target = appletv:12.1
GO_EASY_ON_ME=1
THEOS_DEVICE_IP=13tv.local
DEBUG = 1
INSTALL_TARGET_PROCESSES = TVSettings
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = settingsLoader
settingsLoader_FILES = Tweak.x TVSettingsTweakViewController.m Log.m
#settingsLoader_LIBRARIES = substrate
settingsLoader_FRAMEWORKS = Foundation UIKit TVSettingKit
settingsLoader_CFLAGS += -I. -F. -ITVSettings -fobjc-arc
settingsLoader_LDFLAGS = -F. #-undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk

