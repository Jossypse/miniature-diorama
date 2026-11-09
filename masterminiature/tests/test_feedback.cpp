#include <cassert>
#include <cstdio>
#include <string>
#if __has_include("feedback.h")
#include "feedback.h"
#include "master_controller.h"
using namespace mini;
int main(){
 AppPresence app; assert(!app.online(0)); app.poll(100); assert(app.online(5099));assert(!app.online(5100));
 app.poll(0xfffffff0U); assert(app.online(4983));assert(!app.online(4984));
 EventLog log; log.push(Event::Button1); log.push(Event::Button2); assert(log.latest()==Event::Button2);
 for(int i=0;i<20;++i) log.push(Event::MotorStop); assert(log.size()==8);
 char row[17]; lcdRow(row,"abcdefghijklmnopqrst"); assert(std::string(row)=="abcdefghijklmnop");
 lcdRow(row,"OFF");assert(std::string(row)=="OFF             ");
 char escaped[40]; escapeJson(escaped,sizeof escaped,"a\"b\\c\n"); assert(std::string(escaped)=="a\\\"b\\\\c\\n");
 Controller c; assert(!c.setLight(1,true));c.setMode(false,0);assert(c.setLight(1,true));
 c.tick(1,SensorState{});assert(c.out.fountain==Color::Blue);
 puts("PASS feedback: app timeout/rollover, bounded logs, LCD width, JSON escaping, web mode ownership");
}
#else
int main(){puts("FAIL: feedback helpers not implemented");return 1;}
#endif
