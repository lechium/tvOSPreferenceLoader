target = appletv:12.1
GO_EASY_ON_ME=1
#THEOS_DEVICE_IP=13tv.local
DEBUG = 0
INSTALL_TARGET_PROCESSES = TVSettings
include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libprefs
libprefs_LOGOSFLAGS = -c generator=internal
libprefs_FILES = prefs.xm Log.m
libprefs_FRAMEWORKS = Foundation UIKit TVSettingKit
libprefs_CFLAGS = -I. -F. -ITVSettings -fobjc-arc
libprefs_LDFLAGS = -F.

include $(THEOS_MAKE_PATH)/library.mk

TWEAK_NAME = settingsLoader
settingsLoader_FILES = Tweak.x 
settingsLoader_LIBRARIES = prefs
settingsLoader_FRAMEWORKS = Foundation UIKit TVSettingKit
settingsLoader_CFLAGS += -I. -F. -ITVSettings -fobjc-arc
settingsLoader_LDFLAGS = -F. -L$(THEOS_OBJ_DIR) #-undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk

after-libprefs-stage::
	echo "$(THEOS_OBJ_DIR)"