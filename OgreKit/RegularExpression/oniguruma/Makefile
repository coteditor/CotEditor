ONIGURUMA_VERSION=onig-5.9.2
OS_VERSION=$(shell uname -r)

UNIVERSAL_DIR=universal
INTEL_64_DIR=x86_64
INTEL_DIR=intel
PPC_DIR=ppc

INTEL_64_CONFIGURE_FLAGS=--disable-dependency-tracking --host=x86_64-apple-darwin$(OS_VERSION) --build=i686-apple-darwin$(OS_VERSION)
INTEL_CONFIGURE_FLAGS=--disable-dependency-tracking --host=i686-apple-darwin$(OS_VERSION) --build=i686-apple-darwin$(OS_VERSION)
PPC_CONFIGURE_FLAGS=--disable-dependency-tracking --host=ppc-apple-darwin$(OS_VERSION) --build=i686-apple-darwin$(OS_VERSION)

INTEL_64_SDK=/Developer/SDKs/MacOSX10.6.sdk
INTEL_64_CC=gcc -arch x86_64 

INTEL_SDK=/Developer/SDKs/MacOSX10.6.sdk
INTEL_CC=gcc -arch i686

PPC_SDK=/Developer/SDKs/MacOSX10.4u.sdk
PPC_CC=gcc-4.0 -arch ppc -isystem /Developer/SDKs/MacOSX10.4u.sdk/usr/include/gcc/darwin/4.0 -isystem /Developer/SDKs/MacOSX10.4u.sdk/usr/include 

ONIG_TARGET=libonig.la
LIBS_DIR=.libs
ONIGURUMA=libonig.a

all: $(UNIVERSAL_DIR)/$(ONIGURUMA)

$(UNIVERSAL_DIR)/$(ONIGURUMA): $(UNIVERSAL_DIR) $(PPC_DIR)/$(ONIG_TARGET) $(INTEL_DIR)/$(ONIG_TARGET) $(INTEL_64_DIR)/$(ONIG_TARGET)
	lipo -create $(INTEL_DIR)/$(LIBS_DIR)/$(@F) $(INTEL_64_DIR)/$(LIBS_DIR)/$(@F) $(PPC_DIR)/$(LIBS_DIR)/$(@F) -output $(UNIVERSAL_DIR)/$(@F)

$(INTEL_64_DIR)/$(ONIG_TARGET): $(INTEL_64_DIR)
	cd $(@D);\
	CC="$(INTEL_64_CC)" ./configure $(INTEL_64_CONFIGURE_FLAGS);\
	perl -pi -e 's@CFLAGS = -isysroot /Developer/SDKs/MacOSX10.6.sdk -arch x86_64@CFLAGS = -isysroot $(INTEL_SDK) -arch x86_64@' Makefile;\
	perl -pi -e 's@-dynamiclib@-dynamiclib -arch x86_64@g' libtool;\
	make $(@F)

$(INTEL_DIR)/$(ONIG_TARGET): $(INTEL_DIR)
	cd $(@D);\
	CC="$(INTEL_CC)" ./configure $(INTEL_CONFIGURE_FLAGS);\
	perl -pi -e 's@CFLAGS = -isysroot /Developer/SDKs/MacOSX10.6.sdk -arch x86_64@CFLAGS = -isysroot $(INTEL_SDK) -arch i686@' Makefile;\
	perl -pi -e 's@-dynamiclib@-dynamiclib -arch i686@g' libtool;\
	make $(@F)

$(PPC_DIR)/$(ONIG_TARGET): $(PPC_DIR)
	cd $(@D);\
	CC="$(PPC_CC)" ./configure $(PPC_CONFIGURE_FLAGS);\
	perl -pi -e 's@CFLAGS = -isysroot /Developer/SDKs/MacOSX10.6.sdk -arch x86_64@CFLAGS =@' Makefile;\
	perl -pi -e 's@-dynamiclib@-dynamiclib -arch ppc@g' libtool;\
	make $(@F)

$(INTEL_64_DIR):
	tar xzvf $(ONIGURUMA_VERSION).tar.gz
	mv $(ONIGURUMA_VERSION) $@

$(INTEL_DIR):
	tar xzvf $(ONIGURUMA_VERSION).tar.gz
	mv $(ONIGURUMA_VERSION) $@

$(PPC_DIR):
	tar xzvf $(ONIGURUMA_VERSION).tar.gz
	mv $(ONIGURUMA_VERSION) $@

$(UNIVERSAL_DIR):
	mkdir $@

clean:
	rm -rf $(INTEL_64_DIR)
	rm -rf $(INTEL_DIR)
	rm -rf $(PPC_DIR)
	rm -rf $(UNIVERSAL_DIR)