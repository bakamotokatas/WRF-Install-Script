#!/bin/bash
#########################################################
#		WRF Install Script     			#
# 	This Script was written by Umur Dinç    	#
#  To execute this script "bash WRF4.7.1_Install.bash"	#
#########################################################
WRFversion="4.7.1"
type="ARW"
non_interactive=no
prep_chem_validation=ask
build_dir="$HOME/Build_WRF"
build_jobs=$(nproc)
while [ "$#" -gt 0 ]; do
    case "$1" in
        -arw) type="ARW" ;;
        -chem) type="Chem" ;;
        -hydro) type="Hydro" ;;
        --non-interactive) non_interactive=yes ;;
        --with-prep-chem) prep_chem_validation=yes ;;
        --build-dir)
            [ "$#" -ge 2 ] || { echo "--build-dir requires a path" >&2; exit 1; }
            build_dir="$2"; shift ;;
        --jobs)
            [ "$#" -ge 2 ] || { echo "--jobs requires a positive integer" >&2; exit 1; }
            build_jobs="$2"; shift ;;
        -h|--help)
            echo "Usage: bash $0 [-arw|-chem|-hydro] [--non-interactive] [--with-prep-chem] [--build-dir PATH] [--jobs N]"
            echo "--non-interactive: reuse geography, skip PREP-CHEM-SRC unless requested and do not open a shell."
            echo "--with-prep-chem: install optional PREP-CHEM-SRC for -chem, including in non-interactive mode."
            echo "--build-dir PATH: isolate a build (default: ~/Build_WRF); --jobs N: compilation processes."
            exit 0 ;;
        *) echo "Unrecognized option: $1" >&2; exit 1 ;;
    esac
    shift
done
if [[ ! "$build_jobs" =~ ^[1-9][0-9]*$ ]]; then
    echo "--jobs requires a positive integer" >&2
    exit 1
fi
if [ "$prep_chem_validation" = "yes" ] && [ "$type" != "Chem" ]; then
    echo "--with-prep-chem requires -chem" >&2
    exit 1
fi
build_dir=$(realpath -m "$build_dir")
# Stop on failed downloads, configuration and installation commands.
set -Ee -o pipefail
trap 'echo "Installation failed at line $LINENO: $BASH_COMMAND" >&2' ERR
# Keep builds of different variants independent of the calling shell.
unset WRF_CHEM WRF_KPP WRF_HYDRO
# Some development containers export DEBUG=release; WRF interprets it as C flags.
unset DEBUG
backup_suffix="old-$(date +%Y%m%d-%H%M%S)-$$"
echo "Welcome! This Script will install the WRF${WRFversion}-${type}"
echo "Installation may take several hours and it takes 52 GB storage. Be sure that you have enough time and storage."
#########################################################
#	Controls					#
#########################################################
if [ "$EUID" -eq 0 ]
  then echo "Running this script as root or sudo, is not suggested"
  exit 1
fi
osbit=$(uname -m)
if [ "$osbit" = "x86_64" ]; then
        echo "64 bit operating system is used"
else
        echo "Sorry! This script was written for 64 bit operating systems."
exit 1
fi
########
packagemanagement=$(command -v apt || true)
if [ -n "$packagemanagement" ]; then
        echo "Operating system uses apt packagemanagement"
else
        echo "Sorry! This script is written for the operating systems which uses apt packagemanagement. Please try this script with debian based operating systems, such as, Ubuntu, Linux Mint, Debian, Pardus etc."
#Tested on Ubuntu 22.04
exit 1
fi
local_language=$(locale | grep LANG | grep tr_TR || true)
if [ -n "$local_language" ]; then
 echo "Merhaba, WRF modelinin kodundaki hatadan dolayı, WRF kurulumu işletim sistemi dili Türkçe olduğunda, Türkçedeki i ve ı harflerinin farklı olması sebebiyle hata vermektedir. Lütfen işletim sisteminizin dilini başka bir dile çevirip yeniden çalıştırınız. Kurulum bittikten sonra işletim sistemi dilini tekrar Türkçe'ye çevirebilirsiniz."
 exit 1
fi
#########################################################
#   Installing neccesary packages                       #
#########################################################

extra_packages=()
if [ "$type" = "Chem" ]; then
 extra_packages=(flex bison libfl-dev)
fi
echo "Please enter your sudo password, so necessary packages can be installed."
sudo apt-get update
mpich_repoversion=$(apt-cache policy mpich | grep Candidate | cut -d ':' -f 2 | cut -d '-' -f 1 | cut -c2)
if [ "$mpich_repoversion" -ge 4 ]; then
mpirun_packages=(libopenmpi-dev libhdf5-openmpi-dev)
else
mpirun_packages=(mpich libhdf5-mpich-dev)
fi
packages=(build-essential csh gfortran m4 curl wget perl logsave "${mpirun_packages[@]}" libhdf5-dev libpng-dev netcdf-bin libnetcdff-dev "${extra_packages[@]}")
sudo apt-get install -y "${packages[@]}"

for packagecheck in "${packages[@]}"; do
 if [ "$(dpkg-query --show --showformat='${db:Status-Status}' "$packagecheck" 2>/dev/null || true)" != "installed" ]; then
    echo "Package not installed: $packagecheck" >&2
    exit 1
 fi
done
#########################################
mkdir -p "$build_dir"
cd "$build_dir"
mkdir -p LIBRARIES
cd LIBRARIES
append_bashrc() {
    if ! grep -Fqx -- "$1" ~/.bashrc; then
        echo "$1" >> ~/.bashrc
    fi
}
bashrc_exports=("#WRF Variables" "export DIR=$(pwd)" "export CC=gcc" "export CXX=g++" "export FC=gfortran" "export FCFLAGS=-m64" "export F77=gfortran" "export FFLAGS=-m64"
		"export NETCDF=/usr" "export HDF5=/usr/lib/x86_64-linux-gnu/hdf5/serial" 'export LDFLAGS="-L/usr/lib/x86_64-linux-gnu/hdf5/serial/ -L/usr/lib"'
		'export CPPFLAGS="-I/usr/include/hdf5/serial/ -I/usr/include"' "export LD_LIBRARY_PATH=/usr/lib")
for bashrc_export in "${bashrc_exports[@]}" ; do
append_bashrc "$bashrc_export"
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
append_bashrc "export FLEX_LIB_DIR=/usr/lib/x86_64-linux-gnu"
append_bashrc "export YACC='yacc -d'"
export FLEX_LIB_DIR=/usr/lib/x86_64-linux-gnu
export YACC='yacc -d'
fi
##########################################
#	Jasper Installation		#
#########################################
[ -d "jasper-1.900.1" ] && mv jasper-1.900.1 jasper-1.900.1-"${backup_suffix}"
[ -f "jasper-1.900.1.tar.gz" ] && mv jasper-1.900.1.tar.gz jasper-1.900.1.tar.gz-"${backup_suffix}"
wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-1.900.1.tar.gz -O jasper-1.900.1.tar.gz
tar -zxf jasper-1.900.1.tar.gz
cd jasper-1.900.1/
# JasPer 1.900.1 predates modern GCC: include the missing prototype and
# compile its legacy C sources as GNU C99 (GCC 15 defaults to GNU C23).
# Keep its pre-existing pointer compatibility warnings non-fatal with GCC >= 14.
for jasper_source in src/libjasper/*/*.c src/appl/*.c; do
    if grep -q 'jas_eprintf' "$jasper_source"; then
        sed -i '1i #include "jasper/jas_debug.h"' "$jasper_source"
    fi
done
CFLAGS="-O2 -std=gnu99 -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types" ./configure --prefix="$DIR/grib2"
make
make install
append_bashrc "export JASPERLIB=$DIR/grib2/lib"
append_bashrc "export JASPERINC=$DIR/grib2/include"
export JASPERLIB=$DIR/grib2/lib
export JASPERINC=$DIR/grib2/include
cd ..
#########################################
#	WRF Installation		#
#########################################
cd ..
[ -d "WRFV${WRFversion}" ] && mv WRFV${WRFversion} WRFV${WRFversion}-"${backup_suffix}"
[ -f "WRFV${WRFversion}.tar.gz" ] && mv WRFV${WRFversion}.tar.gz WRFV${WRFversion}.tar.gz-"${backup_suffix}"
wget https://github.com/wrf-model/WRF/releases/download/v${WRFversion}/v${WRFversion}.tar.gz -O WRFV${WRFversion}.tar.gz
tar -zxf WRFV${WRFversion}.tar.gz
if [ "$type" = "Hydro" ]; then
export WRF_HYDRO=1
[ -f "v5.4.0.tar.gz" ] && mv v5.4.0.tar.gz v5.4.0.tar.gz-"${backup_suffix}"
wget https://github.com/NCAR/wrf_hydro_nwm_public/archive/refs/tags/v5.4.0.tar.gz -O v5.4.0.tar.gz
tar -zxf v5.4.0.tar.gz
/bin/cp -rf wrf_hydro_nwm_public-5.4.0/src/. WRFV${WRFversion}/hydro/
# Hydro 5.4.0's traditional Makefile incorrectly capitalizes this filename.
sed -i 's/\.F90/.f90/g' WRFV${WRFversion}/hydro/utils/fortglob/Makefile
rm v5.4.0.tar.gz
rm -r wrf_hydro_nwm_public-5.4.0
fi
cd WRFV${WRFversion}
if [ "$type" = "Chem" ]; then
export WRF_CHEM=1
export WRF_KPP=1
# WRF 4.7.1's legacy KPP generator starts four levels below the WRF root.
sed -i 's#tuv_kpp FIRST ../../inc/#tuv_kpp FIRST ../../../../inc/#' chem/KPP/compile_wkc
# Avoid repeatedly importing every symbol from all 30 KPP mechanisms.
# The driver uses only each mechanism's interface; calculation code is unchanged.
sed -i 's#USE module_kpp_%s_interf #USE module_kpp_%s_interf, ONLY: %s_interface #; /USE module_kpp_%s_interf/s#p2->name );#p2->name, p2->name );#' chem/KPP/util/wkc/gen_kpp_mech_dr.c
fi
# Match the literal shell variable in WRF configure.
# shellcheck disable=SC2016
sed -i 's#$NETCDF/lib#$NETCDF/lib/x86_64-linux-gnu#g' configure
# The NetCDF diffwrf utility also detects Fortran libraries separately.
# shellcheck disable=SC2016
sed -i 's#$(NETCDFPATH)/lib#$(NETCDFPATH)/lib/x86_64-linux-gnu#g' external/io_netcdf/makefile
( echo 34 ; echo 1 ) | ./configure
sed -i 's#-L/usr/lib -lnetcdff -lnetcdf#-L/usr/lib/x86_64-linux-gnu -lnetcdff -lnetcdf#g' configure.wrf
gfortversion=$(gfortran -dumpversion | cut -d '.' -f 1)
if [ "$gfortversion" -lt 8 ] && [ "$gfortversion" -ge 6 ]; then
sed -i '/-DBUILD_RRTMG_FAST=1/d' configure.wrf
fi
logsave compile.log ./compile -j "$build_jobs" em_real
if grep -q "Problems building executables, look for errors in the build log" compile.log; then
        echo "Sorry, There were some errors while installing WRF."
        echo "Please create new issue for the problem, https://github.com/bakamotokatas/WRF-Install-Script/issues"
        exit 1
fi
for executable in wrf.exe real.exe ndown.exe tc.exe; do
    if [ ! -x "main/$executable" ]; then
        echo "WRF build failed: main/$executable is missing." >&2
        exit 1
    fi
done
cd ..
[ -d "WRF-${WRFversion}-${type}" ] && mv WRF-${WRFversion}-${type} WRF-${WRFversion}-${type}-"${backup_suffix}"
mv WRFV${WRFversion} WRF-${WRFversion}-${type}
#########################################
#	WPS Installation		#
#########################################
WPSversion="4.7.0"
[ -d "WPS-${WPSversion}" ] && mv WPS-${WPSversion} WPS-${WPSversion}-"${backup_suffix}"
[ -f "WPSV${WPSversion}.TAR.gz" ] && mv WPSV${WPSversion}.TAR.gz WPSV${WPSversion}.TAR.gz-"${backup_suffix}"
wget https://github.com/wrf-model/WPS/archive/v${WPSversion}.tar.gz -O WPSV${WPSversion}.TAR.gz
tar -zxf WPSV${WPSversion}.TAR.gz
cd WPS-${WPSversion}
./clean
# Debian/Ubuntu keep NetCDF libraries in the multiarch directory.
# shellcheck disable=SC2016
sed -i 's#$NETCDF/lib#$NETCDF/lib/x86_64-linux-gnu#g;s#${NETCDF}/lib#${NETCDF}/lib/x86_64-linux-gnu#g' configure
sed -i "s/standard_wrf_dirs=.*/standard_wrf_dirs=\"WRF-${WRFversion}-${type} WRF WRF-4.0.3 WRF-4.0.2 WRF-4.0.1 WRF-4.0 WRFV3\"/" configure
echo 3 | ./configure
logsave compile.log ./compile
for executable in geogrid.exe ungrib.exe metgrid.exe; do
    if [ ! -x "$executable" ]; then
        echo "WPS build failed: $executable is missing." >&2
        exit 1
    fi
done
sed -i "s# geog_data_path.*# geog_data_path = '../WPS_GEOG/'#" namelist.wps
cd ..
#########################################
#	Opening Geog Data Files 	#
#########################################
geog_url="https://www2.mmm.ucar.edu/wrf/src/wps_files"
GEOG_validation=no
if [ -d "WPS_GEOG" ]; then
    echo "Directory WPS_GEOG already exists."
    if [ "$non_interactive" = "no" ]; then
        read -r -p "Redownload and extract geography? (yes/no): " GEOG_validation
    fi
else
    GEOG_validation=yes
fi
if [ "$GEOG_validation" = "yes" ]; then
    wget -c "$geog_url/geog_high_res_mandatory.tar.gz" -O geog_high_res_mandatory.tar.gz
    tar -zxf geog_high_res_mandatory.tar.gz
fi
if [ "$type" = "Chem" ]; then
    cd WPS_GEOG
    Chem_Geog="modis_landuse_21class_30s soiltype_top_2m soiltype_bot_2m albedo_ncep maxsnowalb erod clayfrac_5m sandfrac_5m"
    for i in ${Chem_Geog}; do
        if [ ! -d "$i" ]; then
            wget -c "$geog_url/${i}.tar.bz2" -O "${i}.tar.bz2"
            tar -xf "${i}.tar.bz2"
            rm "${i}.tar.bz2"
        fi
    done
    cd ..
fi
#######################################
#       PREP_CHEM_SRC                 #
#######################################
if [ "$type" = "Chem" ]; then
 if [ "$prep_chem_validation" != "yes" ] && [ "$non_interactive" = "no" ]; then
  echo "Install optional PREP-CHEM-SRC? Please type yes or no."
  read -r prep_chem_validation
 fi
 if [ "$prep_chem_validation" = "yes" ]; then
  echo "Building convert_emiss.exe from the completed WRF-Chem libraries."
  cd "$build_dir/WRF-${WRFversion}-${type}"
  # The top-level ./compile emi_conv regenerates KPP and rebuilds WRF.
  # Its final chem target can reuse the already compiled WRF libraries directly.
  # shellcheck disable=SC2016
  logsave convert_emi.log make -C chem WRF_SRC_ROOT_DIR="$PWD" \
      WRF_EM_CORE=1 WRF_NMM_CORE=0 WRF_DA_CORE=0 WRF_PLUS_CORE=0 WRF_NMM_NEST=0 \
      MODULE_DIRS='-I../dyn_em $(INCLUDE_MODULES)' SOLVER=em IDEAL_CASE=real convert_emiss
  if [ ! -x chem/convert_emiss.exe ]; then
      echo "Emissions converter build failed: chem/convert_emiss.exe is missing." >&2
      exit 1
  fi
  ln -sfn ../../chem/convert_emiss.exe test/em_real/convert_emiss.exe
  ln -sfn ../chem/convert_emiss.exe run/convert_emiss.exe
  cd "$build_dir"
  [ -d "PREP-CHEM-SRC-1.5" ] && mv PREP-CHEM-SRC-1.5 PREP-CHEM-SRC-1.5-"${backup_suffix}"
  prep_source_archive=prep_chem_sources_v1.5_24aug2015.tar.gz
  prep_data_archive=global_emissions_v3_24aug2015.tar.gz
  prep_url=ftp://aftp.fsl.noaa.gov/divisions/taq/global_emissions
  wget -c "$prep_url/$prep_source_archive" -O "$prep_source_archive"
  tar -zxf "$prep_source_archive"
  cd PREP-CHEM-SRC-1.5/bin/build
  sed -i "s#NETCDF=.*#NETCDF=/usr#" include.mk.gfortran.wrf
  # Preserve make variables in the source file.
  # shellcheck disable=SC2016
  sed -i 's#-L$(NETCDF)/lib#-L/usr/lib/x86_64-linux-gnu#' include.mk.gfortran.wrf
  sed -i "s#HDF5=.*#HDF5=/usr/lib/x86_64-linux-gnu/hdf5/serial#" include.mk.gfortran.wrf
  sed -i "s#HDF5_INC=.*#HDF5_INC=-I/usr/include/hdf5/serial#" include.mk.gfortran.wrf
  # shellcheck disable=SC2016
  sed -i 's#-L$(HDF5)/lib#-L/usr/lib/x86_64-linux-gnu/hdf5/serial#' include.mk.gfortran.wrf
  gfortversion=$(gfortran -dumpversion | cut -d '.' -f 1)
  if [ "$gfortversion" -ge 10 ]; then
   # shellcheck disable=SC2016
   sed -i 's#F_OPTS=.*#F_OPTS= -Xpreprocessor -D$(CHEM) -O2 -fconvert=big-endian -frecord-marker=4 -fallow-argument-mismatch#' include.mk.gfortran.wrf
  fi
  # GNU C99 preserves legacy declarations; PC_LINUX1 selects Fortran symbol names.
  # shellcheck disable=SC2016
  sed -i 's#^C_OPTS=.*#C_OPTS= -O2 -std=gnu99 -D$(CMACH)#' include.mk.gfortran.wrf
  sed -i '1i #include <stdlib.h>' ../../aux_src/utils/eenviron.c
  sed -i '/extern char \*getenv(char\*);/d' ../../aux_src/utils/eenviron.c
  sed -i '1i #include <stdlib.h>\n#include <string.h>' ../../aux_src/utils/tmpname.c
  sed -i "s#-L/scratchin/grupos/catt-brams/shared/libs/gfortran/zlib-1.2.8/lib#-L/usr/lib#" include.mk.gfortran.wrf
  sed -i "842s#.*#    'ENERGY     ',\&#" ../../src/edgar_emissions.f90
  sed -i "843s#.*#    'INDUSTRY   ',\&#" ../../src/edgar_emissions.f90
  sed -i "845s#.*#    'TRANSPORT  '/)#" ../../src/edgar_emissions.f90
  logsave compile.log make OPT=gfortran.wrf CHEM=RADM_WRF_FIM
  if [ ! -x ../prep_chem_sources_RADM_WRF_FIM_.exe ]; then
      echo "PREP-CHEM-SRC build failed: executable is missing." >&2
      exit 1
  fi
  cd "$build_dir"
  # Keep the large data archive outside the source tree so repeat installs reuse it.
  wget -c "$prep_url/$prep_data_archive" -O "$prep_data_archive"
  cd PREP-CHEM-SRC-1.5/bin
  mkdir -p datain
  cd datain
  tar -zxf "$build_dir/$prep_data_archive"
  mv Global_emissions_v3/* .
  rm -r Global_emissions_v3
  mv Emission_data/ EMISSION_DATA
  mv surface_data/ SURFACE_DATA
  cd "$build_dir"
  echo "PREP-CHEM-SRC and convert_emiss.exe builds completed; emissions data installed."
 fi
fi
##########################################################
#	End						#
##########################################################
echo "Installation has completed"
if [ "$non_interactive" = "no" ]; then
 exec bash
fi
