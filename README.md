# WRF-Install-Script


WRF Install script will install the WRF and WPS with the needed libraries(netcdf4, hdf5, mpich, zlib, libpng, jasper). You can choose the version that you want to install. This Script is written for Debian and Ubuntu based Linux operating systems.

To run the scripts, you should run the commands below.

For WRF4.7.1 with ARW option(default)

```
bash WRF4.7.1_Install.bash
```
or
```
bash WRF4.7.1_Install.bash -arw
```

For WRF4.7.1 with Chem option (WRF-Chem)
```
bash WRF4.7.1_Install.bash -chem
```

For WRF4.7.1 with Hydro option (WRF-Hydro)
```
bash WRF4.7.1_Install.bash -hydro
```

To place the installation on a filesystem with sufficient space, select its build directory:

```bash
bash WRF4.7.1_Install.bash -arw --build-dir /tmp/Build_WRF --non-interactive --jobs 2
```

Geography is downloaded and extracted into `WPS_GEOG` under the selected build
directory. Chem also extracts its additional datasets there. Existing extracted
geography is reused in non-interactive mode.

`--non-interactive` reuses existing extracted geography, skips the optional
PREP-CHEM-SRC installation unless `--with-prep-chem` is supplied, and returns
to the calling shell when finished.
System package installation still requires sudo access.
`--build-dir PATH` selects an isolated installation directory (default:
`~/Build_WRF`), and `--jobs N` limits WRF compilation processes (default: all
available CPUs). Previous build directories are backed up with a timestamp; the WPS build uses the selected WRF
variant. Build success requires all four WRF and all three WPS executables.

To include PREP-CHEM-SRC 1.5 and `convert_emiss.exe` in a Chem installation:

```bash
bash WRF4.7.1_Install.bash -chem --with-prep-chem --non-interactive --jobs 2
```

The converter reuses the completed WRF-Chem libraries. PREP-CHEM-SRC's separate
global emissions archive is about 2.41 GB and contains 5.54 GiB of extracted
data. It is cached in the build directory and extracted under
`PREP-CHEM-SRC-1.5/bin/datain`.
Configure `prep_chem_sources.inp` for the chosen inventory and model domain
before using PREP-CHEM-SRC for a simulation.

The geography behavior can be checked without downloads:

```bash
bash tests/geography.bash
```

The short runtime checks use extracted NCAR sample data and create a new results
directory. The WRF check uses two MPI processes, two domains, six simulated
minutes, WSM6 microphysics and disabled chemistry. Coupled Hydro simulations
require a separate hydrologic test case; `--real-only` checks initialization
without running a coupled forecast.

```bash
bash tests/runtime-smoke.bash /path/to/WRF-4.7.1-ARW /path/to/v431-test-data /path/to/new-wrf-results
bash tests/ungrib-smoke.bash /path/to/WPS-4.7.0 /path/to/avn-test-data /path/to/new-ungrib-results
```

After the Chem runtime check, the PREP-CHEM-SRC check uses its `wrfinput_d01`
and namelist to map the bundled EDGAR v4 HDF5 inventory onto the Lambert grid.
It then converts the emissions with two MPI processes and verifies that all
CO and SO2 values are preserved in the WRF NetCDF file:

```bash
bash tests/prep-chem-smoke.bash /path/to/PREP-CHEM-SRC-1.5 /path/to/WRF-4.7.1-Chem /path/to/verified-wrf-results /path/to/new-prep-results
```

Sample data: [WRF real-data case](https://www2.mmm.ucar.edu/wrf/test_data/v431_test_case.tar.gz)
and [WPS GRIB input](https://www2.mmm.ucar.edu/wrf/src/data/avn_data.tar.gz).
Validated on Ubuntu 26.04 (x86_64): ARW/Chem/Hydro builds, WPS decoding,
PREP-CHEM-SRC mapping and emissions conversion. Runtime checks have the scope
described above. Detailed logs and machine-specific recovery files are kept
outside the repository.

The JPEG2000 GRIB2 decoder check requires Python 3 and uses a small synthetic
fixture with known pressure values:

```bash
bash tests/jpeg2000-smoke.bash /path/to/WPS-4.7.0 /path/to/new-jpeg-results
```

Its companion `.filter` file documents the fixture. With ecCodes tools installed,
regenerate it from the repository directory:

```bash
grib_filter -o pressure-jpeg2000.grib2 tests/fixtures/pressure-jpeg2000.filter \
    /usr/share/eccodes/samples/regular_ll_sfc_grib2.tmpl
```
