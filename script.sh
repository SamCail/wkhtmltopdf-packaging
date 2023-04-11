#! /bin/bash
clear
version=0.12.7-samcail
system_version=jammy-amd64
if [ ! -f targets/$system_version/qt_configured ]; then
  docker pull docker.io/aptman/qus:d5.0
  docker pull docker.io/wkhtmltopdf/fpm:1.10.2-20221124
  #docker run --rm --privileged aptman/qus:d5.0 -- -r
  #docker run --rm --privileged aptman/qus:d5.0 -s -- -p

  docker build -f docker/Dockerfile.jammy --build-arg from=ubuntu:jammy --build-arg jpeg=libjpeg-turbo8-dev --build-arg python=python3 -t wkhtmltopdf/$version:$system_version docker/
  mkdir -p targets/$system_version/app targets/$system_version/qt
  docker run --rm -v/home/samuel/Codes/wkhtmltopdf:/src -v/home/samuel/Codes/wkhtmltopdf/packaging/targets/$system_version:/tgt -v/home/samuel/Codes/wkhtmltopdf/packaging:/pkg -w/tgt/qt  wkhtmltopdf/$version:$system_version /src/qt/configure -opensource -confirm-license -fast -release -static -graphicssystem raster -webkit -exceptions -xmlpatterns -system-zlib -system-libpng -system-libjpeg -no-libmng -no-libtiff -no-accessibility -no-stl -no-qt3support -no-phonon -no-phonon-backend -no-opengl -no-declarative -no-script -no-scripttools -no-sql-db2 -no-sql-ibase -no-sql-mysql -no-sql-oci -no-sql-odbc -no-sql-psql -no-sql-sqlite -no-sql-sqlite2 -no-sql-tds -no-mmx -no-3dnow -no-sse -no-sse2 -no-multimedia -nomake demos -nomake docs -nomake examples -nomake tools -nomake tests -nomake translations -silent -xrender -largefile -iconv -openssl-linked -no-javascript-jit -no-rpath -no-dbus -no-nis -no-cups -no-pch -no-gtkstyle -no-nas-sound -no-sm -no-xshape -no-xinerama -no-xcursor -no-xfixes -no-xrandr -no-mitshm -no-xinput -no-xkb -no-glib -no-gstreamer -no-icu -no-openvg -no-xsync -no-audio-backend -no-sse3 -no-ssse3 -no-sse4.1 -no-sse4.2 -no-avx -no-neon  --prefix=/tgt/qt 
  if [ $? -eq 0 ];then
    touch targets/$system_version/qt_configured
  else 
    break
  fi
fi

if [ ! -f targets/$system_version/qt_made ];then
  docker run --rm -v/home/samuel/Codes/wkhtmltopdf:/src -v/home/samuel/Codes/wkhtmltopdf/packaging/targets/$system_version:/tgt -v/home/samuel/Codes/wkhtmltopdf/packaging:/pkg -w/tgt/qt wkhtmltopdf/$version:$system_version make -j4
  if [ $? -eq 0 ];then
    touch targets/$system_version/qt_made
  else 
    break
  fi
fi

rm -fr targets/$system_version/app/bin targets/$system_version/wkhtmltox
docker run --rm -v/home/samuel/Codes/wkhtmltopdf:/src -v/home/samuel/Codes/wkhtmltopdf/packaging/targets/$system_version:/tgt -v/home/samuel/Codes/wkhtmltopdf/packaging:/pkg -w/tgt/app  wkhtmltopdf/$version:$system_version /tgt/qt/bin/qmake /src/wkhtmltopdf.pro CONFIG+=silent 
docker run --rm -v/home/samuel/Codes/wkhtmltopdf:/src -v/home/samuel/Codes/wkhtmltopdf/packaging/targets/$system_version:/tgt -v/home/samuel/Codes/wkhtmltopdf/packaging:/pkg -w/tgt/app  wkhtmltopdf/$version:$system_version make install INSTALL_ROOT=/tgt/wkhtmltox

if [ -f targets/$system_version/to_package ];then
  docker run --rm -v/home/samuel/Codes/wkhtmltopdf/packaging/targets:/tgt -w/tgt -e XZ_OPT=-9 wkhtmltopdf/fpm:1.10.2-20221124 -a amd64 -f -s dir -C $system_version/wkhtmltox --epoch 1 --version "$version" --iteration "0.20230410.dev.buster" --name "wkhtmltox" --description "convert HTML to PDF and various image formats using QtWebkit" --license "LGPLv3" --vendor "wkhtmltopdf" --maintainer "Ashish Kulkarni <ashish@kulkarni.dev>" --url "https://wkhtmltopdf.org/" --prefix "/usr/local" --category "utils" --depends "ca-certificates" --depends "fontconfig" --depends "libc6" --depends "libfreetype6" --depends "libjpeg" --depends "libpng16-16" --depends "libssl1.1" --depends "libstdc++6" --depends "libx11-6" --depends "libxcb1" --depends "libxext6" --depends "libxrender1" --depends "xfonts-75dpi" --depends "xfonts-base" --depends "zlib1g" -t deb --deb-compression xz --provides wkhtmltopdf --conflicts wkhtmltopdf --replaces wkhtmltopdf --deb-shlibs "libwkhtmltox 0 wkhtmltox (>= 0.12.0)"
fi

targets/$system_version/wkhtmltox/bin/wkhtmltopdf --version