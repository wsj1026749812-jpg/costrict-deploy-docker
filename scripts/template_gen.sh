#!/bin/bash
set -eo pipefail

# Get the directory where this script is located
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly SCRIPT_DIR

# Template list file is located in the same directory as this script
readonly TEMPLATES_LIST="${SCRIPT_DIR}/templates.list"

# Working directory: where the script is called from
readonly BASE_DIR=$(pwd)

# Load environment variables from configure.sh (located in BASE_DIR)
readonly CONFIGURE_SH="${BASE_DIR}/configure.sh"
if [[ -f "$CONFIGURE_SH" ]]; then
    # shellcheck source=../configure.sh
    set -a
    # shellcheck disable=SC1090
    source "$CONFIGURE_SH"
    set +a
else
    echo "WARN: configure.sh not found: ${CONFIGURE_SH}" >&2
fi

export COSTRICT_DEPLOY_DIR="${COSTRICT_DEPLOY_DIR:-${BASE_DIR}}"

# Load image environment variables from scripts/images.list (KEY=VALUE format)
# Lines containing '=' are treated as variable definitions; others are skipped
readonly IMAGES_LIST="${SCRIPT_DIR}/newest-images.list"
if [[ -f "$IMAGES_LIST" ]]; then
    set -a
    while IFS= read -r img_line || [[ -n "$img_line" ]]; do
        [[ -z "$img_line" || "$img_line" == \#* ]] && continue
        # Only source lines that look like KEY=VALUE assignments
        if [[ "$img_line" == *=* ]]; then
            # shellcheck disable=SC2163
            export "${img_line?}"
        fi
    done < "$IMAGES_LIST"
    set +a
else
    echo "WARN: images.list not found: ${IMAGES_LIST}" >&2
fi

# Replace {{varname}} markers in a template file with actual environment variable values
# Usage: resolve_file <input_file> <output_file>
resolve_file() {
    local input_file=$1
    local output_file=$2

    cp -f "$input_file" "$output_file"

    for i in $(grep -o -E "\{\{([[:alnum:]]|\.|_)*\}\}" "$output_file" | sort | uniq | tr -d '\r'); do
        local key="${i:2:${#i}-4}"
        local value
        value=$(eval echo "\$$key")
        if echo "$value" | grep -vq '#'; then
            sed -i "s#${i}#${value}#g" "$output_file"
        elif echo "$value" | grep -vq '/'; then
            sed -i "s/${i}/${value}/g" "$output_file"
        elif echo "$value" | grep -vq ','; then
            sed -i "s,${i},${value},g" "$output_file"
        else
            echo "WARN: Value for '${key}' contains special characters '#/,'; skipping" >&2
        fi
    done
}

if [[ ! -f "$TEMPLATES_LIST" ]]; then
    echo "ERROR: Template list not found: ${TEMPLATES_LIST}" >&2
    exit 1
fi

while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue

    tpl_file="${BASE_DIR}/${line}"

    if [[ ! -f "$tpl_file" ]]; then
        echo "ERROR: Template not found: ${tpl_file}" >&2
        exit 1
    fi

    if [[ "$tpl_file" == *.tpl ]]; then
        out_file="${tpl_file%.tpl}"
    else
        out_file="$tpl_file"

    fi

    resolve_file "$tpl_file" "$out_file"
    echo "${tpl_file} -> ${out_file}"
done < "$TEMPLATES_LIST"
