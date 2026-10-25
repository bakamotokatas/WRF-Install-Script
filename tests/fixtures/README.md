# JPEG2000 GRIB2 test fixture

`pressure-jpeg2000.grib2` is a synthetic test fixture, not an operational
forecast or observation. It was generated with ecCodes 2.45.0 from its
[`regular_ll_sfc_grib2.tmpl` sample](https://github.com/ecmwf/eccodes/blob/2.45.0/samples/regular_ll_sfc_grib2.tmpl)
using the accompanying `pressure-jpeg2000.filter`.

The filter changes the sample to an 8 by 8 grid, sets the date to 2026-01-01
at 00:00, selects surface pressure and JPEG2000 packing, and replaces all
values with the sequence 100000 through 100063 Pa. These values were chosen
for the decoder test and do not represent ECMWF data.

The ecCodes sample comes from ECMWF's Apache License 2.0 project. The upstream
license and notices are preserved in [LICENSE.ecCodes](LICENSE.ecCodes) and
[NOTICE.ecCodes](NOTICE.ecCodes), copied unchanged from the
[ecCodes 2.45.0 release](https://github.com/ecmwf/eccodes/tree/2.45.0).
These files document this fixture's upstream material; they do not assign a
license to the entire WRF-Install-Script repository.

To regenerate the fixture from the repository root with JPEG2000 support
enabled in ecCodes:

```bash
grib_filter -o tests/fixtures/pressure-jpeg2000.grib2 \
    tests/fixtures/pressure-jpeg2000.filter \
    /usr/share/eccodes/samples/regular_ll_sfc_grib2.tmpl
```
