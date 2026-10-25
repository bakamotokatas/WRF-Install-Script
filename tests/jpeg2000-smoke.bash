#!/usr/bin/env bash
# The synthetic 8x8 GRIB2 fixture uses JPEG2000 and pressures 100000..100063 Pa.
# Generated with ecCodes 2.45.0; the companion filter documents its construction.
set -euo pipefail
if [ "$#" -ne 2 ]; then
    echo "Usage: bash $0 WPS_BUILD_DIR NEW_RESULTS_DIR (requires python3)" >&2
    exit 1
fi
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
wps_dir=$(realpath "$1")
results_dir=$(realpath -m "$2")
if [ -e "$results_dir" ]; then
    echo "Results directory already exists: $results_dir" >&2
    exit 1
fi
mkdir -p "$results_dir"
cd "$results_dir"
cat > namelist.wps <<'NAMELIST'
&share
 wrf_core = 'ARW',
 max_dom = 1,
 start_date = '2026-01-01_00:00:00',
 end_date = '2026-01-01_00:00:00',
 interval_seconds = 3600,
/
&ungrib
 out_format = 'WPS',
 prefix = 'JPEG',
/
NAMELIST
ln -s "$wps_dir/ungrib/Variable_Tables/Vtable.GFS" Vtable
ln -s "$repo_dir/tests/fixtures/pressure-jpeg2000.grib2" GRIBFILE.AAA
timeout 60 "$wps_dir/ungrib.exe" > ungrib.stdout.log 2>&1
grep -q 'Successful completion of program ungrib' ungrib.log
python3 - <<'PY'
from pathlib import Path
import struct
raw = Path('JPEG:2026-01-01_00').read_bytes()
records = []
offset = 0
while offset < len(raw):
    size = struct.unpack_from('>i', raw, offset)[0]
    offset += 4
    records.append(raw[offset:offset + size])
    offset += size
    assert struct.unpack_from('>i', raw, offset)[0] == size
    offset += 4
values = struct.unpack('>64f', records[-1])
assert sorted(values) == [float(100000 + i) for i in range(64)]
print('PASS: JPEG2000 GRIB2 decoded; all 64 pressure values match exactly.')
PY
