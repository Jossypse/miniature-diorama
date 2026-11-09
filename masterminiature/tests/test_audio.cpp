#include <cassert>
#include <cstdio>
#if __has_include("audio_monitor.h")
#include "audio_monitor.h"
using namespace mini;
int main(){
 AudioMonitor m;m.start(0);assert(!m.verified);assert(!m.probeDue(99));assert(m.probeDue(100));
 m.tick(999);assert(!m.failed);m.tick(1000);assert(m.failed && !m.verified);
 m.start(2000);assert(m.probeDue(2100));m.response(true,2150);assert(m.verified);
 m.tick(3149);assert(!m.failed);m.tick(3150);assert(m.failed); // unplug after playback starts
 m.start(4000);m.response(false,4100);assert(!m.verified && !m.failed);m.tick(5000);assert(m.failed);
 m.start(0xfffffff0U);m.tick(983);assert(!m.failed);m.tick(984);assert(m.failed);
 m.stop();assert(!m.requested && !m.probeDue(6000));
 uint8_t q[10];makeStateQuery(q);const uint8_t expected[]={0x7e,0xff,6,0x42,0,0,0,0xfe,0xb9,0xef};
 for(int i=0;i<10;++i)assert(q[i]==expected[i]);
 puts("PASS audio: silent startup/runtime failure, response verification, rollover and state query");
}
#else
int main(){puts("FAIL: asynchronous audio verification not implemented");return 1;}
#endif
