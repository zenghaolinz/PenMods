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
rcc -name qml "$model_dir/resource.qrc" -o "$model_dir/qrc_qml.cpp"

line_count="$(wc -l < "$model_dir/qrc_qml.cpp")"
head -n "$((line_count - 58))" "$model_dir/qrc_qml.cpp" > "$model_dir/qrc_qml.h"
rm "$model_dir/qrc_qml.cpp"

echo 'done.'
