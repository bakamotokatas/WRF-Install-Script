#!/usr/bin/env bash
# Use NCAR's extracted avn_data.tar.gz without extracting any WPS geography.
set -euo pipefail
if [ "$#" -ne 3 ]; then
    echo "Usage: bash $0 WPS_BUILD_DIR EXTRACTED_AVN_DATA NEW_RESULTS_DIR" >&2
    exit 1
fi
wps_dir=$(realpath "$1")
data_dir=$(realpath "$2")
results_dir=$(realpath -m "$3")
if [ -e "$results_dir" ]; then
    echo "Results directory already exists: $results_dir" >&2
    exit 1
fi
mkdir -p "$results_dir"
cd "$results_dir"
cp "$wps_dir/namelist.wps" .
sed -i -E \
    -e "s/^[[:space:]]*start_date[[:space:]]*=.*/ start_date = '2000-01-24_12:00:00',/" \
    -e "s/^[[:space:]]*end_date[[:space:]]*=.*/ end_date = '2000-01-25_00:00:00',/" \
    -e 's/^[[:space:]]*max_dom[[:space:]]*=.*/ max_dom = 1,/' \
    -e 's/^[[:space:]]*interval_seconds[[:space:]]*=.*/ interval_seconds = 21600,/' namelist.wps
ln -s "$wps_dir/ungrib/Variable_Tables/Vtable.GFS" Vtable
"$wps_dir/link_grib.csh" "$data_dir"/fnl_2000*
timeout 180 "$wps_dir/ungrib.exe" > ungrib.stdout.log 2>&1
grep -q 'Successful completion of program ungrib' ungrib.log
for date_hour in 2000-01-24_12 2000-01-24_18 2000-01-25_00; do
    test -s "FILE:$date_hour"
done
printf '%s\n' "PASS: ungrib converted three GRIB input times ($wps_dir)."
