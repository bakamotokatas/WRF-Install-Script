# WRF-Install-Script


WRF Install script will install the WRF and WPS with the needed libraries(netcdf4, hdf5, mpich, zlib, libpng, jasper). You can choose the version that you want to install. This Script is written for Debian and Ubuntu based Linux operating systems.

To run the scripts, you should run the commands below.

For WRF4.6.1 with ARW option(default)

```
bash WRF4.6.1_Install.bash
```
or
```
bash WRF4.6.1_Install.bash -arw
```

For WRF4.6.1 with Chem option (WRF-Chem)
```
bash WRF4.6.1_Install.bash -chem
```

For WRF4.6.1 with Hydro option (WRF-Hydro)
```
bash WRF4.6.1_Install.bash -hydro
```
