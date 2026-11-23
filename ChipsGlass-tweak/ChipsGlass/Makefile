TARGET := iphone:clang:latest:12.0
ARCHS = arm64
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ChipsGlass
ChipsGlass_FILES = Tweak.x
ChipsGlass_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
