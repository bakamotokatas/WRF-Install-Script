#!/bin/bash
#########################################################
#		WRF Install Script     			#
# 	This Script was written by Umur Dinç    	#
#  To execute this script "bash WRF4.0.1_Install.bash"	#
#########################################################
echo "Welcome! This Script will install the WRF4.0.1"
#########################################################
#       Definitions                 			#
#########################################################
wget=/usr/bin/wget
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
yuklumu=$(apt version build-essential)
if [ -n "$yuklumu" ]; then
        unset yuklumu
        echo "Build Essential has already installed"
else
yukle="build-essential"
fi
yuklumu=$(apt version csh)
if [ -n "$yuklumu" ]; then
        unset yuklumu
        echo "Csh has already installed"
else
yukle="${yukle} csh"
fi
yuklumu=$(apt version gfortran)
if [ -n "$yuklumu" ]; then
        unset yuklumu
        echo "gfortran has already installed"
else
yukle="${yukle} gfortran"
fi
yuklumu=$(apt version m4)
if [ -n "$yuklumu" ]; then
        unset yuklumu
        echo "m4 has already installed"
else
yukle="${yukle} m4"
fi
yuklumu=$(apt version curl)
if [ -n "$yuklumu" ]; then
        unset yuklumu
        echo "curl has already installed"
else
yukle="${yukle} curl"
fi
yuklumu=$(apt version perl)
if [ -n "$yuklumu" ]; then
        unset yuklumu
        echo "perl has already installed"
else
yukle="${yukle} perl"
fi
#####
if [ -z "$yukle" ] ; then
        echo "Starting installing libraries"
else
sudo apt-get update
sudo apt-get install -y $yukle
fi
#############################
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
DIR=$(pwd)
export CC=gcc
export CXX=g++
export FC=gfortran
export FCFLAGS=-m64
export F77=gfortran
export FFLAGS=-m64
#########################################
#	Installing Libraries    	#
#########################################
##############################################
#	MPICH Installation		#
############################################
corerun=$(which mpirun)
if [ -n "$corerun" ]; then
        echo "mpirun has already installed"
else
        echo "mpirun will be installed"
$wget "http://www.mpich.org/static/downloads/3.2.1/mpich-3.2.1.tar.gz"
tar -zxvf mpich-3.2.1.tar.gz
cd mpich-3.2.1/
./configure --prefix=$DIR/mpich
make
make install
echo "export PATH=$DIR/mpich/bin:$PATH" >> ~/.bashrc
export PATH=$DIR/mpich/bin:$PATH
cd ..
fi
############################################
#	Zlib Installation	       	#
############################################
echo "export LDFLAGS=-L$DIR/grib2/lib" >> ~/.bashrc
echo "export CPPFLAGS=-I$DIR/grib2/include" >> ~/.bashrc
export LDFLAGS=-L$DIR/grib2/lib
export CPPFLAGS=-I$DIR/grib2/include
$wget "https://zlib.net/zlib-1.2.11.tar.gz"
tar -zxvf zlib-1.2.11.tar.gz
cd zlib-1.2.11/
./configure --prefix=$DIR/grib2
make
make install
cd ..
##########################################
#	Jasper Installation		#
#########################################
$wget "http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-1.900.1.tar.gz"
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
#	LIBPNG Installation		#
##########################################
$wget "ftp://ftp-osl.osuosl.org/pub/libpng/src/libpng16/libpng-1.6.34.tar.gz"
tar -zxvf libpng-1.6.34.tar.gz
cd libpng-1.6.34/
./configure --prefix=$DIR/grib2
make
make install
cd ..
##########################################
#	HDF5 Installation		#
##########################################
$wget "https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.20/src/hdf5-1.8.20.tar.gz"
tar -zxvf hdf5-1.8.20.tar.gz
cd hdf5-1.8.20/
./configure --with-zlib=$DIR/grib2 --prefix=$DIR/hdf5 --enable-fortran --enable-cxx --enable-fortran2003
make
make install
echo "export PATH=$DIR/hdf5/bin:$PATH" >> ~/.bashrc
echo "export HDF5=$DIR/hdf5" >> ~/.bashrc
export PATH=$DIR/hdf5/bin:$PATH
export HDF5=$DIR/hdf5
sed -i 's#export LDFLAGS.*#export LDFLAGS="-L$DIR/grib2/lib -L$DIR/hdf5/lib"#' ~/.bashrc
sed -i 's#export CPPFLAGS.*#export CPPFLAGS="-I$DIR/grib2/include -I$DIR/hdf5/include"#' ~/.bashrc
export LDFLAGS="-L$DIR/grib2/lib -L$DIR/hdf5/lib"
export CPPFLAGS="-I$DIR/grib2/include -I$DIR/hdf5/include"
cd ..
#########################################
#	NETCDF Installation		#
#########################################
$wget "http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/netcdf-4.1.3.tar.gz"
tar -zxvf netcdf-4.1.3.tar.gz
cd netcdf-4.1.3/
./configure --with-zlib=$DIR/grib2 --with-hdf5=$DIR/hdf5 --prefix=$DIR/netcdf --disable-dap-remote-tests
make
make install
cd ..
echo "export PATH=$DIR/netcdf/bin:$PATH" >> ~/.bashrc
echo "export NETCDF=$DIR/netcdf" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=$DIR/netcdf/lib" >> ~/.bashrc
sed -i 's#export LDFLAGS.*#export LDFLAGS="-L$DIR/grib2/lib -L$DIR/hdf5/lib -L$DIR/netcdf/lib"#' ~/.bashrc
sed -i 's#export CPPFLAGS.*#export CPPFLAGS="-I$DIR/grib2/include -I$DIR/hdf5/include -I$DIR/netcdf/include"#' ~/.bashrc
export PATH=$DIR/netcdf/bin:$PATH
export NETCDF=$DIR/netcdf
export LD_LIBRARY_PATH=$DIR/netcdf/lib
#########################################
#	WRF Installation		#
#########################################
cd ..
$wget "https://github.com/wrf-model/WRF/archive/v4.0.1.tar.gz"
mv v4.0.1.tar.gz WRFV4.0.1.tar.gz
tar -zxvf WRFV4.0.1.tar.gz
cd WRF-4.0.1
./configure
./compile em_real
cd ..
#########################################
#	WPS Installation		#
#########################################
$wget "https://github.com/wrf-model/WPS/archive/v4.0.1.tar.gz"
mv v4.0.1.tar.gz WPSV4.0.1.TAR.gz
tar -zxvf WPSV4.0.1.TAR.gz
cd WPS-4.0.1
./clean
./configure
./compile
sed -i "s# geog_data_path.*# geog_data_path = '../WPS_GEOG/'#" namelist.wps
cd ..
#########################################
#	Opening Geog Data Files 	#
#########################################
$wget "http://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz"
tar -zxvf geog_high_res_mandatory.tar.gz
#########################################
#	NCL Installation		#
#########################################
#cd $DIR
#mkdir ncl
#cd ncl
#$wget "https://www.earthsystemgrid.org/dataset/ncl.640.dap/file/ncl_ncarg-6.4.0-Debian8.6_64bit_gnu492.tar.gz"
#tar -zxvf ncl_ncarg-6.4.0-Debian8.6_64bit_gnu492.tar.gz
#echo "export NCARG_ROOT=$DIR/ncl" >> ~/.bashrc
#echo "export PATH=$NCARG_ROOT/bin:$PATH" >> ~/.bashrc
#echo "export DISPLAY=:0.0" >> ~/.bashrc
##########################################################
#	Son						#
##########################################################
echo "Installation has completed"
exec bash
exit
