#!/bin/bash
#########################################################
#		WRF Install Script     			#
# 	This Script was written by Umur Dinç    	#
#  To execute this script "bash WRF4.3.1_Install.bash"	#
#########################################################
WRFversion="4.3.1"
type="ARW"
if [ -n "$1" ]; then
    if [ "$1" = "-chem" ]; then
        type="Chem"
        extra_packages="flex-old bison"
    elif [ "$1" = "-nmm" ]; then
        type="NMM"
    elif [ "$1" = "-arw" ]; then
        type="ARW"
    else
        echo "Unrecognized option, please run as"
        echo "For WRF-ARW \"bash WRF${WRFversion}_Install.bash -arw\""
        echo "For WRF-Chem \"bash WRF${WRFversion}_Install.bash -chem\""
        echo "For WRF-NMM \"bash WRF${WRFversion}_Install.bash -nmm\""
        exit
    fi
fi
echo "Welcome! This Script will install the WRF${WRFversion}-${type}"
echo "Installation may take several hours and it takes 52 GB storage. Be sure that you have enough time and storage."
#########################################################
#	Controls					#
#########################################################
osbit=$(uname -m)
if [ "$osbit" = "x86_64" ]; then
        echo "64 bit operating system is used"
else
        echo "Sorry! This script was written for 64 bit operating systems."
exit
fi
########
packagemanagement=$(which apt)
if [ -n "$packagemanagement" ]; then
        echo "Operating system uses apt packagemanagement"
else
        echo "Sorry! This script is written for the operating systems which uses apt packagemanagement. Please try this script with debian based operating systems, such as, Ubuntu, Linux Mint, Debian, Pardus etc."
#Tested on Linux Mint 19.3 and Linux Mint 20.1
exit
fi
#########################################################
#   Installing neccesary packages                       #
#########################################################
echo "Please enter your sudo password, so necessary packages can be installed."
sudo apt-get update
sudo apt-get install -y build-essential csh gfortran m4 curl perl mpich libhdf5-mpich-dev libpng-dev netcdf-bin libnetcdff-dev ${extra_packages}

package4checks="build-essential csh gfortran m4 curl perl mpich libhdf5-mpich-dev libpng-dev netcdf-bin libnetcdff-dev ${extra_packages}"
for packagecheck in ${package4checks}; do
 packagechecked=$(dpkg-query --show --showformat='${db:Status-Status}\n' $packagecheck | grep not-installed)
 if [ "$packagechecked" = "not-installed" ]; then
        echo $packagecheck "$packagechecked"
     packagesnotinstalled=yes
 fi
done
if [ "$packagesnotinstalled" = "yes" ]; then
        echo "Some packages were not installed, please re-run the script and enter your root password, when it is requested."
exit
fi
#########################################
cd ~
mkdir Build_WRF
cd Build_WRF
mkdir LIBRARIES
cd LIBRARIES
echo "" >> ~/.bashrc
bashrc_exports=("#WRF Variables" "export DIR=$(pwd)" "export CC=gcc" "export CXX=g++" "export FC=gfortran" "export FCFLAGS=-m64" "export F77=gfortran" "export FFLAGS=-m64"
		"export NETCDF=/usr" "export HDF5=/usr/lib/x86_64-linux-gnu/hdf5/serial" "export LDFLAGS="\""-L/usr/lib/x86_64-linux-gnu/hdf5/serial/ -L/usr/lib"\""" 
		"export CPPFLAGS="\""-I/usr/include/hdf5/serial/ -I/usr/include"\""" "export LD_LIBRARY_PATH=/usr/lib")
for bashrc_export in "${bashrc_exports[@]}" ; do
[[ -z $(grep "${bashrc_export}" ~/.bashrc) ]] && echo "${bashrc_export}" >> ~/.bashrc
done
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
if [ "$type" = "Chem" ]; then
echo "export FLEX_LIB_DIR=/usr/lib" >> ~/.bashrc
echo "export YACC='yacc -d'" >> ~/.bashrc
export FLEX_LIB_DIR=/usr/lib
export YACC='yacc -d'
fi
##########################################
#	Jasper Installation		#
#########################################
[ -d "jasper-1.900.1" ] && mv jasper-1.900.1 jasper-1.900.1-old
[ -f "jasper-1.900.1.tar.gz" ] && mv jasper-1.900.1.tar.gz jasper-1.900.1.tar.gz-old
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
[ -d "WRF-${WRFversion}" ] && mv WRF-${WRFversion} WRF-${WRFversion}-old
[ -f "v${WRFversion}.tar.gz" ] && mv v${WRFversion}.tar.gz v${WRFversion}.tar.gz-old
wget https://github.com/wrf-model/WRF/archive/v${WRFversion}.tar.gz
mv v${WRFversion}.tar.gz WRFV${WRFversion}.tar.gz
tar -zxvf WRFV${WRFversion}.tar.gz
cd WRF-${WRFversion}
if [ "$type" = "Chem" ]; then
export WRF_CHEM=1
export WRF_KPP=1
elif [ "$type" = "NMM" ]; then
export WRF_NMM_CORE=1
export wrf_core=NMM_CORE
fi
sed -i 's#  export USENETCDF=$USENETCDF.*#  export USENETCDF="-lnetcdf"#' configure
sed -i 's#  export USENETCDFF=$USENETCDFF.*#  export USENETCDFF="-lnetcdff"#' configure
cd arch
cp Config.pl Config.pl_backup
sed -i '420s/.*/  $response = 34 ;/' Config.pl
sed -i '695s/.*/  $response = 1 ;/' Config.pl
cd ..
./configure
gfortversion=$(gfortran -dumpversion | cut -c1)
if [ "$gfortversion" -lt 8 ] && [ "$gfortversion" -ge 6 ]; then
sed -i '/-DBUILD_RRTMG_FAST=1/d' configure.wrf
fi
if [ "$type" = "NMM" ]; then
logsave compile.log ./compile nmm_real
else
logsave compile.log ./compile em_real
fi
cd arch
cp Config.pl_backup Config.pl
cd ..
if [ -n "$(grep "Problems building executables, look for errors in the build log" compile.log)" ]; then
        echo "Sorry, There were some errors while installing WRF."
        echo "Please create new issue for the problem, https://github.com/bakamotokatas/WRF-Install-Script/issues"
        exit
fi
cd ..
[ -d "WRF-${WRFversion}-${type}" ] && mv WRF-${WRFversion}-${type} WRF-${WRFversion}-${type}-old
mv WRF-${WRFversion} WRF-${WRFversion}-${type}
#########################################
#	WPS Installation		#
#########################################
WPSversion="4.3.1"
[ -d "WPS-${WPSversion}" ] && mv WPS-${WPSversion} WPS-${WPSversion}-old
[ -f "v${WPSversion}.tar.gz" ] && mv v${WPSversion}.tar.gz v${WPSversion}.tar.gz-old
wget https://github.com/wrf-model/WPS/archive/v${WPSversion}.tar.gz
mv v${WPSversion}.tar.gz WPSV${WPSversion}.TAR.gz
tar -zxvf WPSV${WPSversion}.TAR.gz
cd WPS-${WPSversion}
cd arch
cp Config.pl Config.pl_backup
sed -i '141s/.*/  $response = 3 ;/' Config.pl
cd ..
./clean
sed -i '133s/.*/    NETCDFF="-lnetcdff"/' configure
sed -i "165s/.*/standard_wrf_dirs=\"WRF-${WRFversion}-${type} WRF WRF-4.0.3 WRF-4.0.2 WRF-4.0.1 WRF-4.0 WRFV3\"/" configure
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
   fi
else
wget http://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz
tar -zxvf geog_high_res_mandatory.tar.gz
fi
if [ "$type" = "Chem" ]; then
 cd WPS_GEOG
 Chem_Geog="modis_landuse_21class_30s soiltype_top_2m soiltype_bot_2m albedo_ncep maxsnowalb erod clayfrac_5m sandfrac_5m"
 for i in ${Chem_Geog}; do
  if [ ! -d $i ]; then
   echo $i
   wget https://www2.mmm.ucar.edu/wrf/src/wps_files/${i}.tar.bz2 
   tar -xvf ${i}.tar.bz2
   rm ${i}.tar.bz2
  fi
 done
fi
##########################################################
#	End						#
##########################################################
echo "Installation has completed"
exec bash
exit
