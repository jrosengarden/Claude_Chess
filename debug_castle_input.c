#include "chess.h"
#include <stdio.h>
#include <string.h>

int main() {
    printf("Testing castling input parsing:\n");
    
    // Test the exact input sequences from the test script
    char test_inputs[][10] = {"e2 e4", "g1 f3", "f1 c4", "e1 g1"};
    
    for (int i = 0; i < 4; i++) {
        printf("\nTesting input: '%s'\n", test_inputs[i]);
        
        char from_str[3], to_str[3];
        int result = sscanf(test_inputs[i], "%2s %2s", from_str, to_str);
        printf("sscanf result: %d\n", result);
        printf("from_str: '%s', to_str: '%s'\n", from_str, to_str);
        
        if (result == 2) {
            Position from = char_to_position(from_str);
            Position to = char_to_position(to_str);
            
            printf("from position: row=%d, col=%d\n", from.row, from.col);
            printf("to position: row=%d, col=%d\n", to.row, to.col);
            
            bool from_valid = is_valid_position(from.row, from.col);
            bool to_valid = is_valid_position(to.row, to.col);
            
            printf("from valid: %s\n", from_valid ? "true" : "false");
            printf("to valid: %s\n", to_valid ? "true" : "false");
        }
    }
    
    return 0;
}