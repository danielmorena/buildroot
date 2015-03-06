################################################################################
#
# NRD
#
################################################################################

NRD_VERSION = ef99e03a64e3566e148f7289132b729dd3b9aef0
NRD_SITE = git@github.com:Metrological/nrd.git
NRD_SITE_METHOD = git
NRD_LICENSE = PROPRIETARY
NRD_DEPENDENCIES = freetype icu jpeg libpng libmng webp expat openssl c-ares libcurl

ifeq ($(BR2_PACKAGE_DDPSTUB),y)
NRD_DEPENDENCIES += stubs
endif

NRD_INSTALL_STAGING = NO

ifeq ($(BR2_NRD_GRAPHICS_DIRECTFB),y)
NRD_CMAKE_FLAGS += -DGIBBON_GRAPHICS=directfb
NRD_DEPENDENCIES += alsa-lib portaudio webp ffmpeg tremor directfb
else ifeq ($(BR2_NRD_GRAPHICS_GLES2),y)
NRD_CMAKE_FLAGS += -DGIBBON_GRAPHICS=gles2
else ifeq ($(BR2_NRD_GRAPHICS_GLES2_EGL),y)
NRD_CMAKE_FLAGS += -DGIBBON_GRAPHICS=gles2-egl
else 
NRD_CMAKE_FLAGS += -DGIBBON_GRAPHICS=null
endif

ifeq ($(BR2_NRD_NICE_THREADS),y)
NRD_CMAKE_FLAGS += -DGIBBON_NICE_THREADS=1
endif

ifeq ($(BR2_PACKAGE_NRD_REF_SEKELETON), y)
NRD_CMAKE_FLAGS += -DDPI_IMPLEMENTATION=skeleton
else ifeq ($(BR2_PACKAGE_NRD_REF_X86), y)
NRD_CMAKE_FLAGS += -DDPI_IMPLEMENTATION=reference
else ifeq ($(BR2_PACKAGE_NRD_METRO), y)
NRD_CMAKE_FLAGS += -DDPI_IMPLEMENTATION=metro
endif

ifeq ($(BR2_PACKAGE_NRD_APPLICATION), y)
  NRD_CMAKE_FLAGS += -DGIBBON_MODE=executable
  define NRD_TARGET_SET_DEFINITION
	$(INSTALL) -m 755 $(@D)/output/src/platform/gibbon/netflix $(TARGET_DIR)/usr/bin
	$(INSTALL) -m 755 $(@D)/output/src/platform/gibbon/manufss $(TARGET_DIR)/usr/bin
  endef
else ifeq ($(BR2_PACKAGE_NRD_DYNAMICLIB), y)
  NRD_RELOCATION_OPTION = -fPIC
  NRD_INSTALL_STAGING = YES
  NRD_CMAKE_FLAGS += -DGIBBON_MODE=shared
  define NRD_TARGET_SET_DEFINITION
	$(INSTALL) -m 755 $(@D)/output/src/platform/gibbon/manufss $(TARGET_DIR)/usr/bin
  endef
  define NRD_INSTALL_STAGING_CMDS
	$(INSTALL) -m 755 $(@D)/output/src/platform/gibbon/libnetflix.a $(STAGING_DIR)/usr/lib
	$(INSTALL) -m 755 $(@D)/output/src/platform/gibbon/libnetflix.so $(STAGING_DIR)/usr/lib
	mkdir -p $(STAGING_DIR)/usr/include/gibbon
	cp -R $(@D)/output/nrdlib/include/nrd* $(STAGING_DIR)/usr/include/gibbon
	cp -R $(@D)/output/src/platform/gibbon/include/gibbon/* $(STAGING_DIR)/usr/include/gibbon
	cp -R $(@D)/netflix/src/platform/gibbon/*.h $(STAGING_DIR)/usr/include/gibbon
	cp -R $(@D)/netflix/src/platform/gibbon/bridge/*.h $(STAGING_DIR)/usr/include/gibbon
  endef
else ifeq ($(BR2_PACKAGE_NRD_STATICLIB), y)
  NRD_INSTALL_STAGING = YES
  NRD_CMAKE_FLAGS += -DGIBBON_MODE=static
  define NRD_TARGET_SET_DEFINITION
	$(INSTALL) -m 755 $(@D)/output/src/platform/gibbon/manufss $(TARGET_DIR)/usr/bin
  endef
  define NRD_INSTALL_STAGING_CMDS
	$(INSTALL) -m 755 $(@D)/output/src/platform/gibbon/libnetflix.a $(STAGING_DIR)/usr/lib
	mkdir -p $(STAGING_DIR)/usr/include/gibbon
	cp -R $(@D)/output/nrdlib/include/nrd* $(STAGING_DIR)/usr/include/gibbon
	cp -R $(@D)/output/src/platform/gibbon/include/gibbon/* $(STAGING_DIR)/usr/include/gibbon
	cp -R $(@D)/netflix/src/platform/gibbon/*.h $(STAGING_DIR)/usr/include/gibbon
	cp -R $(@D)/netflix/src/platform/gibbon/bridge/*.h $(STAGING_DIR)/usr/include/gibbon
  endef
endif

ifeq ($(BR2_NRD_DEBUG_BUILD),y)
	NRD_CMAKE_FLAGS= -DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_FLAGS_DEBUG="$(NRD_RELOCATION_OPTION) -O0 -g -Wno-cast-align" -DCMAKE_CXX_FLAGS_DEBUG="$(NRD_RELOCATION_OPTION) -O0 -g -Wno-cast-align"
else
	NRD_CMAKE_FLAGS= -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS_RELEASE="$(NRD_RELOCATION_OPTION) -O2 -DNDEBUG -Wno-cast-align" -DCMAKE_CXX_FLAGS_RELEASE="$(NRD_RELOCATION_OPTION) -O2 -DNDEBUG -Wno-cast-align"
endif

#NRD_CMAKE_FLAGS += -DGIBBON_PLATFORM=application-manager
NRD_CMAKE_FLAGS += -DGIBBON_PLATFORM=posix
NRD_CMAKE_FLAGS += -DBUILD_DPI_DIRECTORY=$(@D)/partner/dpi
NRD_CMAKE_FLAGS += -DGIBBON_INPUT=devinput

NRD_CONFIGURE_CMDS = \
	mkdir $(@D)/output;	\
	cd $(@D)/output; \
	$(TARGET_MAKE_ENV) BUILDROOT_TOOL_PREFIX="$(GNU_TARGET_NAME)-" cmake $(@D)/netflix \
		-DCMAKE_TOOLCHAIN_FILE=$(HOST_DIR)/usr/share/buildroot/toolchainfile.cmake \
		$(NRD_CMAKE_FLAGS) \
		-DSMALL_FLAGS:STRING="-s -O3" -DSMALL_CFLAGS:STRING="" -DSMALL_CXXFLAGS:STRING="-fvisibility=hidden -fvisibility-inlines-hidden" -DNRDAPP_TOOLS="manufSSgenerator" -DDPI_REFERENCE_DRM="none"

NRD_BUILD_CMDS = cd $(@D)/output ; $(TARGET_MAKE_ENV) make 

define NRD_INSTALL_TARGET_CMDS
	$(INSTALL) -m 755 $(@D)/output/src/platform/gibbon/libJavaScriptCore.so $(TARGET_DIR)/usr/lib
	$(INSTALL) -m 755 $(@D)/output/src/platform/gibbon/libWTF.so $(TARGET_DIR)/usr/lib
	cp -R $(@D)/output/src/platform/gibbon/data $(TARGET_DIR)/var/lib/netflix
	$(NRD_TARGET_SET_DEFINITION)
endef

$(eval $(cmake-package))
