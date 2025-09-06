#include <stdio.h>
#include <string.h>
#include "chess.h"

int main() {
    printf("Testing position conversion:\n");
    
    Position e2 = char_to_position("e2");
    printf("e2 -> row=%d, col=%d\n", e2.row, e2.col);
    printf("is_valid_position(e2): %s\n", is_valid_position(e2.row, e2.col) ? "true" : "false");
    
    Position e4 = char_to_position("e4");
    printf("e4 -> row=%d, col=%d\n", e4.row, e4.col);
    printf("is_valid_position(e4): %s\n", is_valid_position(e4.row, e4.col) ? "true" : "false");
    
    // Test sscanf parsing
    char input[] = "e2 e4";
    char from_str[3], to_str[3];
    int result = sscanf(input, "%2s %2s", from_str, to_str);
    printf("\nsscanf result: %d\n", result);
    printf("from_str: '%s'\n", from_str);
    printf("to_str: '%s'\n", to_str);
    printf("strlen(from_str): %zu\n", strlen(from_str));
    printf("strlen(to_str): %zu\n", strlen(to_str));
    
    return 0;
}