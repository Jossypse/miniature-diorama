#include <cassert>
#include <cstdio>
#if __has_include("motion_lease.h")
#include "motion_lease.h"
using namespace mini;
int main(){
 MotionLease m;assert(m.move("one",1,1,100)==Reason::None);assert(m.direction(1099)==1);assert(m.direction(1100)==0);
 assert(m.move("one",2,1,1101)==Reason::MotionExpired);
 assert(m.move("two",10,-1,1200)==Reason::None);assert(m.move("other",1,1,1201)==Reason::MotionBusy);
 assert(m.stop("old",9,1202)==Reason::None);assert(m.direction(1203)==-1);
 assert(m.stop("two",12,1204)==Reason::None);assert(m.move("two",10,-1,1205)==Reason::MotionExpired);
 assert(m.stop("before",3,1300)==Reason::None);assert(m.move("before",1,1,1301)==Reason::MotionExpired);
 assert(m.move("cap",30,1,2000)==Reason::None);
 for(unsigned i=2;i<26;++i)assert(m.move("cap",i+30,1,2000+(i-1)*200)==Reason::None);
 assert(m.direction(7000)==0);assert(m.move("cap",60,1,7000)==Reason::MotionExpired);
 MotionLease wrap;wrap.move("roll",1,1,0xfffffff0U);assert(wrap.direction(983)==1);assert(wrap.direction(984)==0);
 MotionLease replay;
 assert(replay.move("oldest",10,1,0)==Reason::None);assert(replay.stop("oldest",11,1)==Reason::None);
 for(unsigned i=0;i<6;i++){char id[20];snprintf(id,sizeof id,"new%u",i);assert(replay.move(id,20+i*2,1,10+i*2)==Reason::None);assert(replay.stop(id,21+i*2,11+i*2)==Reason::None);}
 assert(replay.move("oldest",10,1,100)==Reason::Superseded);
 puts("PASS motor lease: expiry, cap, stopped replay, owner, wrap");
}
#else
int main(){puts("FAIL motion lease not implemented");return 1;}
#endif
