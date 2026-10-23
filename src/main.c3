import std::io;
import libc;
import tetris;
import utils;

extern fn ulong nc_get_reverse();
extern fn int doupdate();
extern fn void* initscr();
extern fn int endwin();
extern fn int cbreak();
extern fn int noecho();
extern fn int echo();
extern fn int keypad(void *win, bool bf);
extern fn int timeout(int delay);
extern fn int curs_set(int visibility);
extern fn int start_color();
extern fn int init_pair(short pair, short f, short b);
extern fn void* newwin(int nlines, int ncols, int begin_y, int begin_x);
extern fn int box(void *win, uint verch, uint horch);
extern fn int wmove(void *win, int y, int x);
extern fn int waddch(void *win, uint ch);
extern fn int wnoutrefresh(void *win);
extern fn int wclear(void *win);
extern fn int wprintw(void *win, char *fmt, ...);
extern fn int getch();
extern fn int clear();
extern fn int printw(char *fmt, ...);

const int COLS_PER_CELL = 2;

const uint A_REVERSE_FLAG = 1 << 18;

fn void add_block(void *w, int x) {
    waddch(w, ' ' | A_REVERSE_FLAG |(uint) color_pair((short)x)); 
    waddch(w, ' ' | A_REVERSE_FLAG |(uint) color_pair((short)x));
}

fn void add_empty(void *w) {
    waddch(w, ' ');
    waddch(w, ' ');
}

fn int color_pair(short n) {
    return n << 8;
}

fn void display_board(void *w, Tetris_game *obj) {
    box(w, 0, 0);
    for (int i = 0; i < obj.rows; i++) {
        wmove(w, 1 + i, 1);
        for (int j = 0; j < obj.cols; j++) {
            char cell_val = tetris::get(obj, i, j);
            if (tetris::is_filled(cell_val)) {
                add_block(w, (int)cell_val);
            } else {
                add_empty(w);
            }
        }
    }
    wnoutrefresh(w);
}

fn void display_piece(void *w, Tetris_block block) {
    wclear(w);
    box(w, 0, 0);
    if (block.typ == -1) {
        wnoutrefresh(w);
        return;
    }
    for (int b = 0; b < tetris::TETRIS; b++) {
        Tetris_location c = tetris::TETROMINOS[block.typ][block.ori][b];
        wmove(w, c.row + 1, c.col * COLS_PER_CELL + 1);
        add_block(w, tetris::type_to_cell(block.typ));
    }
    wnoutrefresh(w);
}

fn void display_score(void *w, Tetris_game *tg) {
    wclear(w);
    box(w, 0, 0);
    wprintw(w, "Score\n%d\n", tg.points);
    wprintw(w, "Level\n%d\n", tg.level);
    wprintw(w, "Lines\n%d\n", tg.lines_remaining);
    wnoutrefresh(w);
}

fn void boss_mode() {
    clear();
    printw("⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢻⣧⣀⣼⠇⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄\n "
           "⠄⣠⣾⣿⣷⡀⠄⠄⠄⠄⠄⣤⣶⣿⣿⣿⣦⣄⠄⠄⠄⠄⠄⣠⣾⣿⣷⣄⠄ \n"
           "⠺⣿⣿⣿⣿⣿⣦⡀⠄⠄⠄⠿⢿⣿⣿⣿⡿⠟⠄⠄⠄⢀⣼⣾⣿⣿⣿⡿⠇\n "
           "⠄⠈⠻⢿⣿⣿⢛⡇⠄⠄⢀⣠⡤⣖⣗⣷⠤⣄⣀⠄⠄⣸⠛⣿⣿⡿⠋⠄⠄\n "
           "⠄⠄⠄⠄⠙⠛⠛⢗⡴⣛⠭⣖⢂⠏⡟⢹⠖⢖⠭⡓⢤⡛⠛⠛⠉⠄⠄⠄⠄\n "
           "⠄⠄⠄⠄⠄⠄⡴⣫⢞⢈⡳⠛⠈⠉⠉⠉⠙⠺⢦⡿⠢⡙⣆⠄⠄⠄⠄⠄⠄\n "
           "⠄⠄⠄⠄⠄⡾⣱⠉⡲⣏⢀⡠⠴⢶⣟⣓⡤⠔⣚⠑⣖⢛⡌⣧⠄⠄⠄⠄⠄\n "
           "⠄⠄⠄⠄⢸⢧⣇⢬⠃⠐⢵⣏⣛⠸⢷⣶⣚⡭⠾⠄⠘⣑⣺⢸⡄⠄⠄⠄⠄\n "
           "⠄⠄⠄⠨⣯⣿⣙⣨⠄⠄⠣⠩⢖⣫⠭⠭⡵⣚⣭⢅⠄⡷⢶⣿⣽⠄⠄⠄⠄\n "
           "⠄⠄⠄⠈⠹⡝⣿⡿⡀⠄⠈⣋⡭⢖⣫⡭⣞⡽⢖⣫⢤⣉⣹⢹⠏⠄⠄⠄⠄\n "
           "⠄⣦⡀⠄⠄⢳⡱⣥⡶⢄⠄⠸⡚⠁⢰⣛⡭⠖⠉⡠⠳⣭⢇⡟⠄⠄⢀⣴⠄\n "
           "⠄⣿⢞⣷⡀⠄⢀⠜⠲⣍⡲⠿⣢⣰⣩⣠⡃⠿⣛⡡⠞⠥⡀⠄⣠⣟⡶⡿⠄\n "
           "⠄⠄⠈⢫⡻⣶⡟⠁⠄⠄⠉⠑⠒⣗⣟⡗⠒⠛⠉⠄⠄⠄⢨⣶⣯⠞⠄⠁⠄\n "
           "⠄⠄⠄⡠⠻⢮⡻⣦⣄⡀⠄⠄⣀⣥⣥⣥⡀⠄⠄⣀⣠⡶⣿⡿⠛⢆⠄⠄⠄\n "
           "⠄⠄⠾⠉⠄⠄⠙⠿⣽⣟⣿⣿⡿⠟⢹⣿⣿⣿⣟⣿⣽⠞⠋⠄⠄⠄⠑⠄⠄\n "
           );
    echo();
    timeout(-1);
    while (getch() != 265); 
    timeout(0);
    noecho();
    clear();
}

fn void save_game(Tetris_game *game, void *w) {
    wclear(w);
    box(w, 0, 0);
    wmove(w, 1, 1);
    wprintw(w, "Save and exit? [Y/n] ");
    wnoutrefresh(w);
    timeout(-1);
    if (getch() == 'n') {
        timeout(0);
        return;
    }
    endwin();
    io::printn("Game saved.");
    libc::exit(0);
}

fn void init_colors() {
    start_color();
    init_pair(1, 6, 0); 
    init_pair(2, 4, 0); 
    init_pair(3, 7, 0); 
    init_pair(4, 3, 0); 
    init_pair(5, 2, 0); 
    init_pair(6, 5, 0); 
    init_pair(7, 1, 0); 
}

fn int main(int argc, char **argv) {
    Tetris_game inst;
    Tetris_game *tg = &inst;
    tetris::init(tg, 22, 10);
    tetris::put(tg, tg.falling);

    Tetris_move current_move = Tetris_move.TM_NONE;
    bool running = true;

    void *stdscr = initscr();
    cbreak();
    noecho();
    keypad(stdscr, true);
    timeout(0);
    curs_set(0);
    init_colors();

    void *board = newwin(tg.rows + 2, 2 * tg.cols + 2, 0, 0);
    void *next  = newwin(6, 10, 0, 2 * (tg.cols + 1) + 1);
    void *hold  = newwin(6, 10, 7, 2 * (tg.cols + 1) + 1);
    void *score = newwin(6, 10, 14, 2 * (tg.cols + 1) + 1);

    while (running) {
        running = tetris::tick(tg, current_move);

        display_board(board, tg);
        display_piece(next, tg.next);
        display_piece(hold, tg.stored);
        display_score(score, tg);
        doupdate();
        utils::sleep(10);

        int ch = getch();
        switch (ch) {
            case 260: 
                current_move = Tetris_move.TM_LEFT;
                break;
            case 261: 
                current_move = Tetris_move.TM_RIGHT;
                break;
            case 259: 
                current_move = Tetris_move.TM_CLOCK;
                break;
            case 258: 
                current_move = Tetris_move.TM_DROP;
                break;
            case 'q':
                running = false;
                current_move = Tetris_move.TM_NONE;
                break;
            case 'p':
                wclear(board);
                box(board, 0, 0);
                wmove(board, tg.rows / 2, (tg.cols * COLS_PER_CELL - 6) / 2);
                wprintw(board, "PAUSED");
                wnoutrefresh(board);
                timeout(-1);
                getch();
                timeout(0);
                current_move = Tetris_move.TM_NONE;
                break;
            case 'b':
                boss_mode();
                current_move = Tetris_move.TM_NONE;
                break;
            case 's':
                save_game(tg, board);
                current_move = Tetris_move.TM_NONE;
                break;
            case ' ':
                current_move = Tetris_move.TM_HOLD;
                break;
            default:
                current_move = Tetris_move.TM_NONE;
                break;
        }
    }

    endwin();
    io::printn("Game over!");
    io::printfn("You finished with %d points on level %d.", tg.points, tg.level);
    
    return 0;
}
