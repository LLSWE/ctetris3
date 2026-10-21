import std::time;
import libc;

struct Timespec {
    int tv_sec;
    int tv_nsec;
};


void sleep(int millisecs){
   Timespec ts;
   ts.tv_nsec = 0;
   ts.tv_nsec = millisecs * 1000 * 1000;

    libc::nanosleep(&ts, null);
}
