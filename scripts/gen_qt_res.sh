#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <device-model>" >&2
    exit 2
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
model_dir="$script_dir/../resource/models/$1"

echo 'generating resource.qrc...'
python3 "$script_dir/gen_qrc.py" "$model_dir" "$model_dir/resource.qrc"

echo 'generating qrc_qml.h...'
python3 "$script_dir/gen_qt_res.py" "$model_dir"

echo 'done.'
