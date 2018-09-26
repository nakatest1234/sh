#!/bin/sh

## need "Development tools"

set -eu

EXEC_DIR=$(dirname $(readlink -f $0))

GS_CMD=gs
GS_TMP=`mktemp -d tmp.gs.XXXX`
GS_URL=https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs925/ghostpdl-9.25.tar.gz

IM_CMD=convert
IM_TMP=`mktemp -d tmp.im.XXXX`
IM_URL=http://www.imagemagick.org/download/ImageMagick.tar.gz

IPA_TMP=`mktemp -d tmp.ipa.XXXX`
IPA1=http://dl.ipafont.ipa.go.jp/IPAexfont/IPAexfont00201.zip
IPA2=http://dl.ipafont.ipa.go.jp/IPAfont/IPAfont00303.zip
IPA_ZIP=tmp.zip

GSFONT_URL=http://sourceforge.net/projects/gs-fonts/files/latest/download?source=files

atexit() {
	cd ${EXEC_DIR}
	[[ -d ${GS_TMP}  ]] && rm -Rf ${GS_TMP}  && echo "DEL ${GS_TMP}"
	[[ -d ${IM_TMP}  ]] && rm -Rf ${IM_TMP}  && echo "DEL ${IM_TMP}"
	[[ -d ${IPA_TMP} ]] && rm -Rf ${IPA_TMP} && echo "DEL ${IPA_TMP}"
	[[ -f ${IPA_ZIP} ]] && rm -f  ${IPA_ZIP} && echo "DEL ${IPA_ZIP}"
}
trap atexit EXIT
trap 'trap - EXIT; atexit; exit -1' SIGHUP SIGINT SIGTERM ERR

sudo yum install -q -y libjpeg giflib libpng freetype libjpeg-devel giflib-devel libpng-devel freetype-devel
sudo ldconfig

echo "download ghostscript"
wget -q -O - ${GS_URL} | tar xfz - --strip=1 -C ${GS_TMP}

echo "download imagemagik"
wget -q -O - ${IM_URL} | tar xfz - --strip=1 -C ${IM_TMP}

cd ${EXEC_DIR}
cd ${GS_TMP}
./configure --prefix=/usr/local --enable-dynamic --disable-compile-inits --with-system-libtiff --with-x --with-drivers=ALL --without-luratech --with-libiconv=gnu
make -j$(nproc)
sudo make install

cd ${EXEC_DIR}
cd ${IM_TMP}
./configure --prefix=/usr/local --without-x
make -j$(nproc)
make check
sudo make uninstall
sudo make install
${IM_CMD} -list format && :

cd ${EXEC_DIR}
${GS_CMD} --help | grep fonts

while true
do
	read -p "INPUT ghostscript font path: " GSPATH

	if [[ -d "${GSPATH}" ]]; then
		break;
	fi
done

cd ${EXEC_DIR}
echo "download ipa fonts"
wget -q -O ${IPA_ZIP} ${IPA1} && unzip -q -j ${IPA_ZIP} "*.ttf" -d ${IPA_TMP}
wget -q -O ${IPA_ZIP} ${IPA2} && unzip -q -j ${IPA_ZIP} "*.ttf" -d ${IPA_TMP}
sudo cp -p ${IPA_TMP}/*.* ${GSPATH}

echo "download ghostscript fonts"
wget -q -O - ${GSFONT_URL} | sudo tar xfz - --strip=1 -C ${GSPATH}

sudo chown -R root.  ${GSPATH}

fc-cache -f
