#!/bin/bash
#########################################################
#		WRF Install Script     			#
# 	This Script was written by Umur Dinç    	#
#  To execute this script "bash WRF4.0.3_Install.bash"	#
#########################################################
echo "Welcome! This Script will install the WRF4.0.3"
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
echo "export LDFLAGS=-L/usr/lib/x86_64-linux-gnu/hdf5/serial" >> ~/.bashrc
echo "export CPPFLAGS=-I/usr/include/hdf5/serial" >> ~/.bashrc
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
##########################################
#	Jasper Installation		#
#########################################
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
wget https://github.com/wrf-model/WRF/archive/v4.0.3.tar.gz
mv v4.0.3.tar.gz WRFV4.0.3.tar.gz
tar -zxvf WRFV4.0.3.tar.gz
cd WRF-4.0.3
sed -i 's#  export USENETCDF=$USENETCDF.*#  export USENETCDF="-lnetcdf"#' configure
sed -i 's#  export USENETCDFF=$USENETCDFF.*#  export USENETCDFF="-lnetcdff"#' configure
cd arch
cp Config.pl Config.pl_backup
sed -i '405s/.*/  $response = 34 ;/' Config.pl
sed -i '664s/.*/  $response = 1 ;/' Config.pl
cd ..
./configure
./compile em_real
cd arch
cp Config.pl_backup Config.pl
cd ..
cd ..
#########################################
#	WPS Installation		#
#########################################
wget https://github.com/wrf-model/WPS/archive/v4.0.3.tar.gz
mv v4.0.3.tar.gz WPSV4.0.3.TAR.gz
tar -zxvf WPSV4.0.3.TAR.gz
cd WPS-4.0.3
cd arch
cp Config.pl Config.pl_backup
sed -i '141s/.*/  $response = 3 ;/' Config.pl
cd ..
./clean
sed -i '122s/.*/    NETCDFF="-lnetcdff"/' configure
./configure
./compile
sed -i "s# geog_data_path.*# geog_data_path = '../WPS_GEOG/'#" namelist.wps
cd arch
cp Config.pl_backup Config.pl
cd ..
cd ..
#########################################
#	Opening Geog Data Files 	#
#########################################
wget http://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz
tar -zxvf geog_high_res_mandatory.tar.gz
##########################################################
#	End						#
##########################################################
echo "Installation has completed"
exec bash
exit
