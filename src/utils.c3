import std::time;
import libc;

struct Timespec {
    long tv_sec;
    long tv_nsec;
}

fn void sleep(int millisecs) {
    Timespec ts;
    ts.tv_sec = 0;
    ts.tv_nsec = (long)millisecs * 1000 * 1000;

    // Faz o cast direto para o ponteiro que o nanosleep espera, bypassando a checagem estrita de tipo
    libc::nanosleep((void*)&ts, null);
}
