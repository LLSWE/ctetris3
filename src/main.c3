import std::io;

fn void main(){
    bool running = true;
    int a = 0;

    while(running){
        io::printf("%s\n", a);
        a++;
    }
}
