ONIGURUMA_VERSION=Onigmo-Onigmo-5.13.5
OS_VERSION=$(shell uname -r)

UNIVERSAL_DIR=universal
INTEL_64_DIR=x86_64
INTEL_DIR=intel

INTEL_64_CONFIGURE_FLAGS=--disable-dependency-tracking --host=x86_64-apple-darwin$(OS_VERSION) --build=x86_64-apple-darwin$(OS_VERSION)
INTEL_CONFIGURE_FLAGS=--disable-dependency-tracking --host=i686-apple-darwin$(OS_VERSION) --build=i686-apple-darwin$(OS_VERSION)

INTEL_64_SDK=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.8.sdk
INTEL_64_CC=/usr/bin/gcc -arch x86_64

INTEL_SDK=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.8.sdk
INTEL_CC=/usr/bin/gcc -arch i686

ONIG_TARGET=libonig.la
LIBS_DIR=.libs
ONIGURUMA=libonig.a

all: $(UNIVERSAL_DIR)/$(ONIGURUMA)

$(UNIVERSAL_DIR)/$(ONIGURUMA): $(UNIVERSAL_DIR) $(INTEL_DIR)/$(ONIG_TARGET) $(INTEL_64_DIR)/$(ONIG_TARGET)
	lipo -create $(INTEL_DIR)/$(LIBS_DIR)/$(@F) $(INTEL_64_DIR)/$(LIBS_DIR)/$(@F) -output $(UNIVERSAL_DIR)/$(@F)

$(INTEL_64_DIR)/$(ONIG_TARGET): $(INTEL_64_DIR)
	cd $(@D);\
	CC="$(INTEL_64_CC)" ./configure $(INTEL_64_CONFIGURE_FLAGS);\
	perl -pi -e 's@CFLAGS = -isysroot /Developer/SDKs/MacOSX10.7.sdk -arch x86_64@CFLAGS = -isysroot $(INTEL_SDK) -arch x86_64@' Makefile;\
	perl -pi -e 's@-dynamiclib@-dynamiclib -arch x86_64@g' libtool;\
	make $(@F)

$(INTEL_DIR)/$(ONIG_TARGET): $(INTEL_DIR)
	cd $(@D);\
	CC="$(INTEL_CC)" ./configure $(INTEL_CONFIGURE_FLAGS);\
	perl -pi -e 's@CFLAGS = -isysroot /Developer/SDKs/MacOSX10.7.sdk -arch x86_64@CFLAGS = -isysroot $(INTEL_SDK) -arch i686@' Makefile;\
	perl -pi -e 's@-dynamiclib@-dynamiclib -arch i686@g' libtool;\
	make $(@F)

$(INTEL_64_DIR):
	unzip $(ONIGURUMA_VERSION).zip
	mv $(ONIGURUMA_VERSION) $@

$(INTEL_DIR):
	unzip $(ONIGURUMA_VERSION).zip
	mv $(ONIGURUMA_VERSION) $@

$(UNIVERSAL_DIR):
	mkdir $@

clean:
	rm -rf $(INTEL_64_DIR)
	rm -rf $(INTEL_DIR)
	rm -rf $(UNIVERSAL_DIR)