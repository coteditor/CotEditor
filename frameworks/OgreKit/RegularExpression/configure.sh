#!/bin/bash

if [ -e "RegularExpression/oniguruma" ]; then
	echo "oniguruma already exists."
else
	echo "oniguruma is not found. Extracting oniguruma..."
	cd RegularExpression
	tar zxvf onigd20050823.tar.gz
	
#	if false; then
#        echo "Applying patch..."
#        cp 20040720.patch oniguruma/.
#        cd oniguruma
#        cp regparse.c regparse.c.original
#        cp regcomp.c regcomp.c.original
#        patch -p0 < 20040720.patch
#        cd ..
#	fi
	
	cd ..
fi

if [ -e "RegularExpression/oniguruma/config.h" ]; then
	echo "config.h already exists."
else
	echo "config.h is not found. Creating config.h..."
	cd RegularExpression/oniguruma
	./configure
fi

exit

# Name: configure.sh
# Project: OgreKit
#
# Creation Date: Sep 7 2003
# Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
# Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
# License: OgreKit License
#
# Tabsize: 4

