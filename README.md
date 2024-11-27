# WRF-Install-Script


WRF Install scripts will install the WRF and WPS with the needed libraries(netcdf4 hdf5, mpich, zlib, libpng, jasper). You can choose the version that you want to install. These scripts are written for Debian and Ubuntu based Linux operating systems, such as Ubuntu, Debian, Linux Mint, Pardus, etc.

Since WRF-Install-Script uses operating system libraries, it installs much faster than manually installing the libraries and then installing the WRF model.

You can download each version from the [releases](https://github.com/bakamotokatas/WRF-Install-Script/releases).

Currently only WRF4.6.1_Install.bash, WRF4.6.0_Install.bash, WRF4.5.2_Install.bash, WRF4.5.1_Install.bash, WRF4.5_Install.bash, WRF4.4.2_Install.bash, WRF4.4.1_Install.bash, WRF4.4_Install.bash and WRF4.3.3_Install.bash support Ubuntu 22.04. Therefore if you are using Ubuntu 22.04, please use WRF4.6.1_Install.bash, WRF4.6.0_Install.bash, WRF4.5.2_Install.bash, WRF4.5.1_Install.bash, WRF4.5_Install.bash, WRF4.4.2_Install.bash, WRF4.4.1_Install.bash, WRF4.4_Install.bash and WRF4.3.3_Install.bash, otherwise it will fail to build. All other releases will be updated soon to support Ubuntu 22.04.

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

For WRF4.5.2 with ARW option(default)

```
bash WRF4.5.2_Install.bash
```
or
```
bash WRF4.5.2_Install.bash -arw
```

For WRF4.5.2 with Chem option (WRF-Chem)
```
bash WRF4.5.2_Install.bash -chem
```

For WRF4.5.2 with Hydro option (WRF-Hydro)
```
bash WRF4.5.2_Install.bash -hydro
```

For WRF4.4.2 with ARW option(default)

```
bash WRF4.4.2_Install.bash
```
or
```
bash WRF4.4.2_Install.bash -arw
```

For WRF4.4.2 with Chem option (WRF-Chem)
```
bash WRF4.4.2_Install.bash -chem
```

For WRF4.4.2 with Hydro option (WRF-Hydro)
```
bash WRF4.4.2_Install.bash -hydro
```

For WRF4.3.3 with ARW option(default)

```
bash WRF4.3.3_Install.bash
```
or
```
bash WRF4.3.3_Install.bash -arw
```

For WRF4.3.3 with Chem option (WRF-Chem)
```
bash WRF4.3.3_Install.bash -chem
```
For WRF4.3.3 with NMM option
```
bash WRF4.3.3_Install.bash -nmm
```



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
