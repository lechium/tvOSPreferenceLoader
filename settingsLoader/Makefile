ARCHS = arm64
TARGET = appletv
export GO_EASY_ON_ME=1
export SDKVERSION=12.4
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = settingsLoader
settingsLoader_FILES = Tweak.xm TVSettingsTweakViewController.m
settingsLoader_LIBRARIES = substrate
settingsLoader_FRAMEWORKS = Foundation UIKit MAObjCRuntime
settingsLoader_PRIVATEFRAMEWORKS = TVSettingKit
settingsLoader_CFLAGS += -I. -F. -ITVSettings -ITVSettingsKit
settingsLoader_LDFLAGS = -F. -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 TVSettings"
