#include <cassert>
#include <cstdio>
#if __has_include("master_controller.h")
#include "master_controller.h"
using namespace mini;
int main() {
 Controller c; SensorState s{true,false,false,2048,Color::Red};
 c.tick(10,s); assert(c.out.fountain==Color::Red && !c.out.rgb && !c.out.building);
 assert(!c.press(1,10)); c.setMode(false,20); c.tick(20,s);
 assert(c.out.fountain==Color::None);
 c.press(1,21); c.press(2,22); c.press(3,23); c.tick(24,s);
 assert(c.out.fountain==Color::Blue && c.out.rgb && c.out.building);
 c.press(1,25); c.tick(25,s); assert(c.out.fountain==Color::None);
 c.tick(275,s); // stable neutral arms the joystick after entering manual
 s.joy=3500; c.tick(300,s); assert(c.out.motor==1);
 s.joy=500; c.tick(301,s); assert(c.out.motor==-1);
 s.joy=2048; c.tick(302,s); assert(c.out.motor==0);
 s.joy=3500; s.fresh=false; c.tick(303,s); assert(c.out.motor==0);
 c.setMode(true,400); s.fresh=true; s.ir=true; s.sound=true; c.tick(400,s);
 assert(c.out.motor==0 && c.out.rgb && c.out.building);
 s.ir=false; s.sound=false; s.color=Color::None; c.tick(401,s);
 assert(!c.out.rgb && c.out.building && c.out.fountain==Color::None);
 c.tick(2399,s); assert(c.out.building); c.tick(2400,s); assert(!c.out.building);
 s.sound=true; c.tick(0xfffffff0U,s); s.sound=false; c.tick(1983,s); assert(c.out.building);
 c.tick(1984,s); assert(!c.out.building);
 s.fresh=false; c.tick(2000,s); assert(c.out.fountain==Color::None && !c.out.rgb);
 DebouncedButton b; assert(!b.update(true,0)); assert(!b.update(true,100));
 assert(!b.update(false,101)); assert(!b.update(false,131));
 assert(!b.update(true,132)); assert(!b.update(false,140)); assert(!b.update(true,145));
 assert(!b.update(true,174)); assert(b.update(true,175)); assert(!b.update(true,300));
 assert(!b.update(false,301)); assert(!b.update(false,331));
 assert(!b.update(true,0xfffffff0U)); assert(b.update(true,14));
 puts("PASS controller: buttons, modes, sensor rules, motor, debounce, rollover");
}
#else
int main(){puts("FAIL: master controller not implemented");return 1;}
#endif
