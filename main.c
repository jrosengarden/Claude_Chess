/**
 * MAIN.C - Chess Game User Interface and Game Loop
 * 
 * This file implements the main user interface for the chess game including:
 * - Game loop and turn management
 * - User input handling and command processing
 * - Screen management and display formatting
 * - Integration between chess engine and Stockfish AI
 * - Interactive commands (help, hint, undo, fen, setup, score, skill, etc.)
 * 
 * Features:
 * - Clean single-board UI with screen clearing
 * - Interactive command system with pause/continue prompts
 * - Human vs AI gameplay (White vs Stockfish)
 * - Move validation and possible move display
 * - Unlimited undo functionality using FEN log restoration
 * - AI difficulty control with skill level adjustment (0-20)
 * - Real-time position evaluation and visual scoring
 * - Custom board setup via FEN notation
 * - Automatic FEN logging and PGN generation
 * - Debug mode for development
 */

#define _GNU_SOURCE  // Enable GNU/Linux extensions like strdup
#include "chess.h"
#include "stockfish.h"
#include <time.h>
#include <unistd.h>  // For getpid() and unlink()
#include <sys/types.h>  // For process ID types
#include <dirent.h>  // For directory scanning
#include <termios.h>  // For terminal control (arrow keys)
#include <sys/stat.h>  // For file statistics

// Global debug flag for diagnostic output
bool debug_mode = false;

// Global FEN log filename for current game session
char fen_log_filename[256];

// Global flag to track if gameplay has started (prevents skill level changes)
bool game_started = false;

// Global skill level tracking (default 20 = full strength)
int current_skill_level = 20;

// Configuration structure for chess game settings
typedef struct {
    char fen_directory[512];    // Path to directory containing FEN files
    int default_skill_level;    // Default AI skill level (0-20)
} ChessConfig;

// Global configuration instance
ChessConfig config = {0};

// Configuration override tracking for debug messages
bool fen_directory_overridden = false;
bool skill_level_overridden = false;

/**
 * Generate timestamp-based FEN filename for current game session
 * Creates filename in format: CHESS_mmddyy_HHMMSS.fen
 * This allows multiple game sessions to maintain separate FEN logs
 */
void generate_fen_filename() {
    time_t now = time(NULL);
    struct tm *local = localtime(&now);
    
    snprintf(fen_log_filename, sizeof(fen_log_filename), 
             "CHESS_%02d%02d%02d_%02d%02d%02d.fen",
             local->tm_mon + 1,    // Month (1-12)
             local->tm_mday,       // Day (1-31)
             local->tm_year % 100, // Year (2-digit)
             local->tm_hour,       // Hour (0-23)
             local->tm_min,        // Minute (0-59)
             local->tm_sec);       // Second (0-59)
}

/**
 * Save current board position to FEN log file
 * Appends current board state to the session's FEN log file.
 * Called after every half-move to create complete game history.
 * 
 * @param game Current game state to save as FEN
 */
void save_fen_log(ChessGame *game) {
    char *fen = board_to_fen(game);
    FILE *fen_file = fopen(fen_log_filename, "a");
    if (fen_file) {
        fprintf(fen_file, "%s\n", fen);
        fclose(fen_file);
    }
    // Note: FEN logging is always enabled - no debug messages needed
}

// Forward declarations
void create_default_config();
void expand_path(const char* input_path, char* expanded_path, size_t max_len);
bool is_valid_directory(const char* path);

/**
 * Check if a directory path exists and is accessible
 * @param path The directory path to validate
 * @return true if directory exists and is accessible, false otherwise
 */
bool is_valid_directory(const char* path) {
    struct stat statbuf;

    // Check if path exists and is a directory
    if (stat(path, &statbuf) == 0) {
        if (S_ISDIR(statbuf.st_mode)) {
            // Try to open the directory to check access permissions
            DIR *dir = opendir(path);
            if (dir) {
                closedir(dir);
                return true;
            }
        }
    }
    return false;
}

/**
 * Load configuration from CHESS.ini file
 * Parses the configuration file and sets up global config structure.
 * Creates default configuration file if it doesn't exist.
 */
void load_config() {
    FILE *config_file = fopen("CHESS.ini", "r");

    // Initialize default values
    strcpy(config.fen_directory, ".");  // Default to current directory
    config.default_skill_level = 5;     // Default skill level

    if (!config_file) {
        // Create default config file if it doesn't exist
        create_default_config();
        return;
    }

    char line[512];
    char section[64] = "";

    while (fgets(line, sizeof(line), config_file)) {
        // Remove trailing newline
        line[strcspn(line, "\n")] = '\0';

        // Skip empty lines and comments
        if (line[0] == '\0' || line[0] == '#' || line[0] == ';') {
            continue;
        }

        // Check for section header
        if (line[0] == '[') {
            char *end = strchr(line, ']');
            if (end) {
                *end = '\0';
                strcpy(section, line + 1);
            }
            continue;
        }

        // Parse key=value pairs
        char *equals = strchr(line, '=');
        if (equals) {
            *equals = '\0';
            char *key = line;
            char *value = equals + 1;

            // Trim whitespace from key and value
            while (*key == ' ' || *key == '\t') key++;
            while (*value == ' ' || *value == '\t') value++;

            // Process configuration values
            if (strcmp(section, "Paths") == 0) {
                if (strcmp(key, "FENDirectory") == 0) {
                    // Expand path (handle tilde, etc.)
                    char temp_path[512];
                    expand_path(value, temp_path, sizeof(temp_path));

                    // Validate that the directory exists and is accessible
                    if (is_valid_directory(temp_path)) {
                        strcpy(config.fen_directory, temp_path);
                    } else {
                        // Invalid directory - fallback to default and mark for debug message
                        strcpy(config.fen_directory, ".");
                        fen_directory_overridden = true;
                    }
                }
            } else if (strcmp(section, "Settings") == 0) {
                if (strcmp(key, "DefaultSkillLevel") == 0) {
                    int skill = atoi(value);
                    // Validate skill level range (0-20)
                    if (skill >= 0 && skill <= 20) {
                        config.default_skill_level = skill;
                    } else {
                        // Invalid skill level - use default and mark for debug message
                        config.default_skill_level = 5;
                        skill_level_overridden = true;
                    }
                }
            }
        }
    }

    fclose(config_file);

}

/**
 * Create default CHESS.ini configuration file
 * Called when no configuration file exists.
 */
void create_default_config() {
    FILE *config_file = fopen("CHESS.ini", "w");
    if (!config_file) {
        return;  // Silently fail and use defaults
    }

    fprintf(config_file, "# Chess Game Configuration File\n");
    fprintf(config_file, "# Modify these settings to customize your chess experience\n");
    fprintf(config_file, "\n");
    fprintf(config_file, "[Paths]\n");
    fprintf(config_file, "# Directory containing FEN files for the LOAD command\n");
    fprintf(config_file, "# Use . for current directory, or specify full path\n");
    fprintf(config_file, "# Examples: \n");
    fprintf(config_file, "#   FENDirectory=.\n");
    fprintf(config_file, "#   FENDirectory=/home/user/chess/games\n");
    fprintf(config_file, "#   FENDirectory=C:\\Users\\User\\Chess\\Games\n");
    fprintf(config_file, "FENDirectory=.\n");
    fprintf(config_file, "\n");
    fprintf(config_file, "[Settings]\n");
    fprintf(config_file, "# Default AI skill level (0=easiest, 20=strongest)\n");
    fprintf(config_file, "# Can be overridden with 'skill N' command before first move\n");
    fprintf(config_file, "DefaultSkillLevel=5\n");
    fprintf(config_file, "\n");
    fprintf(config_file, "# Future settings can be added here\n");
    fprintf(config_file, "# AutoSavePGN=true\n");

    fclose(config_file);
}

/**
 * Expand path with tilde (~) and environment variables
 * Handles tilde expansion to home directory and provides better error reporting
 */
void expand_path(const char* input_path, char* expanded_path, size_t max_len) {
    if (input_path[0] == '~') {
        // Expand tilde to home directory
        const char* home = getenv("HOME");
        if (home) {
            if (input_path[1] == '/' || input_path[1] == '\0') {
                // ~/path or just ~
                snprintf(expanded_path, max_len, "%s%s", home, input_path + 1);
            } else {
                // ~username/path (not supported, use as-is)
                strncpy(expanded_path, input_path, max_len - 1);
                expanded_path[max_len - 1] = '\0';
            }
        } else {
            // No HOME environment variable, use as-is
            strncpy(expanded_path, input_path, max_len - 1);
            expanded_path[max_len - 1] = '\0';
        }
    } else {
        // No tilde, use path as-is
        strncpy(expanded_path, input_path, max_len - 1);
        expanded_path[max_len - 1] = '\0';
    }
}

/**
 * Reset FEN logging for SETUP command
 * Deletes the current FEN log file and creates a new timestamped file.
 * Then logs the new starting position from the SETUP command.
 * 
 * @param game Current game state to save as new starting position
 */
void reset_fen_log_for_setup(ChessGame *game) {
    // Delete the current FEN log file
    remove(fen_log_filename);
    
    // Generate a new FEN log filename for the setup position
    generate_fen_filename();
    
    // Log the new starting position 
    save_fen_log(game);
}

/**
 * Remove last two moves from FEN log file for undo functionality
 * When undo is executed, both White's move and AI's response are reverted,
 * so we need to remove the last 2 FEN entries to keep the file synchronized.
 */
/**
 * Count available undo moves from FEN log file
 * Returns number of move pairs that can be undone (each pair = White + AI move)
 */
int count_available_undos() {
    FILE *file = fopen(fen_log_filename, "r");
    if (!file) return 0;
    
    int line_count = 0;
    char buffer[256];
    
    while (fgets(buffer, sizeof(buffer), file)) {
        line_count++;
    }
    fclose(file);
    
    // Each move pair requires 2 FEN entries, but we need at least 1 entry to remain (starting position)
    return (line_count > 2) ? (line_count - 1) / 2 : 0;
}

/**
 * Truncate FEN log file by specified number of move pairs
 * Each move pair removes 2 FEN entries (White move + AI response)
 */
void truncate_fen_log_by_moves(int move_pairs_to_undo) {
    FILE *file = fopen(fen_log_filename, "r");
    if (!file) return;
    
    // Read all lines into memory
    char lines[1000][256];  // Support up to 1000 moves (500 move pairs)
    int line_count = 0;
    
    while (fgets(lines[line_count], sizeof(lines[line_count]), file) && line_count < 1000) {
        // Remove newline character for easier handling
        lines[line_count][strcspn(lines[line_count], "\n")] = '\0';
        line_count++;
    }
    fclose(file);
    
    // Remove 2 lines per move pair to undo
    int lines_to_remove = move_pairs_to_undo * 2;
    if (line_count > lines_to_remove) {
        line_count -= lines_to_remove;
        
        // Rewrite the file with the truncated content
        file = fopen(fen_log_filename, "w");
        if (file) {
            for (int i = 0; i < line_count; i++) {
                fprintf(file, "%s\n", lines[i]);
            }
            fclose(file);
        }
    }
}

/**
 * Restore game state from last FEN entry in log file
 * Reads the FEN file and uses the last entry to restore game state
 */
bool restore_from_fen_log(ChessGame *game) {
    FILE *file = fopen(fen_log_filename, "r");
    if (!file) return false;
    
    char last_fen[256] = "";
    char buffer[256];
    
    // Read all lines to find the last one
    while (fgets(buffer, sizeof(buffer), file)) {
        strcpy(last_fen, buffer);
    }
    fclose(file);
    
    // Remove newline character
    last_fen[strcspn(last_fen, "\n")] = '\0';
    
    if (strlen(last_fen) == 0) return false;
    
    // Restore game state from FEN
    return setup_board_from_fen(game, last_fen);
}

/**
 * Check if FEN file contains only the standard chess starting position
 * Returns true if file has only 1 line with the starting position
 */
bool is_starting_position_only_fen_file(const char* filename) {
    FILE* file = fopen(filename, "r");
    if (!file) return false;

    char line[1000];
    int line_count = 0;
    bool is_starting_position = false;

    // Standard chess starting position FEN
    const char* starting_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

    while (fgets(line, sizeof(line), file)) {
        line_count++;
        line[strcspn(line, "\n")] = '\0';  // Remove newline

        if (line_count == 1) {
            // Check if first line is starting position
            is_starting_position = (strcmp(line, starting_fen) == 0);
        }

        // If more than 1 line, it's not starting-position-only
        if (line_count > 1) {
            fclose(file);
            return false;
        }
    }

    fclose(file);

    // Return true only if exactly 1 line and it's the starting position
    return (line_count == 1 && is_starting_position);
}

/**
 * Convert current session's FEN file to PGN format automatically
 * Creates a PGN file with the same base name as the FEN file.
 * This function performs the conversion silently without user prompts.
 * Skips conversion and removes files if only starting position exists.
 */
void convert_fen_to_pgn() {
    // Check if FEN file contains only the starting position
    if (is_starting_position_only_fen_file(fen_log_filename)) {
        // Remove the FEN file - no point keeping starting position only
        if (unlink(fen_log_filename) == 0) {
            printf("Removed empty game file (starting position only): %s\n", fen_log_filename);
        }
        // Don't create PGN file - no meaningful game to record
        return;
    }

    // Create PGN filename from FEN filename
    char pgn_filename[256];
    char* base_name = strdup(fen_log_filename);

    // Remove .fen extension if present
    char* dot = strrchr(base_name, '.');
    if (dot) *dot = '\0';

    snprintf(pgn_filename, sizeof(pgn_filename), "%s.pgn", base_name);
    free(base_name);

    // Open FEN file for reading
    FILE* fen_file = fopen(fen_log_filename, "r");
    if (!fen_file) {
        // FEN file doesn't exist or can't be opened, exit silently
        return;
    }

    // Use system call to run fen_to_pgn utility with input redirection
    // This avoids duplicating the complex conversion logic
    char command[512];
    snprintf(command, sizeof(command), "echo '%s' | ./fen_to_pgn > /dev/null 2>&1", fen_log_filename);
    system(command);

    fclose(fen_file);
}

/**
 * Display the generated game files to inform the user
 * Shows both the FEN log file and the converted PGN file names
 * Handles case where files may have been removed due to starting position only
 */
void show_game_files() {
    // Check if files were removed due to starting position only
    if (access(fen_log_filename, F_OK) != 0) {
        printf("\nNo game files created (game never progressed beyond starting position).\n");
        return;
    }

    // Create PGN filename from FEN filename
    char pgn_filename[256];
    char* base_name = strdup(fen_log_filename);

    // Remove .fen extension if present
    char* dot = strrchr(base_name, '.');
    if (dot) *dot = '\0';

    snprintf(pgn_filename, sizeof(pgn_filename), "%s.pgn", base_name);
    free(base_name);

    printf("\nGame files created:\n");
    printf("  FEN log: %s\n", fen_log_filename);
    printf("  PGN file: %s\n", pgn_filename);
}

/**
 * Detect available terminal application for opening new windows
 * Returns command string for opening a new terminal window, or NULL if none available
 * Supports cross-platform detection for macOS and Linux environments
 *
 * @return Command string for terminal application, or NULL if unavailable
 */
char* detect_terminal_command() {
    // Check for macOS Terminal (always available on macOS)
    if (system("which osascript > /dev/null 2>&1") == 0) {
        return "osascript";  // macOS AppleScript for Terminal control
    }

    // Check for common Linux terminal applications
    if (system("which gnome-terminal > /dev/null 2>&1") == 0) {
        return "gnome-terminal";
    }
    if (system("which konsole > /dev/null 2>&1") == 0) {
        return "konsole";  // KDE terminal
    }
    if (system("which xterm > /dev/null 2>&1") == 0) {
        return "xterm";  // Basic X11 terminal
    }
    if (system("which mate-terminal > /dev/null 2>&1") == 0) {
        return "mate-terminal";  // MATE desktop
    }
    if (system("which xfce4-terminal > /dev/null 2>&1") == 0) {
        return "xfce4-terminal";  // Xfce desktop
    }

    return NULL;  // No suitable terminal found
}

/**
 * Display PGN content in a new terminal window
 * Creates a separate terminal window showing the PGN notation while keeping
 * the chess board visible in the original window. Falls back to full-screen
 * display if new window creation fails.
 *
 * @param pgn_content The PGN string to display
 * @return true if new window was created successfully, false if fallback used
 */
bool display_pgn_in_new_window(const char* pgn_content) {
    char* terminal_cmd = detect_terminal_command();

    if (!terminal_cmd) {
        return false;  // No suitable terminal found, use fallback
    }

    // Create temporary file with PGN content
    char temp_filename[256];
    snprintf(temp_filename, sizeof(temp_filename), "/tmp/chess_pgn_%d.txt", getpid());

    FILE* temp_file = fopen(temp_filename, "w");
    if (!temp_file) {
        return false;  // Could not create temp file, use fallback
    }

    fprintf(temp_file, "%s", pgn_content);
    fprintf(temp_file, "\n\nPress Enter or close this window to continue playing...\n");
    fclose(temp_file);

    // Build command based on detected terminal
    char command[1024];

    if (strcmp(terminal_cmd, "osascript") == 0) {
        // macOS Terminal using AppleScript
        snprintf(command, sizeof(command),
            "osascript -e 'tell application \"Terminal\" to do script \"clear; cat %s; echo \\\"\\nPress Enter to close...\\\"; read; rm %s; exit\"' > /dev/null 2>&1 &",
            temp_filename, temp_filename);
    } else if (strcmp(terminal_cmd, "gnome-terminal") == 0) {
        // GNOME Terminal
        snprintf(command, sizeof(command),
            "gnome-terminal --title=\"Chess Game - PGN Notation\" -- bash -c 'clear; cat %s; echo; echo \"Press Enter to close...\"; read; rm %s' > /dev/null 2>&1 &",
            temp_filename, temp_filename);
    } else if (strcmp(terminal_cmd, "konsole") == 0) {
        // KDE Konsole
        snprintf(command, sizeof(command),
            "konsole --title \"Chess Game - PGN Notation\" -e bash -c 'clear; cat %s; echo; echo \"Press Enter to close...\"; read; rm %s' > /dev/null 2>&1 &",
            temp_filename, temp_filename);
    } else if (strcmp(terminal_cmd, "mate-terminal") == 0) {
        // MATE Terminal
        snprintf(command, sizeof(command),
            "mate-terminal --title=\"Chess Game - PGN Notation\" -e 'bash -c \"clear; cat %s; echo; echo \\\"Press Enter to close...\\\"; read; rm %s\"' > /dev/null 2>&1 &",
            temp_filename, temp_filename);
    } else if (strcmp(terminal_cmd, "xfce4-terminal") == 0) {
        // Xfce Terminal
        snprintf(command, sizeof(command),
            "xfce4-terminal --title=\"Chess Game - PGN Notation\" -e 'bash -c \"clear; cat %s; echo; echo \\\"Press Enter to close...\\\"; read; rm %s\"' > /dev/null 2>&1 &",
            temp_filename, temp_filename);
    } else {
        // Basic xterm fallback
        snprintf(command, sizeof(command),
            "xterm -title \"Chess Game - PGN Notation\" -e bash -c 'clear; cat %s; echo; echo \"Press Enter to close...\"; read; rm %s' > /dev/null 2>&1 &",
            temp_filename, temp_filename);
    }

    // Execute the command
    int result = system(command);

    if (result == 0) {
        printf("\nPGN notation opened in new terminal window.\n");
        printf("You can view both the chess board and PGN notation simultaneously.\n");
        return true;
    } else {
        // Clean up temp file if command failed
        unlink(temp_filename);
        return false;
    }
}

/**
 * Clear the terminal screen using ANSI escape codes
 * Used throughout the UI to maintain clean single-board display
 */
void clear_screen() {
    printf("\033[2J\033[H");  // Clear screen and move cursor to top-left
    fflush(stdout);           // Ensure immediate display
}

/**
 * Structure to hold FEN log game information for selection
 */
typedef struct {
    char filename[256];
    char display_name[300];  // Larger buffer to accommodate filename + formatting
    int move_count;
    time_t timestamp;
    bool from_current_dir;  // true if from current directory, false if from FENDirectory
} FENGameInfo;

/**
 * Structure to hold loaded FEN positions for navigation
 */
typedef struct {
    char **positions;     // Array of FEN strings
    int count;           // Number of positions
    int current;         // Current position index
} FENNavigator;

/**
 * Enable raw terminal mode for arrow key detection
 * Returns old terminal settings for restoration
 */
struct termios enable_raw_mode() {
    struct termios old_termios, new_termios;

    // Get current terminal settings
    tcgetattr(STDIN_FILENO, &old_termios);
    new_termios = old_termios;

    // Disable canonical mode and echo
    new_termios.c_lflag &= ~(ICANON | ECHO);

    // Set new terminal settings
    tcsetattr(STDIN_FILENO, TCSANOW, &new_termios);

    return old_termios;
}

/**
 * Restore original terminal mode
 */
void restore_terminal_mode(struct termios old_termios) {
    tcsetattr(STDIN_FILENO, TCSANOW, &old_termios);
}

/**
 * Get single key input including arrow keys
 * Returns special codes for arrow keys:
 * 1000 = Up, 1001 = Down, 1002 = Right, 1003 = Left
 * 27 = ESC, 10 = Enter, other = regular character
 */
int get_key() {
    int ch = getchar();

    if (ch == 27) {  // ESC sequence
        ch = getchar();
        if (ch == '[') {
            ch = getchar();
            switch (ch) {
                case 'A': return 1000;  // Up arrow
                case 'B': return 1001;  // Down arrow
                case 'C': return 1002;  // Right arrow
                case 'D': return 1003;  // Left arrow
            }
        }
        return 27;  // ESC key
    }
    return ch;
}

/**
 * Helper function to scan a single directory for .fen files
 * @param directory_path Path to the directory to scan
 * @param games Pointer to array of FENGameInfo structures
 * @param count Current count of games in the array
 * @param capacity Current capacity of the games array
 * @param is_current_dir true if scanning current directory, false for FENDirectory
 * @return new count of games, or -1 on error
 */
int scan_single_directory(const char* directory_path, FENGameInfo **games, int count, int *capacity, bool is_current_dir) {
    DIR *dir;
    struct dirent *entry;
    struct stat file_stat;

    dir = opendir(directory_path);
    if (!dir) {
        return count;  // Silently skip inaccessible directories
    }

    while ((entry = readdir(dir)) != NULL) {
        // Check if file has .fen extension
        char *fen_ext = strstr(entry->d_name, ".fen");
        if (fen_ext != NULL && strcmp(fen_ext, ".fen") == 0) {

            if (count >= *capacity) {
                *capacity *= 2;
                *games = realloc(*games, (*capacity) * sizeof(FENGameInfo));
                if (!*games) {
                    closedir(dir);
                    return -1;
                }
            }

            // Build full path for file operations
            char full_path[768];
            if (strcmp(directory_path, ".") == 0) {
                strcpy(full_path, entry->d_name);
            } else {
                snprintf(full_path, sizeof(full_path), "%s/%s", directory_path, entry->d_name);
            }

            // Check for duplicate filenames (same basename from different directories)
            bool is_duplicate = false;
            for (int i = 0; i < count; i++) {
                // Extract basename from existing filename
                char *existing_basename = strrchr((*games)[i].filename, '/');
                existing_basename = existing_basename ? existing_basename + 1 : (*games)[i].filename;

                if (strcmp(existing_basename, entry->d_name) == 0) {
                    is_duplicate = true;
                    break;
                }
            }

            // Skip duplicates (current directory takes precedence)
            if (is_duplicate && !is_current_dir) {
                continue;
            }

            // Store full path in filename field
            strcpy((*games)[count].filename, full_path);
            (*games)[count].from_current_dir = is_current_dir;

            // Get file timestamp
            if (stat(full_path, &file_stat) == 0) {
                (*games)[count].timestamp = file_stat.st_mtime;
            } else {
                (*games)[count].timestamp = 0;
            }

            // Count moves in file
            FILE *file = fopen(full_path, "r");
            if (file) {
                int moves = 0;
                char line[512];
                while (fgets(line, sizeof(line), file)) {
                    moves++;
                }
                fclose(file);
                (*games)[count].move_count = moves;
            } else {
                (*games)[count].move_count = 0;
            }

            // Create display name
            if (strncmp(entry->d_name, "CHESS_", 6) == 0) {
                // Format CHESS_mmddyy_HHMMSS.fen as readable date/time
                char date_str[20];
                char time_str[20];

                if (sscanf(entry->d_name, "CHESS_%6s_%6s.fen", date_str, time_str) == 2) {
                    snprintf((*games)[count].display_name, sizeof((*games)[count].display_name),
                             "%.2s/%.2s/%.2s %.2s:%.2s:%.2s - %d moves",
                             date_str, date_str + 2, date_str + 4,
                             time_str, time_str + 2, time_str + 4,
                             (*games)[count].move_count);
                    count++;
                    continue;
                }
            }
            
            // Use filename as-is (for non-CHESS files or malformed CHESS_ files)
            snprintf((*games)[count].display_name, sizeof((*games)[count].display_name),
                     "%s - %d moves", entry->d_name, (*games)[count].move_count);

            count++;
        }
    }

    closedir(dir);
    return count;
}

/**
 * Scan both current directory and FENDirectory for all .fen files and return sorted list
 */
int scan_fen_files(FENGameInfo **games) {
    int count = 0;
    int capacity = 10;

    *games = malloc(capacity * sizeof(FENGameInfo));
    if (!*games) return 0;

    // First, scan current directory (takes precedence for duplicates)
    count = scan_single_directory(".", games, count, &capacity, true);
    if (count == -1) {
        free(*games);
        return -1;
    }

    // Then, scan FENDirectory if it's different from current directory
    if (strcmp(config.fen_directory, ".") != 0) {
        count = scan_single_directory(config.fen_directory, games, count, &capacity, false);
        if (count == -1) {
            free(*games);
            return -1;
        }
    }

    // Return error if no directories could be accessed
    if (count == 0) {
        // Check if we can access current directory
        if (!is_valid_directory(".")) {
            free(*games);
            return -1;
        }
        // Current directory accessible but no files found - this is ok
    }

    // Sort by timestamp (newest first)
    for (int i = 0; i < count - 1; i++) {
        for (int j = i + 1; j < count; j++) {
            if ((*games)[i].timestamp < (*games)[j].timestamp) {
                FENGameInfo temp = (*games)[i];
                (*games)[i] = (*games)[j];
                (*games)[j] = temp;
            }
        }
    }

    return count;
}

/**
 * Load all FEN positions from a file into navigator
 */
int load_fen_positions(const char *filename, FENNavigator *nav) {
    FILE *file = fopen(filename, "r");
    if (!file) return 0;

    // Count lines first
    int count = 0;
    char line[1000];
    while (fgets(line, sizeof(line), file)) {
        if (strlen(line) > 10) count++;  // Skip empty lines
    }

    if (count == 0) {
        fclose(file);
        return 0;
    }

    // Allocate memory
    nav->positions = malloc(count * sizeof(char*));
    if (!nav->positions) {
        fclose(file);
        return 0;
    }

    // Read positions
    rewind(file);
    nav->count = 0;
    nav->current = 0;

    while (fgets(line, sizeof(line), file) && nav->count < count) {
        line[strcspn(line, "\n")] = '\0';  // Remove newline
        if (strlen(line) > 10) {  // Valid FEN line
            nav->positions[nav->count] = malloc(strlen(line) + 1);
            if (nav->positions[nav->count]) {
                strcpy(nav->positions[nav->count], line);
                nav->count++;
            }
        }
    }

    fclose(file);
    return nav->count;
}

/**
 * Free FEN navigator memory
 */
void free_fen_navigator(FENNavigator *nav) {
    if (nav->positions) {
        for (int i = 0; i < nav->count; i++) {
            free(nav->positions[i]);
        }
        free(nav->positions);
    }
    nav->positions = NULL;
    nav->count = 0;
    nav->current = 0;
}

/**
 * Copy game history from loaded FEN positions up to selected position
 * This preserves the complete game history when resuming from a LOAD
 */
void copy_game_history_to_new_log(FENNavigator *nav, int up_to_position) {
    FILE *file = fopen(fen_log_filename, "w");
    if (!file) {
        printf("Warning: Could not create new FEN log file for game history.\n");
        return;
    }

    // Copy all positions from start up to and including the selected position
    for (int i = 0; i <= up_to_position; i++) {
        fprintf(file, "%s\n", nav->positions[i]);
    }

    fclose(file);

    printf("Copied %d position%s to new game log.\n",
           up_to_position + 1,
           up_to_position == 0 ? "" : "s");
}

/**
 * Interactive FEN navigation browser
 * Returns the index of selected position, or -1 if cancelled
 */
int interactive_fen_browser(ChessGame *game, FENNavigator *nav) {
    struct termios old_termios = enable_raw_mode();
    ChessGame temp_game = *game;  // Work with copy to preserve original

    while (1) {
        // Load current position
        if (!setup_board_from_fen(&temp_game, nav->positions[nav->current])) {
            printf("Error loading position %d\n", nav->current + 1);
            break;
        }

        clear_screen();

        // Display current board
        Position empty_moves[1];  // No highlighting
        print_board(&temp_game, empty_moves, 0);

        // Display navigation info
        printf("\n=== GAME BROWSER ===\n");
        printf("Position %d/%d", nav->current + 1, nav->count);

        // Show move number based on FEN fullmove counter
        if (nav->current < nav->count) {
            // Try to extract move number from FEN string
            char fen_copy[1000];
            strcpy(fen_copy, nav->positions[nav->current]);

            // FEN format: board active castling enpassant halfmove fullmove
            char *token = strtok(fen_copy, " ");
            for (int i = 0; i < 5 && token; i++) {
                token = strtok(NULL, " ");
            }
            if (token) {
                int move_num = atoi(token);
                if (move_num > 0) {
                    printf(" - Move %d", move_num);
                }
            }
        }

        printf("\n\n");
        printf("← → Navigate positions\n");
        printf("ENTER to resume game from the currently loaded position\n");
        printf("ESC ESC (twice) to cancel loading\n");
        printf("Current FEN: %.60s...\n", nav->positions[nav->current]);

        fflush(stdout);

        int key = get_key();

        switch (key) {
            case 1002:  // Right arrow - next position
                if (nav->current < nav->count - 1) {
                    nav->current++;
                }
                break;

            case 1003:  // Left arrow - previous position
                if (nav->current > 0) {
                    nav->current--;
                }
                break;

            case 10:    // Enter - select this position
            case 13:    // Carriage return
                restore_terminal_mode(old_termios);
                return nav->current;

            case 27:    // ESC - cancel
                restore_terminal_mode(old_termios);
                return -1;

            default:
                // Ignore other keys
                break;
        }
    }

    restore_terminal_mode(old_termios);
    return -1;
}

/**
 * Main LOAD command implementation
 * Allows user to select and interactively browse saved games
 */
void handle_load_command(ChessGame *game) {
    FENGameInfo *games = NULL;
    int game_count = scan_fen_files(&games);

    if (game_count == -1) {
        printf("\nError: Cannot access FEN directory '%s'\n", config.fen_directory);
        printf("Please check:\n");
        printf("1. The directory exists\n");
        printf("2. You have read permissions\n");
        printf("3. The path is correct in CHESS.ini\n");
        printf("\nCurrent configured path: %s\n", config.fen_directory);
        return;
    }

    if (game_count == 0) {
        printf("\nNo .fen files found in directory '%s'\n", config.fen_directory);
        printf("Play some games first to create FEN logs, or move your FEN files to this directory!\n");
        return;
    }

    // Display available games with pagination
    clear_screen();
    printf("=== LOAD SAVED GAME ===\n\n");

    int item_number = 1;
    int line_count = 3;  // Starting with title and blank lines
    bool has_current_dir_files = false;
    bool has_fen_dir_files = false;

    // Check what types of files we have
    for (int i = 0; i < game_count; i++) {
        if (games[i].from_current_dir) {
            has_current_dir_files = true;
        } else {
            has_fen_dir_files = true;
        }
    }

    // Display current directory files first
    if (has_current_dir_files) {
        printf("Chess Program Directory:\n");
        line_count++;

        for (int i = 0; i < game_count; i++) {
            if (games[i].from_current_dir) {
                // Check if we need to paginate
                if (line_count >= 20) {
                    printf("\nPress Enter to continue...");
                    getchar();
                    clear_screen();
                    printf("=== LOAD SAVED GAME ===\n\n");
                    printf("Chess Program Directory (continued):\n");
                    line_count = 4;  // Reset line count
                }

                printf("%d. %s\n", item_number++, games[i].display_name);
                line_count++;
            }
        }
    }

    // Add blank line and display FEN directory files
    if (has_fen_dir_files) {
        // Check if we need to paginate before the section header
        if (has_current_dir_files) {
            if (line_count >= 19) {  // Reserve space for blank line and header
                printf("\nPress Enter to continue...");
                getchar();
                clear_screen();
                printf("=== LOAD SAVED GAME ===\n\n");
                printf("FEN Files Directory:\n");
                line_count = 4;
            } else {
                printf("\n");  // Blank line between sections
                printf("FEN Files Directory:\n");
                line_count += 2;
            }
        } else {
            printf("FEN Files Directory:\n");
            line_count++;
        }

        for (int i = 0; i < game_count; i++) {
            if (!games[i].from_current_dir) {
                // Check if we need to paginate
                if (line_count >= 20) {
                    printf("\nPress Enter to continue...");
                    getchar();
                    clear_screen();
                    printf("=== LOAD SAVED GAME ===\n\n");
                    printf("FEN Files Directory (continued):\n");
                    line_count = 4;  // Reset line count
                }

                printf("%d. %s\n", item_number++, games[i].display_name);
                line_count++;
            }
        }
    }

    printf("\nSelect game to load (1-%d) or 0 to cancel: ", game_count);
    fflush(stdout);

    // Get user selection
    char input[10];
    if (!fgets(input, sizeof(input), stdin)) {
        free(games);
        return;
    }

    int selection = atoi(input);
    if (selection == 0) {
        printf("Load cancelled.\n");
        free(games);
        return;
    }

    if (selection < 1 || selection > game_count) {
        printf("Invalid selection. Load cancelled.\n");
        free(games);
        return;
    }

    // Load selected game
    selection--;  // Convert to 0-based index
    FENNavigator nav;

    printf("\nLoading game: %s\n", games[selection].display_name);

    if (!load_fen_positions(games[selection].filename, &nav)) {
        printf("Error loading game file. Load cancelled.\n");
        free(games);
        return;
    }

    printf("Game loaded successfully! Starting interactive browser...\n");
    printf("Use arrow keys to navigate positions.\n");
    printf("ENTER to resume game from selected position.\n");
    printf("ESC ESC (twice) to cancel loading.\n");
    printf("Press any key to continue...");
    getchar();

    // Start interactive browser
    int selected_position = interactive_fen_browser(game, &nav);

    if (selected_position >= 0) {
        // Load selected position into game
        if (setup_board_from_fen(game, nav.positions[selected_position])) {
            printf("\nPosition loaded successfully!\n");
            printf("Resuming game from position %d/%d\n", selected_position + 1, nav.count);

            // Create new FEN log for continued gameplay
            generate_fen_filename();
            printf("New game log: %s\n", fen_log_filename);

            // Copy complete game history up to selected position
            copy_game_history_to_new_log(&nav, selected_position);

            // Reset game started flag to allow new skill settings
            game_started = false;
        } else {
            printf("\nError loading selected position!\n");
        }
    } else {
        printf("\nLoad cancelled. Returning to current game.\n");
    }

    // Cleanup
    free_fen_navigator(&nav);
    free(games);

    printf("Press Enter to continue...");
    getchar();
}

/**
 * Convert centipawn evaluation to -9 to +9 scale
 * Stockfish returns evaluations in centipawns (hundredths of a pawn)
 * We map this to a visual scale from -9 (Black winning) to +9 (White winning)
 * 
 * @param centipawns Evaluation in centipawns from Stockfish
 * @return Evaluation on -9 to +9 scale
 */
int centipawns_to_scale(int centipawns) {
    // Typical centipawn ranges:
    // 0-50: roughly equal
    // 50-150: slight advantage
    // 150-300: moderate advantage  
    // 300-500: significant advantage
    // 500+: winning advantage
    
    if (centipawns <= -900) return -9;        // Black crushing
    else if (centipawns <= -500) return -8;   // Black winning big
    else if (centipawns <= -300) return -7;   // Black significant advantage
    else if (centipawns <= -200) return -6;   // Black moderate advantage
    else if (centipawns <= -100) return -5;   // Black small advantage
    else if (centipawns <= -50) return -4;    // Black slight advantage
    else if (centipawns <= -25) return -3;    // Black tiny advantage
    else if (centipawns <= -10) return -2;    // Black very slight edge
    else if (centipawns < 0) return -1;       // Black barely ahead
    else if (centipawns == 0) return 0;       // Perfectly equal
    else if (centipawns <= 10) return 1;      // White barely ahead
    else if (centipawns <= 25) return 2;      // White very slight edge
    else if (centipawns <= 50) return 3;      // White tiny advantage
    else if (centipawns <= 100) return 4;     // White slight advantage
    else if (centipawns <= 200) return 5;     // White small advantage
    else if (centipawns <= 300) return 6;     // White moderate advantage
    else if (centipawns <= 500) return 7;     // White significant advantage
    else if (centipawns <= 900) return 8;     // White winning big
    else return 9;                           // White crushing
}

/**
 * Display evaluation line showing game score from -9 (Black winning) to +9 (White winning)
 * 
 * @param evaluation Current game evaluation (-9 to +9, where 0 is even)
 */
void print_evaluation_line(int evaluation) {
    printf("\n");
    printf("Black winning -9       -6       -3         0        +3       +6       +9 White winning\n");
    printf("              ");
    
    // Draw the indicator line with position marker
    // Map evaluation (-9 to +9) to exact positions under the actual numbers
    // -9=1, -6=10, -3=19, 0=29, +3=39, +6=48, +9=56
    int position;
    if (evaluation == -9) position = 1;
    else if (evaluation == -6) position = 10;
    else if (evaluation == -3) position = 19;
    else if (evaluation == 0) position = 29;
    else if (evaluation == 3) position = 39;
    else if (evaluation == 6) position = 48;
    else if (evaluation == 9) position = 56;
    else position = (evaluation + 9) * 57 / 18;  // Approximate for other values
    
    // First line: tick marks and horizontal line
    for (int i = 0; i < 58; i++) {
        if (i == 29) {
            printf("┼");  // Center marker at 0 to match top line
        } else if (i == 10 || i == 19 || i == 39 || i == 48) {
            printf("│");  // Tick marks under the actual numbers 6, 3, 3, 6
        } else {
            printf("─");
        }
    }
    printf("\n");
    
    // Second line: caret indicator
    printf("              ");
    for (int i = 0; i < 58; i++) {
        if (i == position) {
            printf("^");
        } else {
            printf(" ");
        }
    }
    printf("\n");
}

/**
 * Display current game information including player turn and captured pieces
 * Shows game status header and captured piece summary for both players
 * 
 * @param game Current game state to display
 */
void print_game_info(ChessGame *game) {
    printf("\n=== CHESS GAME ===\n");
    printf("Current player: %s\n", game->current_player == WHITE ? "WHITE" : "BLACK");
    printf("Stockfish Skill Level: %d\n", current_skill_level);
    
    // Display captured pieces for both players
    printf("\n");
    print_captured_pieces(&game->black_captured, "\033[1;96m", "Black");
    print_captured_pieces(&game->white_captured, "\033[1;95m", "White");
}

/**
 * Display the score conversion chart showing centipawn ranges
 * Shows how Stockfish centipawn evaluations map to our -9 to +9 scale
 */
void print_scale_chart() {
    printf("\n=== SCORE CONVERSION CHART ===\n");
    printf("Stockfish Centipawns → Game Score Scale\n\n");
    
    printf("Black Advantage:\n");
    printf("  -900+ centipawns  →  -9  (Black crushing)\n");
    printf("  -500 to -900      →  -8  (Black winning big)\n");
    printf("  -300 to -500      →  -7  (Black significant advantage)\n");
    printf("  -200 to -300      →  -6  (Black moderate advantage)\n");
    printf("  -100 to -200      →  -5  (Black small advantage)\n");
    printf("   -50 to -100      →  -4  (Black slight advantage)\n");
    printf("   -25 to -50       →  -3  (Black tiny advantage)\n");
    printf("   -10 to -25       →  -2  (Black very slight edge)\n");
    printf("    -1 to -10       →  -1  (Black barely ahead)\n");
    
    printf("\nEven Game:\n");
    printf("     0 centipawns   →   0  (Perfectly equal)\n");
    
    printf("\nPress Enter to continue...");
    getchar();
    
    clear_screen();
    printf("\n=== SCORE CONVERSION CHART (continued) ===\n\n");
    printf("White Advantage:\n");
    printf("    +1 to +10       →  +1  (White barely ahead)\n");
    printf("   +10 to +25       →  +2  (White very slight edge)\n");
    printf("   +25 to +50       →  +3  (White tiny advantage)\n");
    printf("   +50 to +100      →  +4  (White slight advantage)\n");
    printf("  +100 to +200      →  +5  (White small advantage)\n");
    printf("  +200 to +300      →  +6  (White moderate advantage)\n");
    printf("  +300 to +500      →  +7  (White significant advantage)\n");
    printf("  +500 to +900      →  +8  (White winning big)\n");
    printf("  +900+ centipawns  →  +9  (White crushing)\n");
    
    printf("\nNote: 100 centipawns = 1 pawn advantage\n");
}

/**
 * Display help message with all available commands
 * Shows comprehensive list of user commands and their descriptions
 * Used by the help command and during game startup
 */
void print_help() {
    printf("\n=== COMMANDS ===\n");
    printf("Enter moves in format: e2 e4 (from to)\n");
    printf("Type 'help' for this help message\n");
    printf("Type 'hint' to get Stockfish's best move suggestion for White\n");
    printf("Type 'score' to display current game evaluation score\n");
    printf("Type 'scale' to view the score conversion chart (centipawns to -9/+9 scale)\n");
    printf("Type 'skill N' to set AI difficulty level (0=easiest, 20=strongest, only before first move)\n");
    printf("Type 'fen' to display current board position in FEN notation\n");
    printf("Type 'pgn' to display current game in PGN (Portable Game Notation) format\n");
    printf("Type 'title' to re-display the game title and info screen\n");
    printf("Type 'setup' to setup a custom board position from FEN string\n");
    printf("Type 'load' to interactively browse and load saved games (with arrow key navigation)\n");
    printf("Type 'undo' for unlimited undo (undo any number of move pairs)\n");
    printf("Type 'resign' to resign the game (with confirmation)\n");
    printf("Type 'quit' to exit the game\n");
    printf("Type a piece position to see its possible moves (marked with * or highlighted)\n");
    printf("* = empty square you can move to\n");
    printf("highlighted piece = piece you can capture\n\n");
}

bool has_legal_moves(ChessGame *game, Color color) {
    for (int row = 0; row < BOARD_SIZE; row++) {
        for (int col = 0; col < BOARD_SIZE; col++) {
            if (is_piece_at(game, row, col)) {
                Piece piece = get_piece_at(game, row, col);
                if (piece.color == color) {
                    Position moves[64];
                    Color original_player = game->current_player;
                    game->current_player = color;
                    
                    int move_count = get_possible_moves(game, (Position){row, col}, moves);
                    
                    for (int i = 0; i < move_count; i++) {
                        if (!would_be_in_check_after_move(game, (Position){row, col}, moves[i])) {
                            game->current_player = original_player;
                            return true;
                        }
                    }
                    
                    game->current_player = original_player;
                }
            }
        }
    }
    return false;
}

bool is_checkmate(ChessGame *game, Color color) {
    return is_in_check(game, color) && !has_legal_moves(game, color);
}

bool is_stalemate(ChessGame *game, Color color) {
    return !is_in_check(game, color) && !has_legal_moves(game, color);
}

/**
 * Handle human player's turn (White pieces)
 * Processes user input for moves and commands including:
 * - Standard chess moves (e.g., "e2 e4")
 * - Interactive commands (help, hint, fen, undo, title, quit)
 * - Piece position queries (e.g., "e2" to show possible moves)
 * 
 * @param game Current game state
 * @param engine Stockfish engine for hint generation
 */
void handle_white_turn(ChessGame *game, StockfishEngine *engine) {
    char input[100];
    printf("\nWhite's turn. Enter move (e.g., 'e2 e4') or 'help': ");
    
    if (!fgets(input, sizeof(input), stdin)) {
        return;
    }
    
    input[strcspn(input, "\n")] = '\0';
    
    // Skip empty input
    if (strlen(input) == 0) {
        return;
    }
    
    if (strcmp(input, "quit") == 0) {
        // Convert FEN log to PGN before exiting
        convert_fen_to_pgn();
        show_game_files();
        exit(0);
    }
    
    if (strcmp(input, "help") == 0) {
        clear_screen();
        print_help();
        printf("Press Enter to continue...");
        getchar();
        return;
    }
    
    if (strcmp(input, "hint") == 0) {
        printf("\nGetting hint from Stockfish...");
        fflush(stdout);
        
        char hint_move[10];
        if (get_best_move(engine, game, hint_move)) {
            if (debug_mode) {
                printf("\nDebug: Stockfish returned hint: '%s'\n", hint_move);
            }
            Move suggested_move = parse_move_string(hint_move);
            if (debug_mode) {
                printf("Debug: Parsed hint from (%d,%d) to (%d,%d)\n", 
                       suggested_move.from.row, suggested_move.from.col, 
                       suggested_move.to.row, suggested_move.to.col);
            }
            char from_str[4], to_str[4];
            strcpy(from_str, position_to_string(suggested_move.from));
            strcpy(to_str, position_to_string(suggested_move.to));
            printf("\nStockfish suggests: %s to %s\n", from_str, to_str);
        } else {
            printf("\nSorry, couldn't get a hint from Stockfish.\n");
        }
        
        printf("Press Enter to continue...");
        getchar();
        return;
    }
    
    if (strcmp(input, "scale") == 0 || strcmp(input, "SCALE") == 0) {
        clear_screen();
        print_scale_chart();
        printf("\nPress Enter to continue...");
        getchar();
        return;
    }
    
    if (strncmp(input, "skill ", 6) == 0 || strncmp(input, "SKILL ", 6) == 0) {
        if (game_started) {
            printf("\nSkill level cannot be changed after the game has started!\n");
            printf("Use this command only before making your first move.\n");
        } else {
            char *level_str = input + 6;  // Skip "skill "
            int skill_level = atoi(level_str);
            
            if (skill_level >= 0 && skill_level <= 20) {
                if (set_skill_level(engine, skill_level)) {
                    current_skill_level = skill_level;  // Update global tracking
                    printf("\nStockfish skill level set to %d (0=easiest, 20=strongest)\n", skill_level);
                } else {
                    printf("\nFailed to set skill level. Make sure Stockfish is ready.\n");
                }
            } else {
                printf("\nInvalid skill level. Please enter a number from 0 to 20.\n");
                printf("0 = easiest, 20 = strongest (default)\n");
            }
        }
        printf("Press Enter to continue...");
        getchar();
        return;
    }
    
    if (strcmp(input, "fen") == 0 || strcmp(input, "FEN") == 0) {
        char *fen = board_to_fen(game);
        printf("\nCurrent FEN: %s\n", fen);
        printf("Press Enter to continue...");
        getchar();
        return;
    }

    if (strcmp(input, "pgn") == 0 || strcmp(input, "PGN") == 0) {
        printf("\nGenerating current game PGN notation...");
        fflush(stdout);

        char* pgn_content = convert_fen_to_pgn_string(fen_log_filename);
        if (pgn_content) {
            // Try to display in new terminal window first
            if (display_pgn_in_new_window(pgn_content)) {
                // Success - new window opened
                // Chess board remains visible, automatically return when PGN window closes
                printf("Close the PGN window when you're done viewing.\n");
            } else {
                // Fallback to full-screen display (original method)
                printf("\nCould not open new window, displaying full-screen instead.\n");
                clear_screen();
                printf("Current Game in PGN Format:\n");
                printf("==================================================\n");
                printf("%s\n", pgn_content);
                printf("==================================================\n");
                printf("\nPress Enter to continue...");
                getchar();
            }
            free(pgn_content);
        } else {
            printf("\nError: Could not generate PGN notation from current game.\n");
            printf("Press Enter to continue...");
            getchar();
        }
        return;
    }
    
    if (strcmp(input, "score") == 0 || strcmp(input, "SCORE") == 0) {
        printf("\nGetting evaluation from Stockfish...");
        fflush(stdout);
        
        int centipawn_score;
        if (get_position_evaluation(engine, game, &centipawn_score)) {
            int scale_score = centipawns_to_scale(centipawn_score);
            printf("\nCurrent Game Evaluation (Stockfish depth 15):\n");
            if (debug_mode) {
                printf("DEBUG: Raw centipawn score: %+d\n", centipawn_score);
            }
            print_evaluation_line(scale_score);
        } else {
            printf("\nSorry, couldn't get evaluation from Stockfish.\n");
            printf("Showing neutral position:\n");
            print_evaluation_line(0);
        }
        printf("Press Enter to continue...");
        getchar();
        return;
    }
    
    if (strcmp(input, "title") == 0 || strcmp(input, "TITLE") == 0) {
        clear_screen();
        
        printf("=== Chess Game with Stockfish AI ===\n");
        printf("You play as White, AI plays as Black\n");
        printf("Stockfish engine is running successfully!\n");
        
        if (debug_mode) {
            printf("*** DEBUG MODE ENABLED ***\n");
        }
        
        printf("\nPress Enter to continue...");
        getchar();
        return;
    }

    if (strcmp(input, "load") == 0 || strcmp(input, "LOAD") == 0) {
        handle_load_command(game);
        return;
    }

    if (strcmp(input, "undo") == 0 || strcmp(input, "UNDO") == 0) {
        int available_undos = count_available_undos();
        
        if (available_undos > 0) {
            // Ask how many move pairs to undo for unlimited undo
            if (available_undos > 1) {
                printf("\nYou can undo up to %d move pairs. How many would you like to undo? (1-%d): ", 
                       available_undos, available_undos);
                fflush(stdout);
                
                char undo_input[10];
                if (fgets(undo_input, sizeof(undo_input), stdin)) {
                    int undo_count = atoi(undo_input);
                    if (undo_count >= 1 && undo_count <= available_undos) {
                        truncate_fen_log_by_moves(undo_count);
                        if (restore_from_fen_log(game)) {
                            printf("\n%d move pair%s undone! Restored to previous position.\n", 
                                   undo_count, undo_count > 1 ? "s" : "");
                        } else {
                            printf("\nError restoring game state from FEN log.\n");
                        }
                    } else {
                        printf("\nInvalid undo count. Must be between 1 and %d.\n", available_undos);
                    }
                } else {
                    printf("\nFailed to read undo count.\n");
                }
            } else {
                // Single undo available
                truncate_fen_log_by_moves(1);
                if (restore_from_fen_log(game)) {
                    printf("\nMove pair undone! Restored to previous position.\n");
                } else {
                    printf("\nError restoring game state from FEN log.\n");
                }
            }
        } else {
            printf("\nNo moves to undo!\n");
        }
        printf("Press Enter to continue...");
        getchar();
        return;
    }
    
    if (strcmp(input, "resign") == 0 || strcmp(input, "RESIGN") == 0) {
        printf("\nYou are indicating that you are resigning the game. Are you sure?\n");
        printf("Type 'YES' to resign or 'NO' to cancel: ");
        fflush(stdout);
        
        char confirmation[10];
        if (!fgets(confirmation, sizeof(confirmation), stdin)) {
            printf("Failed to read confirmation.\n");
            printf("Press Enter to continue...");
            getchar();
            return;
        }
        
        // Remove newline character
        confirmation[strcspn(confirmation, "\n")] = '\0';
        
        if (strcmp(confirmation, "YES") == 0 || strcmp(confirmation, "yes") == 0) {
            printf("\n*** WHITE RESIGNS! BLACK WINS! ***\n");
            printf("Game ended by resignation.\n");
            
            // Convert FEN log to PGN before exiting
            convert_fen_to_pgn();
            show_game_files();
            
            printf("Press Enter to exit...");
            getchar();
            exit(0);
        } else {
            printf("\nResignation cancelled. Game continues.\n");
            printf("Press Enter to continue...");
            getchar();
            return;
        }
    }
    
    if (strcmp(input, "setup") == 0 || strcmp(input, "SETUP") == 0) {
        char fen_input[256];
        printf("\nEnter FEN string for board setup: ");
        fflush(stdout);
        
        if (!fgets(fen_input, sizeof(fen_input), stdin)) {
            printf("Failed to read FEN string.\n");
            printf("Press Enter to continue...");
            getchar();
            return;
        }
        
        // Remove newline character
        fen_input[strcspn(fen_input, "\n")] = '\0';
        
        // Validate and setup board from FEN
        if (setup_board_from_fen(game, fen_input)) {
            printf("\nBoard setup successful from FEN: %s\n", fen_input);
            
            // Reset FEN logging with new position
            reset_fen_log_for_setup(game);
            printf("New FEN log file created: %s\n", fen_log_filename);
            
            printf("\nGame will continue from this custom position.\n");
        } else {
            printf("\nInvalid FEN string! Board setup failed.\n");
            printf("Please check FEN format and try again.\n");
        }
        
        printf("Press Enter to continue...");
        getchar();
        return;
    }
    
    if (strlen(input) == 2) {
        Position from = char_to_position(input);
        if (is_valid_position(from.row, from.col) && is_piece_at(game, from.row, from.col)) {
            Piece piece = get_piece_at(game, from.row, from.col);
            if (piece.color == WHITE) {
                Position possible_moves[64];
                int move_count = 0;
                
                Position all_moves[64];
                int all_count = get_possible_moves(game, from, all_moves);
                
                for (int i = 0; i < all_count; i++) {
                    if (!would_be_in_check_after_move(game, from, all_moves[i])) {
                        possible_moves[move_count++] = all_moves[i];
                    }
                }
                
                clear_screen();
                printf("\n=== CHESS GAME ===\n");
                printf("Current player: %s\n", game->current_player == WHITE ? "WHITE" : "BLACK");
                
                printf("\n");
                print_captured_pieces(&game->black_captured, "\033[1;96m", "Black");
                print_captured_pieces(&game->white_captured, "\033[1;95m", "White");
                
                if (game->in_check[WHITE]) {
                    printf("\nYour king is in check! You can only make moves that get out of check.\n");
                }
                
                print_board(game, possible_moves, move_count);
                
                if (move_count > 0) {
                    printf("\nPossible moves from %s:\n", position_to_string(from));
                    for (int i = 0; i < move_count; i++) {
                        printf("%s ", position_to_string(possible_moves[i]));
                    }
                    printf("\n");
                } else {
                    printf("\nNo legal moves available from %s\n", position_to_string(from));
                }
                
                printf("Press Enter to continue...");
                getchar();
                return;
            }
        }
        printf("Invalid position or no piece at %s\n", input);
        return;
    }
    
    char from_str[3], to_str[3];
    if (sscanf(input, "%2s %2s", from_str, to_str) != 2) {
        printf("Invalid input format. Use: e2 e4\n");
        return;
    }
    
    Position from = char_to_position(from_str);
    Position to = char_to_position(to_str);
    
    if (!is_valid_position(from.row, from.col) || !is_valid_position(to.row, to.col)) {
        printf("Invalid positions\n");
        return;
    }
    
    
    if (make_move(game, from, to)) {
        game_started = true;  // Mark game as started after first move
        printf("Move made: %s to %s\n", from_str, to_str);
        save_fen_log(game);  // Save FEN after White's move
        printf("Press Enter to continue...");
        getchar();
        clear_screen();
    } else {
        printf("Invalid move\n");
    }
}

void handle_black_turn(ChessGame *game, StockfishEngine *engine) {
    printf("\nBlack's turn (AI thinking...)");
    fflush(stdout);
    
    char move_str[10];
    if (get_best_move(engine, game, move_str)) {
        if (debug_mode) {
            printf("\nDebug: Stockfish returned move: '%s'\n", move_str);
        }
        Move ai_move = parse_move_string(move_str);
        if (debug_mode) {
            printf("Debug: Parsed from (%d,%d) to (%d,%d)\n", 
                   ai_move.from.row, ai_move.from.col, ai_move.to.row, ai_move.to.col);
        }
        
        if (is_valid_position(ai_move.from.row, ai_move.from.col) && 
            is_valid_position(ai_move.to.row, ai_move.to.col)) {
            
            // Store the positions before making the move for display
            Position from_pos = ai_move.from;
            Position to_pos = ai_move.to;
            
            if (make_move(game, ai_move.from, ai_move.to)) {
                char from_str[4], to_str[4];
                strcpy(from_str, position_to_string(from_pos));
                strcpy(to_str, position_to_string(to_pos));
                printf("\nAI played: %s to %s\n", from_str, to_str);
                save_fen_log(game);  // Save FEN after AI's move
                printf("Press Enter to continue...");
                getchar();
                clear_screen();
            } else {
                printf("\nAI suggested invalid move, skipping turn\n");
                game->current_player = WHITE;
            }
        } else {
            printf("\nInvalid AI move format, skipping turn\n");
            game->current_player = WHITE;
        }
    } else {
        printf("\nAI couldn't find a move, skipping turn\n");
        game->current_player = WHITE;
    }
}

/**
 * Main entry point for chess game
 * Initializes the game, sets up Stockfish AI, and runs the main game loop
 * handling alternating turns between human (White) and AI (Black) players.
 * 
 * Command line arguments:
 * - "DEBUG" - Enable diagnostic output mode
 * 
 * @param argc Number of command line arguments
 * @param argv Array of command line argument strings
 * @return 0 on successful completion, 1 on initialization failure
 */
int main(int argc, char *argv[]) {
    ChessGame game;
    StockfishEngine engine = {0};
    
    // Check for DEBUG command line argument
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "DEBUG") == 0) {
            debug_mode = true;
            break;
        }
    }
    
    // Generate FEN log filename for this game session
    generate_fen_filename();

    // Load configuration settings from CHESS.ini
    load_config();

    // Clear screen at startup
    clear_screen();
    
    printf("=== Chess Game with Stockfish AI ===\n");
    printf("You play as White, AI plays as Black\n");
    if (debug_mode) {
        printf("*** DEBUG MODE ENABLED ***\n");
    }
    printf("Initializing Stockfish engine...\n");
    
    if (!init_stockfish(&engine)) {
        printf("Failed to initialize Stockfish engine!\n");
        printf("Make sure Stockfish is installed and in your PATH.\n");
        printf("You can install it with: brew install stockfish (macOS) or apt install stockfish (Ubuntu)\n");
        return 1;
    }

    // Apply default skill level from configuration
    if (set_skill_level(&engine, config.default_skill_level)) {
        current_skill_level = config.default_skill_level;
    }
    
    // Get and display Stockfish version
    char version_str[256];
    if (get_stockfish_version(&engine, version_str, sizeof(version_str))) {
        clear_screen();
        printf("=== Chess Game with %s AI ===\n", version_str);
        printf("You play as White, AI plays as Black\n");
        if (debug_mode) {
            printf("*** DEBUG MODE ENABLED ***\n");
            printf("Configuration loaded: FENDirectory='%s'\n", config.fen_directory);
            printf("Configuration loaded: DefaultSkillLevel=%d\n", config.default_skill_level);

            // Show any configuration overrides
            if (fen_directory_overridden) {
                printf("WARNING: Invalid FENDirectory in CHESS.ini - using default '.'\n");
            }
            if (skill_level_overridden) {
                printf("WARNING: Invalid DefaultSkillLevel in CHESS.ini - using default 5\n");
            }
        }
        printf("Stockfish initialized successfully!\n");
    } else {
        if (debug_mode) {
            printf("*** DEBUG MODE ENABLED ***\n");
            printf("Configuration loaded: FENDirectory='%s'\n", config.fen_directory);
            printf("Configuration loaded: DefaultSkillLevel=%d\n", config.default_skill_level);

            // Show any configuration overrides
            if (fen_directory_overridden) {
                printf("WARNING: Invalid FENDirectory in CHESS.ini - using default '.'\n");
            }
            if (skill_level_overridden) {
                printf("WARNING: Invalid DefaultSkillLevel in CHESS.ini - using default 5\n");
            }
        }
        printf("Stockfish initialized successfully!\n");
    }
    
    printf("\nPress Enter to continue...");
    getchar();
    
    clear_screen();
    print_help();
    
    init_board(&game);
    
    // Log initial board position to FEN file
    save_fen_log(&game);
    
    while (true) {
        clear_screen();
        print_game_info(&game);
        
        // Check for game ending conditions
        if (is_checkmate(&game, game.current_player)) {
            print_board(&game, NULL, 0);
            Color winner = (game.current_player == WHITE) ? BLACK : WHITE;
            printf("\n*** CHECKMATE! %s WINS! ***\n", winner == WHITE ? "WHITE" : "BLACK");
            convert_fen_to_pgn();  // Convert FEN log to PGN before exiting
            show_game_files();
            printf("Press Enter to exit...");
            getchar();
            break;
        }
        
        if (is_stalemate(&game, game.current_player)) {
            print_board(&game, NULL, 0);
            printf("\n*** STALEMATE! IT'S A DRAW! ***\n");
            convert_fen_to_pgn();  // Convert FEN log to PGN before exiting
            show_game_files();
            printf("Press Enter to exit...");
            getchar();
            break;
        }
        
        if (is_fifty_move_rule_draw(&game)) {
            print_board(&game, NULL, 0);
            printf("\n*** 50-MOVE RULE DRAW! ***\n");
            printf("50 moves have passed without a pawn move or capture.\n");
            convert_fen_to_pgn();  // Convert FEN log to PGN before exiting
            show_game_files();
            printf("Press Enter to exit...");
            getchar();
            break;
        }
        
        print_board(&game, NULL, 0);
        
        if (game.current_player == WHITE) {
            handle_white_turn(&game, &engine);
        } else {
            handle_black_turn(&game, &engine);
        }
    }
    
    close_stockfish(&engine);
    printf("Thanks for playing!\n");
    
    return 0;
}