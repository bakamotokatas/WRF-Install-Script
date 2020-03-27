#!/bin/bash
#########################################################
#		WRF Install Script     			#
# 	This Script was written by Umur Dinç    	#
#  To execute this script "bash WRF4.1.5_Install.bash"	#
#########################################################
echo "Welcome! This Script will install the WRF4.1.5"
echo "Installation may take several hours and it takes 52 GB storage. Be sure that you have enough time and storage."
#########################################################
#	Controls					#
#########################################################
osbit=$(uname -m)
if [ "$osbit" = "x86_64" ]; then
        echo "64 bit operating system is used"
else
        echo "Error! This script was written for 64 bit operating systems."
exit
fi
########
packagemanagement=$(which apt)
if [ -n "$packagemanagement" ]; then
        echo "Operating system uses apt packagemanagement"
else
        echo "Error! This script is written for the operating systems which uses apt packagemanagement. Please try this script with debian based operating systems, such as, Ubuntu, Linux Mint, Debian, Pardus etc."
#Tested on Linux Mint 19.3
exit
fi
#########################################################
#   Installing neccesary packages                       #
#########################################################
sudo apt-get update
sudo apt-get install -y build-essential csh gfortran m4 curl perl mpich libhdf5-mpich-dev libpng-dev netcdf-bin libnetcdff-dev
#########################################
cd ~
mkdir Build_WRF
cd Build_WRF
mkdir LIBRARIES
cd LIBRARIES
echo "" >> ~/.bashrc
echo "#WRF Variables" >> ~/.bashrc
echo "export DIR="$(pwd) >> ~/.bashrc
echo "export CC=gcc" >> ~/.bashrc
echo "export CXX=g++" >> ~/.bashrc
echo "export FC=gfortran" >> ~/.bashrc
echo "export FCFLAGS=-m64" >> ~/.bashrc
echo "export F77=gfortran" >> ~/.bashrc
echo "export FFLAGS=-m64" >> ~/.bashrc
echo "export NETCDF=/usr" >> ~/.bashrc
echo "export HDF5=/usr/lib/x86_64-linux-gnu/hdf5/serial" >> ~/.bashrc
echo "export LDFLAGS="\""-L/usr/lib/x86_64-linux-gnu/hdf5/serial/ -L/usr/lib"\""" >> ~/.bashrc
echo "export CPPFLAGS="\""-I/usr/include/hdf5/serial/ -I/usr/include"\""" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=/usr/lib" >> ~/.bashrc
DIR=$(pwd)
export CC=gcc
export CXX=g++
export FC=gfortran
export FCFLAGS=-m64
export F77=gfortran
export FFLAGS=-m64
export NETCDF=/usr
export HDF5=/usr/lib/x86_64-linux-gnu/hdf5/serial
export LDFLAGS="-L/usr/lib/x86_64-linux-gnu/hdf5/serial/ -L/usr/lib"
export CPPFLAGS="-I/usr/include/hdf5/serial/ -I/usr/include"
export LD_LIBRARY_PATH=/usr/lib
##########################################
#	Jasper Installation		#
#########################################
[ -d "jasper-1.900.1" ] && mv jasper-1.900.1 jasper-1.900.1-old
[ -d "jasper-1.900.1.tar.gz" ] && mv jasper-1.900.1.tar.gz jasper-1.900.1.tar.gz-old
wget http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-1.900.1.tar.gz
tar -zxvf jasper-1.900.1.tar.gz
cd jasper-1.900.1/
./configure --prefix=$DIR/grib2
make
make install
echo "export JASPERLIB=$DIR/grib2/lib" >> ~/.bashrc
echo "export JASPERINC=$DIR/grib2/include" >> ~/.bashrc
export JASPERLIB=$DIR/grib2/lib
export JASPERINC=$DIR/grib2/include
cd ..
#########################################
#	WRF Installation		#
#########################################
cd ..
[ -d "WRF-4.1.5" ] && mv WRF-4.1.5 WRF-4.1.5-old
[ -d "v4.1.5.tar.gz" ] && mv v4.1.5.tar.gz v4.1.5.tar.gz-old
wget https://github.com/wrf-model/WRF/archive/v4.1.5.tar.gz
mv v4.1.5.tar.gz WRFV4.1.5.tar.gz
tar -zxvf WRFV4.1.5.tar.gz
cd WRF-4.1.5
sed -i 's#  export USENETCDF=$USENETCDF.*#  export USENETCDF="-lnetcdf"#' configure
sed -i 's#  export USENETCDFF=$USENETCDFF.*#  export USENETCDFF="-lnetcdff"#' configure
cd arch
cp Config.pl Config.pl_backup
sed -i '405s/.*/  $response = 34 ;/' Config.pl
sed -i '668s/.*/  $response = 1 ;/' Config.pl
cd ..
./configure
gfortversion=$(gfortran -dumpversion | cut -c1)
if [ "$gfortversion" -lt 8 ] && [ "$gfortversion" -ge 6 ]; then
sed -i '/-DBUILD_RRTMG_FAST=1/d' configure.wrf
fi
logsave compile.log ./compile em_real
cd arch
cp Config.pl_backup Config.pl
cd ..
if [ -n "$(grep "Problems building executables, look for errors in the build log" compile.log)" ]; then
        echo "Sorry, There were some errors while installing WRF."
        echo "Please create new issue for the problem, https://github.com/bakamotokatas/WRF-Install-Script/issues"
        exit
fi
cd ..
#########################################
#	WPS Installation		#
#########################################
[ -d "WPS-4.1" ] && mv WPS-4.1 WPS-4.1-old
[ -d "v4.1.tar.gz" ] && mv v4.1.tar.gz v4.1.tar.gz-old
wget https://github.com/wrf-model/WPS/archive/v4.1.tar.gz
mv v4.1.tar.gz WPSV4.1.TAR.gz
tar -zxvf WPSV4.1.TAR.gz
cd WPS-4.1
cd arch
cp Config.pl Config.pl_backup
sed -i '141s/.*/  $response = 3 ;/' Config.pl
cd ..
./clean
sed -i '122s/.*/    NETCDFF="-lnetcdff"/' configure
sed -i '154s/.*/standard_wrf_dirs="WRF-4.1.5 WRF WRF-4.0.3 WRF-4.0.2 WRF-4.0.1 WRF-4.0 WRFV3"/' configure
./configure
logsave compile.log ./compile
sed -i "s# geog_data_path.*# geog_data_path = '../WPS_GEOG/'#" namelist.wps
cd arch
cp Config.pl_backup Config.pl
cd ..
cd ..
#########################################
#	Opening Geog Data Files 	#
#########################################
if [ -d "WPS_GEOG" ]; then
  echo "WRF and WPS are installed successfully"
  echo "Directory WPS_GEOG is already exists."
  echo "Do you want WPS_GEOG files to be redownloaded and reexracted?"
  echo "please type yes or no"
  read GEOG_validation
  if [ ${GEOG_validation} = "yes" ]; then
    wget http://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz
    tar -zxvf geog_high_res_mandatory.tar.gz
  else
    echo "You can download it later from http://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz and extract it"
    exit
   fi
else
wget http://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz
tar -zxvf geog_high_res_mandatory.tar.gz
fi
##########################################################
#	End						#
##########################################################
echo "Installation has completed"
exec bash
exit
