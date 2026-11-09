#include <cassert>
#include <cstdio>
#if __has_include("wifi_controller.h")
#include "wifi_controller.h"
using namespace mini;
int main(){
 Controller c;ReliableLink l(1);CombinedAction b;WifiController d(c,l,b,1);
 ApiCommand x;x.boot=1;strcpy(x.id,"mode");x.action=ApiAction::Mode;x.enabled=false;
 d.registry.admit(x,0);d.execute(x,0);assert(!c.automatic);
 c.setLight(1,true);c.tick(1,{});c.setMode(false,2);c.tick(2,{});assert(c.out.fountain==Color::Blue);
 x.action=ApiAction::Light;x.number=3;x.enabled=true;strcpy(x.id,"light");d.registry.admit(x,3);
 c.setMode(true,3);d.execute(x,4);CommandResult result;d.registry.lookup("light",result);assert(result.reason==Reason::ModeRejected);
 Packet p;p.sound=1;p.ir=1;p.color=Color::Red;d.history.observe(p,100);p.sound=0;d.history.observe(p,300);
 assert(d.history.soundSequence==1 && d.history.detected(850));assert(!d.history.detected(2100));
 l.connected=true;l.lastRx=850;SensorState s{true,false,false,2048,Color::None};
 c.setMode(false,500);d.sensors=s;d.motor(500);d.motor(750);
 x.action=ApiAction::FlagMove;strcpy(x.id,"move");strcpy(x.lease,"gesture");x.sequence=1;x.direction=1;
 d.registry.admit(x,850);d.execute(x,850);assert(d.motor(851)==1);
 d.sensors.joy=3500;assert(d.motor(852)==1 && d.motorOwner==1);
 d.sensors.joy=2048;assert(d.motor(853)==0);assert(d.motion.move("gesture",2,1,854)==Reason::MotionExpired);
 d.audio.ready=true;assert(d.play(1,1000));d.stopAudio(1001);assert(!d.pause(1002));
 for(int i=0;i<8;i++)d.volume(uint8_t(i));d.audioError(Reason::AudioUnavailable,1003);
 AudioEffect effect;bool stopped=false;while(d.takeEffect(effect))if(effect.op==AudioOp::Stop&&effect.generation==d.audio.generation)stopped=true;assert(stopped);
 ApiCommand abandoned;abandoned.boot=1;strcpy(abandoned.id,"unqueued");abandoned.action=ApiAction::Stop;
 d.registry.admit(abandoned,2000);d.tick(4000);d.registry.lookup("unqueued",result);assert(result.status==CommandStatus::Failed);
 Controller cc;ReliableLink ll(1);CombinedAction bb;WifiController dd(cc,ll,bb,1);ll.connected=true;ll.lastRx=5000;
 ApiCommand relay;relay.boot=1;relay.action=ApiAction::Relay;relay.number=1;
 for(int i=0;i<3;i++){snprintf(relay.id,49,"relay%d",i);relay.enabled=i!=1;dd.registry.admit(relay,5000+i);dd.execute(relay,5000+i);}
 dd.tick(5003);dd.registry.lookup("relay0",result);assert(result.status==CommandStatus::Failed&&result.reason==Reason::Superseded);
 dd.registry.lookup("relay1",result);assert(result.status==CommandStatus::Failed&&result.reason==Reason::Superseded);
 ll.pending=false;ll.confirmed=1;dd.tick(5004);dd.registry.lookup("relay2",result);assert(result.status==CommandStatus::Applied);
 puts("PASS Wi-Fi controller: mode races, sound history, motor arbitration");
}
#else
int main(){puts("FAIL Wi-Fi controller not implemented");return 1;}
#endif
