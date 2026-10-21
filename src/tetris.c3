import std::io;
import libc;


const String EMPTY_STR = "";
const String BLOCK_STR = "\u2588";

const int TETRIS = 4;
const int NUM_TETROMINOS = 7;
const int NUM_ORIENTATIONS = 4;


const int MAX_LEVEL = 19;
const int LINES_PER_LEVEL = 10;

fn int type_to_cell(int x){
    return x + 1;
}

enum Tetris_type : int {
    TET_I,
    TET_J,
    TET_L,
    TET_O,
    TET_S,
    TET_T,
    TET_Z
}

struct Tetris_location {
    int row;
    int col;
}

enum Tetris_cell : char{
    TC_EMPTY,
    TC_CELLI,
    TC_CELLL,
    TC_CELLO,
    TC_CELLS,
    TC_CELLT,
    TC_CELLZ,
}

struct Tetris_block{
    int typ;
    int ori;
    Tetris_location loc;
}

enum Tetris_move : int {
    TM_LEFT,
    TM_RIGHT,
    TM_CLOCK,
    TM_COUNTER,
    TM_DROP,
    TM_HOLD,
    TM_NONE
}

struct Tetris_game {
    int rows;
    int cols;
    char *board;

    int points;
    int level;

    Tetris_block falling;
    Tetris_block next;
    Tetris_block stored;

    int ticks_till_gravity;
    
    int lines_remaining;
}

const Tetris_location[][][] TETROMINOS = {
      // I
  {{{1, 0}, {1, 1}, {1, 2}, {1, 3}},
   {{0, 2}, {1, 2}, {2, 2}, {3, 2}},
   {{3, 0}, {3, 1}, {3, 2}, {3, 3}},
   {{0, 1}, {1, 1}, {2, 1}, {3, 1}}},
  // J
  {{{0, 0}, {1, 0}, {1, 1}, {1, 2}},
   {{0, 1}, {0, 2}, {1, 1}, {2, 1}},
   {{1, 0}, {1, 1}, {1, 2}, {2, 2}},
   {{0, 1}, {1, 1}, {2, 0}, {2, 1}}},
  // L
  {{{0, 2}, {1, 0}, {1, 1}, {1, 2}},
   {{0, 1}, {1, 1}, {2, 1}, {2, 2}},
   {{1, 0}, {1, 1}, {1, 2}, {2, 0}},
   {{0, 0}, {0, 1}, {1, 1}, {2, 1}}},
  // O
  {{{0, 1}, {0, 2}, {1, 1}, {1, 2}},
   {{0, 1}, {0, 2}, {1, 1}, {1, 2}},
   {{0, 1}, {0, 2}, {1, 1}, {1, 2}},
   {{0, 1}, {0, 2}, {1, 1}, {1, 2}}},
  // S
  {{{0, 1}, {0, 2}, {1, 0}, {1, 1}},
   {{0, 1}, {1, 1}, {1, 2}, {2, 2}},
   {{1, 1}, {1, 2}, {2, 0}, {2, 1}},
   {{0, 0}, {1, 0}, {1, 1}, {2, 1}}},
  // T
  {{{0, 1}, {1, 0}, {1, 1}, {1, 2}},
   {{0, 1}, {1, 1}, {1, 2}, {2, 1}},
   {{1, 0}, {1, 1}, {1, 2}, {2, 1}},
   {{0, 1}, {1, 0}, {1, 1}, {2, 1}}},
  // Z
  {{{0, 0}, {0, 1}, {1, 1}, {1, 2}},
   {{0, 2}, {1, 1}, {1, 2}, {2, 1}},
   {{1, 0}, {1, 1}, {2, 1}, {2, 2}},
   {{0, 1}, {1, 0}, {1, 1}, {2, 0}}},
};

const int[] GRAVITY_LEVEL = {
  50, 48, 46, 44, 42, 40, 38, 36, 34, 32,
  30, 28, 26, 24, 22, 20, 16, 12,  8,  4
};

fn bool is_empty(char cell){
    return cell == (char)Tetris_cell.TC_EMPTY;
}

fn bool is_filled(char cell) {
    return !is_empty(cell);
}


fn char get(Tetris_game *obj, int row, int column) {
    return obj.board[obj.cols * row + column];
}

fn void set(Tetris_game *obj, int row, int column, char value){
    obj.board[obj.cols * row + column] = value;
}

fn bool check(Tetris_game *obj, int row, int col) {
    return 0 <= row && row < obj.rows && 0 <= col && col < obj.cols;
}

fn void put(Tetris_game *obj, Tetris_block block) {
    for (int i = 0; i < TETRIS; i++){
        Tetris_location cell = TETROMINOS[block.typ][block.ori][i];
        set(obj, block.loc.row + cell.row, block.loc.col + cell.col, (char)type_to_cell(block.typ));
    }
}

fn void remove(Tetris_game *obj, Tetris_block block){
    for (int i = 0; i < TETRIS; i++){
        Tetris_location cell = TETROMINOS[block.typ][block.ori][i];
        set(obj, block.loc.row + cell.row, block.loc.col + cell.col, (char)Tetris_cell.TC_EMPTY);
    }
}

fn bool fits(Tetris_game *obj, Tetris_block block){
    for (int i = 0; i < TETRIS; i++) {
    Tetris_location cell = TETROMINOS[block.typ][block.ori][i];
    int r = block.loc.row + cell.row;
    int c = block.loc.col + cell.col;
    if (!check(obj,r,c) || is_filled(get(obj,r,c))) {
        return false;
        }
    }
    return true;
}

fn int random_tetromino(){
    return libc::rand() % NUM_TETROMINOS;
}

fn void new_falling(Tetris_game *obj) {
    obj.falling = obj.next;
    obj.next.typ = random_tetromino();
    obj.next.ori = 0;
    obj.next.loc.row = 0;
    obj.next.loc.col = obj.cols / 2 - 2;
}

fn void do_gravity_tick(Tetris_game *obj) {
    obj.ticks_till_gravity--;
    if (obj.ticks_till_gravity <= 0) {
        remove(obj, obj.falling);
        obj.falling.loc.row++;
        if (fits(obj, obj.falling)) {
            obj.ticks_till_gravity = GRAVITY_LEVEL[obj.level];
        } else {
            obj.falling.loc.row--;
            put(obj, obj.falling);
            new_falling(obj);
        }
        put(obj, obj.falling);
    }
}

fn void move_piece(Tetris_game *obj, int direction) {
    remove(obj, obj.falling);
    obj.falling.loc.col += direction;
    if (!fits(obj, obj.falling)) {
        obj.falling.loc.col -= direction;
    }
    put(obj, obj.falling);
}

fn void down(Tetris_game *obj) {
    remove(obj, obj.falling);
    while (fits(obj, obj.falling)) {
        obj.falling.loc.row++;
    }
    obj.falling.loc.row--;
    put(obj, obj.falling);
    new_falling(obj);
}

fn void rotate(Tetris_game *obj, int direction) {
    remove(obj, obj.falling);
    while (true) {
        obj.falling.ori = (obj.falling.ori + direction) % NUM_ORIENTATIONS;
        if (fits(obj, obj.falling)) break;

        obj.falling.loc.col--;
        if (fits(obj, obj.falling)) break;

        obj.falling.loc.col += 2;
        if (fits(obj, obj.falling)) break;

        obj.falling.loc.col--;
        break; 
    }
    put(obj, obj.falling);
}

fn void handle_move(Tetris_game *obj, Tetris_move move) {
    switch (move) {
        case TM_LEFT: 
            move_piece(obj, -1);
            break;
        case TM_RIGHT: 
            move_piece(obj, 1);
            break;
        case TM_DROP: 
            down(obj);
            break;
        case TM_CLOCK: 
            rotate(obj, 1);
            break;
        case TM_COUNTER: 
            rotate(obj, -1);
            break;
        default: 
            break;
    }
}

fn bool line_full(Tetris_game *obj, int i) {
    for (int j = 0; j < obj.cols; j++) {
        if (is_empty(get(obj, i, j))) return false;
    }
    return true;
}

fn void shift_lines(Tetris_game *obj, int r) {
    for (int i = r - 1; i >= 0; i--) {
        for (int j = 0; j < obj.cols; j++) {
            set(obj, i + 1, j, get(obj, i, j));
            set(obj, i, j, (char)Tetris_cell.TC_EMPTY);
        }
    }
}

fn int check_lines(Tetris_game *obj) {
    int nlines = 0;
    remove(obj, obj.falling);
    for (int i = obj.rows - 1; i >= 0; i--) {
        if (line_full(obj, i)) {
            shift_lines(obj, i);
            i++;
            nlines++;
        }
    }
    put(obj, obj.falling);
    return nlines;
}

fn bool game_over(Tetris_game *obj) {
    bool over = false;
    remove(obj, obj.falling);
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < obj.cols; j++) {
            if (is_filled(get(obj, i, j))) {
                over = true;
            }
        }
    }
    put(obj, obj.falling);
    return over;
}

fn bool tick(Tetris_game *obj, Tetris_move move) {
    do_gravity_tick(obj);
    handle_move(obj, move);
    check_lines(obj);
    return !game_over(obj);
}

fn void init(Tetris_game *obj, int rows, int cols) {
    obj.rows = rows;
    obj.cols = cols;
    obj.board = (char*)libc::malloc((usz)(rows * cols));
    libc::memset(obj.board, (int)Tetris_cell.TC_EMPTY, (usz)(rows * cols));
    obj.points = 0;
    obj.level = 0;
    obj.ticks_till_gravity = GRAVITY_LEVEL[obj.level];
    obj.lines_remaining = LINES_PER_LEVEL;
    libc::srand((uint)libc::time(null));

    obj.next.loc.col = obj.cols / 2 - 2;
    new_falling(obj);
    new_falling(obj);

    obj.stored.typ = -1;
    obj.stored.ori = 0;
    obj.stored.loc.row = 0;

    put(obj, obj.falling);
}
