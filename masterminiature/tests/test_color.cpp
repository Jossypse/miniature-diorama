#include <cassert>
#include <cstdio>
#if __has_include("../slaveminiature/slave_color.h")
#include "../slaveminiature/slave_color.h"
using namespace mini;
int main(){
 ColorCalibration c;
 assert(classifyColor({0,0,0},c)==Color::None);
 assert(classifyColor({1000,1000,1000},c)==Color::None);
 assert(classifyColor({50,500,500},c)==Color::Red);
 assert(classifyColor({500,50,500},c)==Color::Green);
 assert(classifyColor({500,500,50},c)==Color::Blue);
 assert(classifyColor({50,50,500},c)==Color::Yellow);
 assert(classifyColor({50,50,50},c)==Color::White);
 assert(classifyColor({150,180,250},c)==Color::None);
 assert(classifyColor({0,50,50},c)==Color::None);
 c.whiteUs[0]=c.darkUs[0]; assert(classifyColor({50,50,50},c)==Color::None);
 puts("PASS color: calibration, supported colors, absence, ambiguity, pulse timeout");
}
#else
int main(){puts("FAIL: color classification not implemented");return 1;}
#endif
