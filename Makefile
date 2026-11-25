# Naloia Glass — Standalone Clang .dylib & Rootless .deb Makefile
# Default target builds zero-dependency @rpath/NaloiaGlass.dylib for IPA injection & signing.

VERSION := $(shell tr -d '[:space:]' < VERSION)
DYLIB_NAME := NaloiaGlass.dylib

SOURCES := \
	src/Core/NGEnvironment.m \
	src/Core/NGPreferences.m \
	src/Core/NGRuntimeBridge.m \
	src/Dock/NGBadgeSync.m \
	src/Dock/NGCapsuleDockView.m \
	src/Dock/NGDockCoordinator.m \
	src/Dock/NGNativeSolariumStyler.m \
	src/Settings/NGSettingsViewController.m \
	src/Settings/NGWeChatSettingsEntry.m \
	src/NGEntry.m

.PHONY: all dylib deb test clean

all: dylib

dylib: $(SOURCES)
	bash scripts/build_dylib.sh

deb: dylib
	bash scripts/package_deb.sh

test:
	python3 -m unittest discover -s tests -p "test_*.py" -v

clean:
	rm -rf build dist packages
