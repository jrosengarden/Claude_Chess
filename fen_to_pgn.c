#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>

#define MAX_LINE_LENGTH 256
#define MAX_MOVES 1000
#define BOARD_SIZE 8

// Chess piece representation
typedef enum {
    EMPTY = 0,
    PAWN = 1, KNIGHT = 2, BISHOP = 3, ROOK = 4, QUEEN = 5, KING = 6
} PieceType;

typedef enum {
    WHITE = 0, BLACK = 1
} Color;

typedef struct {
    PieceType type;
    Color color;
} Piece;

typedef struct {
    int from_row, from_col, to_row, to_col;
    PieceType piece_type;
    Color piece_color;
    PieceType captured_piece;
    int is_castle;
    int is_en_passant;
    PieceType promotion_piece;
    int is_check;
    int is_checkmate;
} Move;

// Global board representation
Piece board[BOARD_SIZE][BOARD_SIZE];
Move moves[MAX_MOVES];
int move_count = 0;

// Function prototypes
void parse_fen(const char* fen, Piece board[BOARD_SIZE][BOARD_SIZE], Color* to_move, 
               char* castling, char* en_passant, int* halfmove, int* fullmove);
void copy_board(Piece src[BOARD_SIZE][BOARD_SIZE], Piece dst[BOARD_SIZE][BOARD_SIZE]);
int compare_boards(Piece board1[BOARD_SIZE][BOARD_SIZE], Piece board2[BOARD_SIZE][BOARD_SIZE], Move* move);
char piece_to_char(PieceType type, Color color);
PieceType char_to_piece_type(char c);
Color char_to_color(char c);
void detect_special_moves(Piece old_board[BOARD_SIZE][BOARD_SIZE], 
                         Piece new_board[BOARD_SIZE][BOARD_SIZE], Move* move);
char* move_to_algebraic(Move* move, Piece board[BOARD_SIZE][BOARD_SIZE]);
void write_pgn(const char* filename, Move moves[], int move_count, const char* first_fen);
char* get_base_filename(const char* filepath);

int main() {
    char input_filename[256];
    char output_filename[256];
    char line[MAX_LINE_LENGTH];
    FILE* input_file;
    
    // Get input filename from user
    printf("Enter FEN file name: ");
    if (fgets(input_filename, sizeof(input_filename), stdin) == NULL) {
        fprintf(stderr, "Error reading filename\n");
        return 1;
    }
    
    // Remove newline from filename
    input_filename[strcspn(input_filename, "\n")] = 0;
    
    // Open input file
    input_file = fopen(input_filename, "r");
    if (!input_file) {
        fprintf(stderr, "Error: Cannot open file '%s'\n", input_filename);
        return 1;
    }
    
    // Create output filename
    char* base_name = get_base_filename(input_filename);
    snprintf(output_filename, sizeof(output_filename), "%s.pgn", base_name);
    free(base_name);
    
    // Initialize board arrays
    Piece prev_board[BOARD_SIZE][BOARD_SIZE];
    Piece curr_board[BOARD_SIZE][BOARD_SIZE];
    Color to_move = WHITE;
    char castling[5], en_passant[3];
    int halfmove, fullmove;
    
    printf("Converting FEN positions to PGN moves...\n");

    // Read first FEN position as the starting position
    int first_position = 1;
    char first_fen[MAX_LINE_LENGTH] = {0};

    // Read FEN positions line by line
    while (fgets(line, sizeof(line), input_file)) {
        // Remove newline and whitespace
        line[strcspn(line, "\n")] = 0;
        if (strlen(line) == 0) continue;

        // Parse current FEN position
        parse_fen(line, curr_board, &to_move, castling, en_passant, &halfmove, &fullmove);

        if (first_position) {
            // Save the first FEN string for PGN headers
            strncpy(first_fen, line, sizeof(first_fen) - 1);
            // First position becomes our starting point - no move to analyze yet
            copy_board(curr_board, prev_board);
            first_position = 0;
            continue;
        }
        
        // Compare with previous position to find the move
        Move move = {0};
        if (compare_boards(prev_board, curr_board, &move)) {
            // Detect special moves (castling, en passant, etc.)
            detect_special_moves(prev_board, curr_board, &move);
            
            // Store the move
            moves[move_count] = move;
            move_count++;
            
            if (move_count >= MAX_MOVES) {
                fprintf(stderr, "Warning: Maximum moves exceeded\n");
                break;
            }
        }
        
        // Copy current board to previous for next iteration
        copy_board(curr_board, prev_board);
    }
    
    fclose(input_file);

    // Write PGN file
    write_pgn(output_filename, moves, move_count, first_fen);

    printf("Conversion complete! Output written to: %s\n", output_filename);
    printf("Converted %d moves\n", move_count);
    
    return 0;
}

void parse_fen(const char* fen, Piece board[BOARD_SIZE][BOARD_SIZE], Color* to_move, 
               char* castling, char* en_passant, int* halfmove, int* fullmove) {
    // Initialize empty board
    for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
            board[i][j].type = EMPTY;
            board[i][j].color = WHITE;
        }
    }
    
    // Parse board position
    int row = 0, col = 0;
    const char* ptr = fen;
    
    while (*ptr && *ptr != ' ') {
        if (*ptr == '/') {
            row++;
            col = 0;
        } else if (isdigit(*ptr)) {
            col += (*ptr - '0');
        } else {
            board[row][col].type = char_to_piece_type(tolower(*ptr));
            board[row][col].color = isupper(*ptr) ? WHITE : BLACK;
            col++;
        }
        ptr++;
    }
    
    // Parse remaining FEN fields
    if (*ptr == ' ') ptr++; // Skip space
    *to_move = (*ptr == 'w') ? WHITE : BLACK;
    
    ptr += 2; // Skip to castling rights
    int i = 0;
    while (*ptr && *ptr != ' ' && i < 4) {
        castling[i++] = *ptr++;
    }
    castling[i] = '\0';
    
    if (*ptr == ' ') ptr++; // Skip space
    i = 0;
    while (*ptr && *ptr != ' ' && i < 2) {
        en_passant[i++] = *ptr++;
    }
    en_passant[i] = '\0';
    
    // Parse halfmove and fullmove clocks
    if (*ptr == ' ') {
        *halfmove = atoi(++ptr);
        while (*ptr && *ptr != ' ') ptr++;
        if (*ptr == ' ') {
            *fullmove = atoi(++ptr);
        }
    }
}

void copy_board(Piece src[BOARD_SIZE][BOARD_SIZE], Piece dst[BOARD_SIZE][BOARD_SIZE]) {
    for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
            dst[i][j] = src[i][j];
        }
    }
}

int compare_boards(Piece board1[BOARD_SIZE][BOARD_SIZE], Piece board2[BOARD_SIZE][BOARD_SIZE], Move* move) {
    // First check for castling - special case where king and rook both move
    for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
            // Look for a king that disappeared
            if (board1[i][j].type == KING && board2[i][j].type != KING) {
                // Check if this could be castling by looking for the king in the new position
                for (int ni = 0; ni < BOARD_SIZE; ni++) {
                    for (int nj = 0; nj < BOARD_SIZE; nj++) {
                        if (board2[ni][nj].type == KING && 
                            board2[ni][nj].color == board1[i][j].color &&
                            board1[ni][nj].type != KING &&
                            ni == i && abs(nj - j) == 2) { // Same rank, 2 squares away
                            
                            move->from_row = i;
                            move->from_col = j;
                            move->to_row = ni;
                            move->to_col = nj;
                            move->piece_type = KING;
                            move->piece_color = board1[i][j].color;
                            move->is_castle = 1;
                            return 1;
                        }
                    }
                }
            }
        }
    }
    
    // Find normal moves (non-castling) - improved logic to handle captures correctly
    // First, find all pieces that disappeared and appeared
    typedef struct {
        int row, col;
        PieceType type;
        Color color;
    } PieceChange;
    
    PieceChange disappeared[64], appeared[64];
    int disappeared_count = 0, appeared_count = 0;
    
    // Find all pieces that disappeared from board1
    for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
            if (board1[i][j].type != EMPTY && 
                (board2[i][j].type != board1[i][j].type ||
                 board2[i][j].color != board1[i][j].color)) {
                disappeared[disappeared_count].row = i;
                disappeared[disappeared_count].col = j;
                disappeared[disappeared_count].type = board1[i][j].type;
                disappeared[disappeared_count].color = board1[i][j].color;
                disappeared_count++;
            }
        }
    }
    
    // Find all pieces that appeared on board2
    for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
            if (board2[i][j].type != EMPTY && 
                (board1[i][j].type != board2[i][j].type ||
                 board1[i][j].color != board2[i][j].color)) {
                appeared[appeared_count].row = i;
                appeared[appeared_count].col = j;
                appeared[appeared_count].type = board2[i][j].type;
                appeared[appeared_count].color = board2[i][j].color;
                appeared_count++;
            }
        }
    }
    
    // Match disappeared and appeared pieces to find the actual move
    // Priority: look for piece that disappeared and reappeared elsewhere
    for (int d = 0; d < disappeared_count; d++) {
        for (int a = 0; a < appeared_count; a++) {
            if (disappeared[d].type == appeared[a].type && 
                disappeared[d].color == appeared[a].color) {
                // Found a piece that moved
                move->from_row = disappeared[d].row;
                move->from_col = disappeared[d].col;
                move->to_row = appeared[a].row;
                move->to_col = appeared[a].col;
                move->piece_type = disappeared[d].type;
                move->piece_color = disappeared[d].color;
                
                // Check if this was a capture (something was on the destination)
                if (board1[appeared[a].row][appeared[a].col].type != EMPTY) {
                    move->captured_piece = board1[appeared[a].row][appeared[a].col].type;
                }
                
                return 1;
            }
        }
    }
    
    return 0;
}

void detect_special_moves(Piece old_board[BOARD_SIZE][BOARD_SIZE], 
                         Piece new_board[BOARD_SIZE][BOARD_SIZE], Move* move) {
    // Castling is now detected in compare_boards function
    
    // Detect en passant (pawn moves diagonally to empty square)
    if (move->piece_type == PAWN && 
        move->from_col != move->to_col && 
        old_board[move->to_row][move->to_col].type == EMPTY) {
        move->is_en_passant = 1;
    }
    
    // Detect promotion (pawn reaches end rank and piece type changes)
    if (move->piece_type == PAWN && 
        ((move->piece_color == WHITE && move->to_row == 0) ||
         (move->piece_color == BLACK && move->to_row == 7)) &&
        new_board[move->to_row][move->to_col].type != PAWN) {
        move->promotion_piece = new_board[move->to_row][move->to_col].type;
    }
}

PieceType char_to_piece_type(char c) {
    switch (c) {
        case 'p': return PAWN;
        case 'n': return KNIGHT;
        case 'b': return BISHOP;
        case 'r': return ROOK;
        case 'q': return QUEEN;
        case 'k': return KING;
        default: return EMPTY;
    }
}

Color char_to_color(char c) {
    return isupper(c) ? WHITE : BLACK;
}

char piece_to_char(PieceType type, Color color) {
    char pieces[] = " PNBRQK";
    char c = pieces[type];
    return (color == WHITE) ? toupper(c) : tolower(c);
}

char* move_to_algebraic(Move* move, Piece board[BOARD_SIZE][BOARD_SIZE] __attribute__((unused))) {
    static char algebraic[10];
    
    if (move->is_castle) {
        if (move->to_col > move->from_col) {
            strcpy(algebraic, "O-O");
        } else {
            strcpy(algebraic, "O-O-O");
        }
        return algebraic;
    }
    
    char piece_symbol = ' ';
    if (move->piece_type != PAWN) {
        char symbols[] = " PNBRQK";
        piece_symbol = symbols[move->piece_type];
    }
    
    char from_file = 'a' + move->from_col;
    char to_file = 'a' + move->to_col;
    char to_rank = '8' - move->to_row;
    
    if (move->piece_type == PAWN) {
        if (move->captured_piece != EMPTY || move->is_en_passant) {
            // Pawn capture
            if (move->promotion_piece != EMPTY) {
                char promo_symbols[] = " PNBRQK";
                snprintf(algebraic, sizeof(algebraic), "%cx%c%c=%c", 
                        from_file, to_file, to_rank, promo_symbols[move->promotion_piece]);
            } else {
                snprintf(algebraic, sizeof(algebraic), "%cx%c%c", 
                        from_file, to_file, to_rank);
            }
        } else {
            // Pawn move
            if (move->promotion_piece != EMPTY) {
                char promo_symbols[] = " PNBRQK";
                snprintf(algebraic, sizeof(algebraic), "%c%c=%c", 
                        to_file, to_rank, promo_symbols[move->promotion_piece]);
            } else {
                snprintf(algebraic, sizeof(algebraic), "%c%c", to_file, to_rank);
            }
        }
    } else {
        // Piece move
        if (move->captured_piece != EMPTY) {
            snprintf(algebraic, sizeof(algebraic), "%cx%c%c", 
                    piece_symbol, to_file, to_rank);
        } else {
            snprintf(algebraic, sizeof(algebraic), "%c%c%c", 
                    piece_symbol, to_file, to_rank);
        }
    }
    
    // Add check/checkmate notation if needed
    if (move->is_checkmate) {
        strcat(algebraic, "#");
    } else if (move->is_check) {
        strcat(algebraic, "+");
    }
    
    return algebraic;
}

void write_pgn(const char* filename, Move moves[], int move_count, const char* first_fen) {
    FILE* output_file = fopen(filename, "w");
    if (!output_file) {
        fprintf(stderr, "Error: Cannot create output file '%s'\n", filename);
        return;
    }

    // Write PGN headers
    time_t now = time(0);
    struct tm* timeinfo = localtime(&now);
    char date_str[20];
    strftime(date_str, sizeof(date_str), "%Y.%m.%d", timeinfo);

    fprintf(output_file, "[Event \"Converted Game\"]\n");
    fprintf(output_file, "[Site \"?\"]\n");
    fprintf(output_file, "[Date \"%s\"]\n", date_str);
    fprintf(output_file, "[Round \"?\"]\n");
    fprintf(output_file, "[White \"Player\"]\n");
    fprintf(output_file, "[Black \"AI\"]\n");
    fprintf(output_file, "[Result \"*\"]\n");

    // Check if starting position is non-standard and add FEN headers if needed
    // Standard starting position FEN (piece placement only):
    // rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR
    const char* standard_position = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR";

    if (first_fen && first_fen[0] != '\0') {
        // Extract just the piece placement part (before first space)
        char fen_pieces[MAX_LINE_LENGTH] = {0};
        const char* space_pos = strchr(first_fen, ' ');
        if (space_pos) {
            size_t len = space_pos - first_fen;
            if (len < sizeof(fen_pieces)) {
                strncpy(fen_pieces, first_fen, len);
                fen_pieces[len] = '\0';
            }
        } else {
            strncpy(fen_pieces, first_fen, sizeof(fen_pieces) - 1);
        }

        // Compare with standard position (case-insensitive)
        int is_standard = (strcasecmp(fen_pieces, standard_position) == 0);

        if (!is_standard) {
            // Add PGN standard FEN headers for custom starting position
            fprintf(output_file, "[SetUp \"1\"]\n");
            fprintf(output_file, "[FEN \"%s\"]\n", first_fen);
        }
    }

    fprintf(output_file, "\n");
    
    // Write moves
    for (int i = 0; i < move_count; i++) {
        if (i % 2 == 0) {
            fprintf(output_file, "%d. ", (i / 2) + 1);
        }
        
        char* algebraic = move_to_algebraic(&moves[i], board);
        fprintf(output_file, "%s ", algebraic);
        
        if ((i + 1) % 6 == 0) {  // Line break every 6 moves for readability
            fprintf(output_file, "\n");
        }
    }
    
    fprintf(output_file, "*\n");
    fclose(output_file);
}

char* get_base_filename(const char* filepath) {
    // Find the last occurrence of '/' or '\'
    const char* base = strrchr(filepath, '/');
    if (!base) base = strrchr(filepath, '\\');
    if (base) base++; else base = filepath;
    
    // Copy and remove extension
    char* result = malloc(strlen(base) + 1);
    strcpy(result, base);
    
    char* dot = strrchr(result, '.');
    if (dot) *dot = '\0';
    
    return result;
}