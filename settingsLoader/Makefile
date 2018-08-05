ARCHS = arm64
TARGET = appletv
export GO_EASY_ON_ME=1
export SDKVERSION=10.2
THEOS_DEVICE_IP=btv.local
include THEOS/makefiles/common.mk

TWEAK_NAME = settingsLoader
settingsLoader_FILES = Tweak.xm TVSettingsTweakViewController.m
settingsLoader_LIBRARIES = substrate
settingsLoader_FRAMEWORKS = Foundation UIKit TVSettingKit
settingsLoader_CFLAGS += -I. -ITVSettings -ITVSettingsKit
settingsLoader_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 TVSettings"
