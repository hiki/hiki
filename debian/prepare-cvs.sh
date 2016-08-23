#!/bin/sh
# prepare-cvs.sh - prepare to create hiki deb package from cvs

VERSION=0.5
BRANCH=v0_5_branch

if [ -z "$1" ]; then
  DESTDIR=.
else
  DESTDIR=$1
fi

cd ${DESTDIR}

DEBVERSION=${VERSION}+`date '+%Y%m%d'`
DIR=hiki-${DEBVERSION}

if [ -d ${DIR} ]; then
    echo "Directory ${DIR} already exists."
    exit 1
fi

cvs -Q -d:pserver:anonymous@cvs.sourceforge.jp:/cvsroot/hiki co -r ${BRANCH} -d ${DIR} hiki
cp -a ${DIR} ${DIR}.orig
cd ${DIR}
dch -D experimental -v ${DEBVERSION}-1 'New upstream release (cvs snapshot)'
echo Please type \"cd ${DESTDIR}/${DIR}\" and debuild
