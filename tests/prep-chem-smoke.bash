#!/usr/bin/env bash
# Map the bundled EDGAR v4 HDF5 inventory, then check the WRF emissions conversion.
# The verified WRF case supplies wrfinput_d01 and namelist.input (Lambert grid).
set -euo pipefail
if [ "$#" -ne 4 ]; then
    echo "Usage: bash $0 PREP_DIR WRF_DIR VERIFIED_WRF_CASE NEW_RESULTS_DIR" >&2
    exit 1
fi
prep_dir=$(realpath "$1")
wrf_dir=$(realpath "$2")
case_dir=$(realpath "$3")
results_dir=$(realpath -m "$4")
if [ -e "$results_dir" ]; then
    echo "Results directory already exists: $results_dir" >&2
    exit 1
fi
test -s "$prep_dir/bin/datain/EMISSION_DATA/EDGARV4/EDGAR_2005.h5"
mkdir -p "$results_dir/convert"
cd "$results_dir"
ln -s "$prep_dir/bin/datain" datain
python3 - "$prep_dir" "$wrf_dir" "$case_dir" <<'PY'
from pathlib import Path
import datetime
import json
import re
import subprocess
import sys

prep, wrf, case = map(Path, sys.argv[1:])
header = subprocess.check_output(['ncdump', '-h', str(case / 'wrfinput_d01')], text=True)
def attribute(name):
    value = re.search(r':' + name + r'\s*=\s*([^;]+);', header).group(1).strip()
    return value.strip('"').removesuffix('f')
def dimension(name):
    return int(re.search(r'\b' + name + r'\s*=\s*(\d+)\s*;', header).group(1))
assert int(attribute('MAP_PROJ')) == 1, 'This check requires a Lambert WRF case.'
nx, ny = dimension('west_east_stag'), dimension('south_north_stag')
date = datetime.datetime.strptime(attribute('START_DATE'), '%Y-%m-%d_%H:%M:%S')
source = (prep / 'bin/prep_chem_sources.inp').read_text()
settings = dict.fromkeys([
    'use_retro', 'use_gocart', 'use_streets', 'use_seac4rs', 'use_fwbawb',
    'use_bioge', 'use_gfedv2', 'use_bbem', 'use_bbem_plumerise', 'use_vcf',
    'use_gocart_bg', 'use_volcanoes', 'use_degass_volcanoes', 'merge_GFEDv2_bbem'
], '0')
settings.update({
    'use_edgar': '2', 'edgar_data_dir': "'./datain/EMISSION_DATA/EDGARV4'",
    'grid_type': "'lambert'", 'ngrids': '1', 'nnxp': str(nx), 'nnyp': str(ny),
    'nxtnest': '0', 'nstratx': '1', 'nstraty': '1', 'ninest': '1', 'njnest': '1',
    'deltax': attribute('DX'), 'deltay': attribute('DY'),
    'polelat': attribute('CEN_LAT'), 'polelon': attribute('STAND_LON'),
    'centlat': attribute('CEN_LAT'), 'centlon': attribute('CEN_LON'),
    'stdlat1': attribute('TRUELAT1'), 'stdlat2': attribute('TRUELAT2'),
    'ihour': str(date.hour), 'iday': str(date.day), 'imon': str(date.month),
    'iyear': str(date.year), 'proj_to_ll': "'NOT'", 'chem_out_prefix': "'WRF'",
    'special_output_to_wrf': "'YES'", 'chem_out_format': "'vfm'"
})
for key, value in settings.items():
    source, count = re.subn(r'^\s*' + key + r'\s*=.*$', f' {key} = {value},',
                            source, flags=re.I | re.M)
    assert count == 1, (key, count)
Path('prep_chem_sources.inp').write_text(source)
Path('grid.json').write_text(json.dumps(dict(nx=nx, ny=ny, date=date.isoformat())))

namelist = (case / 'namelist.input').read_text()
def configure_group(name, values):
    global namelist
    pattern = r'(^\s*&' + name + r'\b)(.*?)(^\s*/\s*$)'
    match = re.search(pattern, namelist, flags=re.I | re.M | re.S)
    assert match, name
    body = match.group(2)
    for key, value in values.items():
        line = f' {key} = {value},'
        body, count = re.subn(r'^\s*' + key + r'\s*=.*$', line, body, flags=re.I | re.M)
        if not count:
            body += line + '\n'
    namelist = namelist[:match.start()] + match.group(1) + body + match.group(3) + namelist[match.end():]
configure_group('domains', {'max_dom': '1'})
# Unlike real.exe/wrf.exe, convert_emiss does not resolve physics_suite defaults.
configure_group('physics', {name: attribute(name.upper()) for name in [
    'mp_physics', 'cu_physics', 'ra_lw_physics', 'ra_sw_physics',
    'bl_pbl_physics', 'sf_sfclay_physics', 'sf_surface_physics'
]})
times = {'run_days': '0', 'run_hours': '0', 'run_minutes': '0', 'run_seconds': '0',
         'io_form_auxinput5': '2', 'auxinput5_interval_m': '1440',
         'frames_per_auxinput5': '1'}
for key in ['year', 'month', 'day', 'hour', 'minute', 'second']:
    times['end_' + key] = str(getattr(date, key))
configure_group('time_control', times)
chem = '''&chem
 chem_opt = 0,
 emiss_opt = 5,
 emiss_inpt_opt = 1,
 kemit = 1,
 biomass_burn_opt = 0,
 bio_emiss_opt = 0,
 emiss_opt_vol = 0,
/
'''
namelist = re.sub(r'^\s*&chem\b.*?^\s*/\s*$', '', namelist, flags=re.I | re.M | re.S)
Path('convert/namelist.input').write_text(namelist + '\n' + chem)
for p in (wrf / 'run').iterdir():
    if p.name == 'namelist.input' or p.name.endswith('.exe'):
        continue
    (Path('convert') / p.name).symlink_to(p.resolve())
Path('convert/wrfinput_d01').symlink_to(case / 'wrfinput_d01')
PY
timeout 180 "$prep_dir/bin/prep_chem_sources_RADM_WRF_FIM_.exe" > prep.stdout.log 2>&1
shopt -s nullglob
emissions=(WRF*-ab.bin)
if [ "${#emissions[@]}" -ne 1 ]; then
    echo "PREP-CHEM-SRC did not produce a unique anthropogenic emissions file." >&2
    exit 1
fi
ln -s "../${emissions[0]}" convert/emissopt3_d01
cd convert
timeout 180 mpiexec -np 2 "$wrf_dir/chem/convert_emiss.exe" > convert.stdout.log 2>&1
test -s wrfchemi_d01
ncdump -h wrfchemi_d01 > wrfchemi-header.log
cd ..
python3 - "${emissions[0]}" <<'PY'
from pathlib import Path
import json
import math
import re
import struct
import subprocess
import sys

grid = json.loads(Path('grid.json').read_text())
nx, ny = grid['nx'], grid['ny']
raw = Path(sys.argv[1]).read_bytes()
records = []
offset = 0
while offset < len(raw):
    size = struct.unpack_from('>i', raw, offset)[0]
    offset += 4
    records.append(raw[offset:offset + size])
    offset += size
    assert struct.unpack_from('>i', raw, offset)[0] == size
    offset += 4
assert struct.unpack('>i', records[0])[0] == 29
summary = {}
# The legacy RADM WRFFIM stream starts with SO2 and has CO as its 12th field.
for variable, index in [('E_SO2', 3), ('E_CO', 14)]:
    assert len(records[index]) == nx * ny * 4
    values = struct.unpack(f'>{nx * ny}f', records[index])
    expected = [values[j * nx + i] for j in range(ny - 1) for i in range(nx - 1)]
    assert all(math.isfinite(v) and v >= 0 for v in expected)
    assert max(expected) > 0, f'{variable}: inventory produced no positive emissions'
    nc = subprocess.check_output(['ncdump', '-p', '9,17', '-v', variable,
                                  'convert/wrfchemi_d01'], text=True)
    data = nc.split('\ndata:\n', 1)[1]
    payload = re.search(r'\b' + variable + r'\s*=\s*(.*?);', data, flags=re.S).group(1)
    actual = [struct.unpack('f', struct.pack('f', float(v)))[0]
              for v in re.split(r'[,\s]+', payload.strip()) if v]
    assert actual == expected, f'{variable}: conversion changed inventory values or dimensions'
    summary[variable] = dict(cells=len(actual), maximum=max(actual), total=sum(actual))
Path('value-checks.json').write_text(json.dumps(summary, indent=2) + '\n')
print('PASS: EDGAR v4 HDF5 -> PREP-CHEM-SRC -> two-rank convert_emiss -> WRF NetCDF;')
print('      CO and SO2 are finite, positive somewhere, and match the binary inputs exactly.')
PY
