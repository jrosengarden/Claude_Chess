#include <stdio.h>
#include <string.h>

int main() {
    char input[100];
    printf("Testing fgets input processing:\n");
    
    // Simulate what happens in the actual code
    printf("Enter 'e2 e4': ");
    if (!fgets(input, sizeof(input), stdin)) {
        printf("fgets failed\n");
        return 1;
    }
    
    printf("Raw input: '%s'\n", input);
    printf("Length: %zu\n", strlen(input));
    
    // Remove newline (what the main code does)
    input[strcspn(input, "\n")] = '\0';
    printf("After newline removal: '%s'\n", input);
    printf("Length after: %zu\n", strlen(input));
    
    // Test sscanf
    char from_str[3], to_str[3];
    int result = sscanf(input, "%2s %2s", from_str, to_str);
    printf("sscanf result: %d\n", result);
    printf("from_str: '%s'\n", from_str);
    printf("to_str: '%s'\n", to_str);
    
    return 0;
}