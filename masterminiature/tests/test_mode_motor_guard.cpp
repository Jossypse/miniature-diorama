#include <cassert>
#include <cstdio>
#include "wifi_controller.h"
using namespace mini;
int main(){
 Controller c;ReliableLink l(1);CombinedAction b;WifiController d(c,l,b,1);
 d.sensors={true,false,false,3500,Color::None};assert(d.motor(0)==0);
 ApiCommand mode;mode.boot=1;strcpy(mode.id,"manual");mode.action=ApiAction::Mode;mode.enabled=false;d.registry.admit(mode,1);d.execute(mode,1);
 assert(d.motor(2)==0&&d.motorOwner==0);assert(d.motor(1000)==0); // held input must not start on mode entry
 d.sensors.joy=2048;assert(d.motor(1001)==0);assert(d.motor(1249)==0);
 d.sensors.joy=3500;assert(d.motor(1250)==0); // interrupted neutral dwell does not arm
 d.sensors.joy=2048;d.motor(1500);d.motor(1750);d.sensors.joy=3500;
 assert(d.motor(1751)==1&&d.motorOwner==1); // intentional move after stable neutral
 c.setMode(true,2000);assert(d.motor(2000)==0);c.setMode(false,2001);assert(d.motor(2001)==0);
 ApiCommand move;move.boot=1;strcpy(move.id,"raise");move.action=ApiAction::FlagMove;strcpy(move.lease,"held");move.sequence=1;move.direction=1;
 d.registry.admit(move,2100);assert(d.execute(move,2100)==Reason::None);assert(d.motor(2101)==1&&d.motorOwner==2); // app hold remains explicit
 d.sensors.joy=2048;d.motor(2200);d.motor(2450);d.sensors.joy=500;assert(d.motor(2451)==-1&&d.motorOwner==1);
 d.sensors.joy=2048;assert(d.motor(2452)==0); // joystick takeover revoked app lease
 d.sensors.fresh=false;assert(d.motor(2500)==0);d.sensors.fresh=true;d.sensors.joy=500;assert(d.motor(2501)==0); // reconnect cannot resume a held input
 Controller wrap;wrap.setMode(false,0xfffffff0U);SensorState s{true,false,false,2048,Color::None};wrap.tick(0xfffffff0U,s);wrap.tick(233U,s);assert(wrap.out.motor==0);wrap.tick(234U,s);s.joy=3500;wrap.tick(235U,s);assert(wrap.out.motor==1);
 s.joy=2048;wrap.tick(300U,s);wrap.tick(550U,s);s.joy=3500;wrap.tick(551U,s);assert(wrap.out.motor==1);
 puts("PASS manual motor guard: no motion on mode entry, stable neutral, explicit app hold, reconnect and rollover");
}
