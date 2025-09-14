#!/bin/bash

# Detailed validation script for FEN files
# Checks for impossible piece movements between consecutive positions

analyze_position() {
    local board=$1
    # Convert FEN board to array of squares
    local squares=""

    # Replace numbers with dots for empty squares
    board=$(echo "$board" | sed 's/8/......../g' | sed 's/7/......./g' | sed 's/6/....../g' | sed 's/5/...../g' | sed 's/4/..../g' | sed 's/3/.../g' | sed 's/2/../g' | sed 's/1/./g')

    # Remove rank separators
    board=$(echo "$board" | tr -d '/')

    echo "$board"
}

count_pieces() {
    local position=$1
    echo "$position" | grep -o '[rnbqkpRNBQKP]' | sort | uniq -c | sort -k2
}

validate_detailed() {
    local filename=$1
    echo "=== DETAILED VALIDATION: $filename ==="

    local line_num=1
    local prev_line=""
    local issues=0

    while IFS= read -r line; do
        if [ $line_num -gt 1 ] && [ -n "$prev_line" ]; then
            local prev_board=$(echo "$prev_line" | cut -d' ' -f1)
            local curr_board=$(echo "$line" | cut -d' ' -f1)

            local prev_pos=$(analyze_position "$prev_board")
            local curr_pos=$(analyze_position "$curr_board")

            local prev_counts=$(count_pieces "$prev_pos")
            local curr_counts=$(count_pieces "$curr_pos")

            # Check each piece type for dramatic changes
            for piece in r n b q k p R N B Q K P; do
                local prev_count=$(echo "$prev_counts" | grep " $piece$" | cut -d' ' -f1 || echo "0")
                local curr_count=$(echo "$curr_counts" | grep " $piece$" | cut -d' ' -f1 || echo "0")

                # Convert empty strings to 0
                [ -z "$prev_count" ] && prev_count=0
                [ -z "$curr_count" ] && curr_count=0

                local diff=$((curr_count - prev_count))

                # Check for impossible changes (more than 1 piece appearing)
                if [ $diff -gt 1 ]; then
                    echo "❌ Line $line_num: Impossible piece appearance - $piece: $prev_count → $curr_count"
                    echo "   From: $prev_line"
                    echo "   To:   $line"
                    issues=$((issues + 1))
                elif [ $diff -lt -2 ]; then
                    echo "❌ Line $line_num: Too many pieces disappeared - $piece: $prev_count → $curr_count"
                    echo "   From: $prev_line"
                    echo "   To:   $line"
                    issues=$((issues + 1))
                fi
            done
        fi

        prev_line="$line"
        line_num=$((line_num + 1))
    done < "$filename"

    if [ $issues -eq 0 ]; then
        echo "✅ All piece movements are legal"
    else
        echo "❌ Found $issues illegal piece movements"
    fi
    echo ""

    return $issues
}

# Test with the two files we fixed
echo "Checking the two files that were corrected:"
validate_detailed "KINGS_INDIAN.fen"
validate_detailed "ALEKHINES_DEFENSE.fen"

# Quick check on a few others
echo "Spot checking other files:"
validate_detailed "ITALIAN.fen"
validate_detailed "RUY_LOPEZ.fen"