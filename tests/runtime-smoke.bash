#!/usr/bin/env bash
# Use NCAR's v431_test_case.tar.gz (already extracted) for a six-minute run.
# Use WSM6 microphysics to avoid generating Thompson lookup tables in a smoke test.
# Chem is tested with chemistry disabled; Hydro needs its own coupled test case.
set -euo pipefail
if [ "$#" -ne 3 ] && [ "$#" -ne 4 ]; then
    echo "Usage: bash $0 WRF_BUILD_DIR EXTRACTED_TEST_DATA NEW_RESULTS_DIR [--real-only]" >&2
    exit 1
fi
if [ "$#" -eq 4 ] && [ "$4" != --real-only ]; then
    echo "Unknown runtime option: $4" >&2
    exit 1
fi
wrf_dir=$(realpath "$1")
data_dir=$(realpath "$2")
results_dir=$(realpath -m "$3")
# Preserve earlier test evidence instead of overwriting it.
if [ -e "$results_dir" ]; then
    echo "Results directory already exists: $results_dir" >&2
    exit 1
fi
mkdir -p "$results_dir"
cd "$results_dir"
for runtime_file in "$wrf_dir"/run/*; do
    case "$(basename "$runtime_file")" in
        namelist.input|*.exe) continue ;;
    esac
    ln -s "$(realpath "$runtime_file")" "$(basename "$runtime_file")"
done
ln -s "$wrf_dir/main/real.exe" .
ln -s "$wrf_dir/main/wrf.exe" .
ln -s "$data_dir"/met_em*.nc .
cp "$data_dir/namelist.input" .
sed -i -E \
    -e 's/^( run_hours[[:space:]]*=).*/\1 0,/' \
    -e 's/^( run_minutes[[:space:]]*=).*/\1 6,/' \
    -e 's/^( mp_physics[[:space:]]*=).*/\1 6, 6,/' namelist.input

timeout 300 mpiexec -np 2 ./real.exe > real.stdout.log 2>&1
grep -q 'SUCCESS COMPLETE REAL_EM INIT' rsl.error.0000
test -s wrfinput_d01
test -s wrfinput_d02
test -s wrfbdy_d01
cp rsl.error.0000 real.rsl.error.0000
cp rsl.out.0000 real.rsl.out.0000

if [ "${4:-}" = --real-only ]; then
    printf '%s\n' "PASS: two-rank real.exe initialization ($wrf_dir)."
    exit 0
fi

timeout 300 mpiexec -np 2 ./wrf.exe > wrf.stdout.log 2>&1
grep -q 'SUCCESS COMPLETE WRF' rsl.error.0000
# Require output from both the coarse and nested domain.
compgen -G 'wrfout_d01*' > /dev/null
compgen -G 'wrfout_d02*' > /dev/null
printf '%s\n' "PASS: two-rank real.exe initialization and six-minute nested wrf.exe run ($wrf_dir)."
