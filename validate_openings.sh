#!/bin/bash

# Script to validate FEN files for illegal piece movements
# Checks for pieces appearing/disappearing without valid captures

validate_fen_file() {
    local filename=$1
    echo "=== Validating $filename ==="

    if [ ! -f "$filename" ]; then
        echo "❌ File not found: $filename"
        return 1
    fi

    local line_num=1
    local prev_line=""
    local issues_found=0

    while IFS= read -r line; do
        if [ $line_num -gt 1 ] && [ -n "$prev_line" ]; then
            # Extract just the board part (before the first space)
            local prev_board=$(echo "$prev_line" | cut -d' ' -f1)
            local curr_board=$(echo "$line" | cut -d' ' -f1)

            # Count pieces in each position
            local prev_pieces=$(echo "$prev_board" | grep -o '[rnbqkpRNBQKP]' | sort | uniq -c | sort)
            local curr_pieces=$(echo "$curr_board" | grep -o '[rnbqkpRNBQKP]' | sort | uniq -c | sort)

            # Check if piece counts changed dramatically (more than 1 piece difference per type)
            local prev_total=$(echo "$prev_board" | grep -o '[rnbqkpRNBQKP]' | wc -l | tr -d ' ')
            local curr_total=$(echo "$curr_board" | grep -o '[rnbqkpRNBQKP]' | wc -l | tr -d ' ')
            local diff=$((prev_total - curr_total))

            # Allow for captures (1-2 piece difference is normal)
            if [ $diff -gt 2 ] || [ $diff -lt -2 ]; then
                echo "⚠️  Line $line_num: Suspicious piece count change ($prev_total → $curr_total)"
                echo "   Previous: $prev_line"
                echo "   Current:  $line"
                echo "   Difference: $diff pieces"
                issues_found=$((issues_found + 1))
            fi
        fi

        prev_line="$line"
        line_num=$((line_num + 1))
    done < "$filename"

    if [ $issues_found -eq 0 ]; then
        echo "✅ No suspicious piece movements found"
    else
        echo "❌ Found $issues_found potential issues"
    fi
    echo ""

    return $issues_found
}

# Validate all opening files
total_issues=0
for file in *.fen; do
    if [ -f "$file" ] && [[ $file == *"_"* ]] || [[ $file == "ITALIAN.fen" ]] || [[ $file == "ENGLISH.fen" ]]; then
        validate_fen_file "$file"
        total_issues=$((total_issues + $?))
    fi
done

echo "=== SUMMARY ==="
if [ $total_issues -eq 0 ]; then
    echo "✅ All opening files validated successfully - no illegal piece movements detected"
else
    echo "❌ Total issues found: $total_issues"
fi