#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <fen_file>"
    exit 1
fi

filename=$1

echo "Validating $filename..."

line_num=1
prev_line=""
issues=0

while IFS= read -r line; do
    if [ $line_num -gt 1 ] && [ -n "$prev_line" ]; then
        prev_board=$(echo "$prev_line" | cut -d' ' -f1)
        curr_board=$(echo "$line" | cut -d' ' -f1)

        # Count total pieces
        prev_total=$(echo "$prev_board" | grep -o '[rnbqkpRNBQKP]' | wc -l)
        curr_total=$(echo "$curr_board" | grep -o '[rnbqkpRNBQKP]' | wc -l)

        diff=$((prev_total - curr_total))

        if [ $diff -gt 2 ] || [ $diff -lt -1 ]; then
            echo "Line $line_num: Suspicious change ($prev_total → $curr_total pieces, diff=$diff)"
            issues=$((issues + 1))
        fi
    fi

    prev_line="$line"
    line_num=$((line_num + 1))
done < "$filename"

if [ $issues -eq 0 ]; then
    echo "✅ $filename validated - no illegal piece movements"
else
    echo "❌ $filename has $issues potential issues"
fi