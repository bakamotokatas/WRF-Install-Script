#!/usr/bin/env bash
# The sourced block uses these variables and is generated at runtime.
# shellcheck disable=SC1091,SC2034
# Exercise the installer's actual geography block without network or large files.
set -euo pipefail
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
awk '/^geog_url=/{capture=1} capture && /^#       PREP_CHEM_SRC/{exit} capture {print}' \
    "$repo_dir/WRF4.7.1_Install.bash" > "$test_dir/geography.bash"

wget() {
    printf '%s\n' "$*" >> downloads.log
    while [ "$#" -gt 0 ]; do
        if [ "$1" = '-O' ]; then
            touch "$2"
            return
        fi
        shift
    done
    return 1
}
tar() {
    printf '%s\n' "$*" >> extractions.log
    if [ "$2" = geog_high_res_mandatory.tar.gz ]; then
        mkdir -p WPS_GEOG
    else
        mkdir -p "${2%.tar.bz2}"
    fi
}

for type in ARW Chem Hydro; do
    mkdir "$test_dir/$type"
    (
        cd "$test_dir/$type"
        non_interactive=yes
        source "$test_dir/geography.bash"
        test -f geog_high_res_mandatory.tar.gz
        test -d WPS_GEOG
        test -s extractions.log
        if [ "$type" = Chem ]; then
            test -d WPS_GEOG/erod
            test "$(find WPS_GEOG -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 8
            test "$(find WPS_GEOG -name '*.tar.bz2' | wc -l)" -eq 0
        fi
        # A second non-interactive run reuses existing extracted datasets.
        download_count=$(find . -name downloads.log -exec cat {} + | wc -l)
        extraction_count=$(find . -name extractions.log -exec cat {} + | wc -l)
        source "$test_dir/geography.bash"
        test "$(find . -name downloads.log -exec cat {} + | wc -l)" -eq "$download_count"
        test "$(find . -name extractions.log -exec cat {} + | wc -l)" -eq "$extraction_count"
    )
done
printf '%s\n' 'PASS: ARW/Chem/Hydro geography extraction, Chem archive cleanup and dataset reuse.'
