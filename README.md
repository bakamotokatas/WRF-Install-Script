# WRF-Install-Script


WRF Install scripts will install the WRF and WPS with the needed libraries(netcdf4 hdf5, mpich, zlib, libpng, jasper). You can choose the version that you wanted to install. These Scripts is written for Debian based linux operating systems.

To run the scripts, you should run the commands below.

For WRF4.2.2 with ARW option(default)

```
bash WRF4.2.2_Install.bash
```
or
```
bash WRF4.2.2_Install.bash -arw
```

For WRF4.2.2 with Chem option
```
bash WRF4.2.2_Install.bash -chem
```
For WRF4.2.2 with NMM option
```
bash WRF4.2.2_Install.bash -nmm
```
Chem and NMM options not available before WRF4.2.2_Install script

For WRF4.1.5

```
bash WRF4.1.5_Install.bash
```

For WRF4.1.3

```
bash WRF4.1.3_Install.bash
```

For WRF4.1.2

```
bash WRF4.1.2_Install.bash
```

For WRF4.1

```
bash WRF4.1_Install.bash
```

For WRF4.0.3

```
bash WRF4.0.3_Install.bash
```

For WRF4.0.1

```
bash WRF4.0.1_Install.bash
```


For WRF4.0

```
bash WRF4.0_Install.bash
```



You will be asked the write number(No need after 4.0.3 install script), while it is installing the WRF. You should choose the number 34, when it is configuring WRF which will be asked first,and you should choose the number 1, when it is configuring WPS which will be asked second.
