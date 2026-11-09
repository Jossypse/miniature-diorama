#include <cassert>
#include <cstdio>
#include "wifi_controller.h"
using namespace mini;
void drain(WifiController& d){AudioEffect e;while(d.takeEffect(e)){} }
void start(WifiController& d,ReliableLink& l,uint32_t now){l.connected=true;l.lastRx=now;d.audio.ready=true;assert(d.setCombined(true,now));l.pending=false;l.confirmed=l.desired;d.playing(now);d.tick(now);drain(d);}
int main(){
 Controller c;ReliableLink l(1);CombinedAction b;WifiController d(c,l,b,1);
 start(d,l,1);d.tick(4001);assert(l.desired==2);l.pending=false;l.confirmed=2;d.tick(4002);
 assert(d.pause(4003));assert(!b.engaged()&&l.desired==0&&d.audio.phase==AudioPhase::Paused);drain(d);
 start(d,l,5000);d.finished(1,5001);assert(!b.engaged()&&l.desired==0);drain(d);
 start(d,l,6000);d.audioError(Reason::AudioUnavailable,6001);assert(!b.engaged()&&l.desired==0);drain(d);
 start(d,l,7000);assert(d.setRelay(2,true,7001));assert(!b.engaged()&&l.desired==2&&d.audio.phase==AudioPhase::Stopped);drain(d);
 start(d,l,8000);ApiCommand stop;stop.boot=1;strcpy(stop.id,"show_off");stop.action=ApiAction::Combined;stop.enabled=false;d.registry.admit(stop,8001);d.execute(stop,8001);
 auto* r=d.registry.record(stop.id);assert(r&&r->concern==3&&r->wait==1&&r->result.status==CommandStatus::Pending);
 l.pending=false;l.confirmed=0;d.tick(8002);assert(r->result.status==CommandStatus::Applied);
 puts("PASS fountain controller: both-pump cancel on pause/end/error, shared ownership, full OFF acknowledgement");
}
