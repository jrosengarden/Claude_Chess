#include <stdio.h>
#include <string.h>
#include "chess.h"

void test_move_parsing(const char* move_str) {
    printf("\n=== Testing move: '%s' ===\n", move_str);
    
    char input[100];
    strcpy(input, move_str);
    
    char from_str[3], to_str[3];
    int sscanf_result = sscanf(input, "%2s %2s", from_str, to_str);
    printf("sscanf result: %d\n", sscanf_result);
    
    if (sscanf_result != 2) {
        printf("sscanf failed\n");
        return;
    }
    
    printf("from_str: '%s', to_str: '%s'\n", from_str, to_str);
    
    Position from = char_to_position(from_str);
    Position to = char_to_position(to_str);
    
    printf("from position: row=%d, col=%d\n", from.row, from.col);
    printf("to position: row=%d, col=%d\n", to.row, to.col);
    
    bool from_valid = is_valid_position(from.row, from.col);
    bool to_valid = is_valid_position(to.row, to.col);
    
    printf("from valid: %s\n", from_valid ? "true" : "false");
    printf("to valid: %s\n", to_valid ? "true" : "false");
    
    if (!from_valid || !to_valid) {
        printf("ERROR: Invalid positions detected!\n");
    } else {
        printf("SUCCESS: Positions are valid\n");
    }
}

int main() {
    printf("Testing move parsing logic:\n");
    
    test_move_parsing("e2 e4");
    test_move_parsing("g1 f3");
    test_move_parsing("f1 c4");
    test_move_parsing("e1 g1");  // castling
    
    return 0;
}