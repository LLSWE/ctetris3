import std::io;


String EMPTY_STR = "";
String BLOCK_STR = "\u2588";

int TETRIS = 4;
int NUM_TETROMINOS = 7;
int NUM_ORIENTATIONS = 4;


int MAX_LEVEL = 19;
int LINES_PER_LEVEL = 10;

fn int type_to_cell(int x){
    return x + 1 
}

enum Tetris_type : int {
    TET_I,
    TET_J,
    TET_L,
    TET_O,
    TET_S,
    TET_T,
    TET_Z
};

struct Tetris_location {
    int row;
    int col;
};

enum Tetris_cell : char{
    TC_EMPTY,
    TC_CELLI,
    TC_CELLL,
    TC_CELLO,
    TC_CELLS,
    TC_CELLT,
    TC_CELLZ,
};

struct Tetris_block{
    int typ;
    int ori;
    Tetris_location loc;
};

enum Tetris_move : int {
    TM_LEFT,
    TM_RIGHT,
    TM_CLOCK,
    TM_COUNTER,
    TM_DROP,
    TM_HOLD,
    TM_NONE
};

struct Tetris_game {
    int rows;
    int cols;
    char *board;

    int points;
    int level;

    Tetris_block falling;
    Tetris_block next;
    Tetris_bloc stored;

    int ticks_till_gravity;
    
    int lines_remaining;
};

Tetris_location TETROMINOS[NUM_TETROMINOS][NUM_ORIENTATIONS][TETRIS] = {
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

int GRAVITY_LEVEL[MAX_LEVEL+1] = {
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
        Tetris_location cell = TETRONOMINOS[block.typ][block.ori][i];
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
    for (i = 0; i < TETRIS; i++) {
    Tetris_location cell = TETRONOMINOS[block.typ][block.ori][i];
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

fn void tg_new_falling(Tetris_game *obj) {
    obj.falling = obj.next;
    obj.next.typ = random_tetromino();
    obj.next.ori = 0;
    obj.next.loc.row = 0;
    obj.next.loc.col = obj.cols / 2 - 2;
}

fn void tg_do_gravity_tick(Tetris_game *obj) {
    obj.ticks_till_gravity--;
    if (obj.ticks_till_gravity <= 0) {
        tg_remove(obj, obj.falling);
        obj.falling.loc.row++;
        if (tg_fits(obj, obj.falling)) {
            obj.ticks_till_gravity = GRAVITY_LEVEL[obj.level];
        } else {
            obj.falling.loc.row--;
            tg_put(obj, obj.falling);
            tg_new_falling(obj);
        }
        tg_put(obj, obj.falling);
    }
}

fn void tg_move(Tetris_game *obj, int direction) {
    tg_remove(obj, obj.falling);
    obj.falling.loc.col += direction;
    if (!tg_fits(obj, obj.falling)) {
        obj.falling.loc.col -= direction;
    }
    tg_put(obj, obj.falling);
}

fn void tg_down(Tetris_game *obj) {
    tg_remove(obj, obj.falling);
    while (tg_fits(obj, obj.falling)) {
        obj.falling.loc.row++;
    }
    obj.falling.loc.row--;
    tg_put(obj, obj.falling);
    tg_new_falling(obj);
}

fn void tg_rotate(Tetris_game *obj, int direction) {
    tg_remove(obj, obj.falling);
    while (true) {
        obj.falling.ori = (obj.falling.ori + direction) % NUM_ORIENTATIONS;
        if (tg_fits(obj, obj.falling)) break;

        obj.falling.loc.col--;
        if (tg_fits(obj, obj.falling)) break;

        obj.falling.loc.col += 2;
        if (tg_fits(obj, obj.falling)) break;

        obj.falling.loc.col--;
        break; // previne loop infinito se nada encaixar
    }
    tg_put(obj, obj.falling);
}

fn void tg_handle_move(Tetris_game *obj, Tetris_move move) {
    switch (move) {
        case TM_LEFT: tg_move(obj, -1);
        case TM_RIGHT: tg_move(obj, 1);
        case TM_DROP: tg_down(obj);
        case TM_CLOCK: tg_rotate(obj, 1);
        case TM_COUNTER: tg_rotate(obj, -1);
        default: break;
    }
}

fn bool tg_line_full(Tetris_game *obj, int i) {
    for (int j = 0; j < obj.cols; j++) {
        if (tc_is_empty(tg_get(obj, i, j))) return false;
    }
    return true;
}

fn void tg_shift_lines(Tetris_game *obj, int r) {
    for (int i = r - 1; i >= 0; i--) {
        for (int j = 0; j < obj.cols; j++) {
            tg_set(obj, i + 1, j, tg_get(obj, i, j));
            tg_set(obj, i, j, (char)Tetris_cell.TC_EMPTY);
        }
    }
}

fn int tg_check_lines(Tetris_game *obj) {
    int nlines = 0;
    tg_remove(obj, obj.falling);
    for (int i = obj.rows - 1; i >= 0; i--) {
        if (tg_line_full(obj, i)) {
            tg_shift_lines(obj, i);
            i++;
            nlines++;
        }
    }
    tg_put(obj, obj.falling);
    return nlines;
}

fn bool tg_game_over(Tetris_game *obj) {
    bool over = false;
    tg_remove(obj, obj.falling);
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < obj.cols; j++) {
            if (tc_is_filled(tg_get(obj, i, j))) {
                over = true;
            }
        }
    }
    tg_put(obj, obj.falling);
    return over;
}

fn bool tg_tick(Tetris_game *obj, Tetris_move move) {
    tg_do_gravity_tick(obj);
    tg_handle_move(obj, move);
    tg_check_lines(obj);
    return !tg_game_over(obj);
}

fn void tg_init(Tetris_game *obj, int rows, int cols) {
    obj.rows = rows;
    obj.cols = cols;
    obj.board = (char*)libc::malloc(rows * cols);
    libc::memset(obj.board, (int)Tetris_cell.TC_EMPTY, rows * cols);
    obj.points = 0;
    obj.level = 0;
    obj.ticks_till_gravity = GRAVITY_LEVEL[obj.level];
    obj.lines_remaining = LINES_PER_LEVEL;
    libc::srand((uint)libc::time(null));
    tg_new_falling(obj);
    tg_new_falling(obj);
    obj.stored.typ = -1;
    obj.stored.ori = 0;
    obj.stored.loc.row = 0;
}
