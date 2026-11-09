#include <cassert>
#include <cstdio>
#include "combined_action.h"
using namespace mini;
void connect(ReliableLink& l){Packet p;p.kind=Kind::Telemetry;p.session=22;l.receive(p,1);p.target=11;p.sequence=1;l.receive(p,2);}
void ack(ReliableLink& l,uint32_t now){Packet p;p.kind=Kind::Ack;p.session=22;p.target=11;p.ack=l.command.sequence;p.relays=l.desired;l.lastRx=now;assert(l.receive(p,now));}
int main(){
 ReliableLink l(11);CombinedAction c;connect(l);
 assert(!c.toggle(l,false,3));assert(!l.pending&&!c.engaged());
 assert(c.toggle(l,true,4));assert(c.pending&&c.playRequested&&l.desired==1&&l.command.relays==1);
 c.playRequested=false;ack(l,5);c.tick(l,5,false);assert(c.pending&&!c.active);
 c.tick(l,6,true);assert(c.active&&!c.pending);
 c.tick(l,4005,true);assert(l.desired==1&&!l.pending);
 c.tick(l,4006,true);assert(l.desired==2&&l.command.relays==2&&l.pending);
 c.tick(l,9000,true);assert(l.desired==2); // no backlog while waiting for the switch ACK
 ack(l,9001);c.tick(l,9001,true);c.tick(l,13000,true);assert(l.desired==2);
 c.tick(l,13001,true);assert(l.desired==1&&l.command.relays==1);ack(l,13002);c.tick(l,13002);
 c.cancel(l,13003);assert(!c.engaged()&&c.stopRequested&&l.desired==0&&l.command.relays==0);
 c.stopRequested=false;assert(c.toggle(l,true,14000));c.cancel(l,14001);assert(l.desired==0);
 assert(c.toggle(l,true,15000));l.failed=true;l.pending=false;c.tick(l,15001);assert(!c.engaged()&&c.stopRequested&&l.desired==0);
 assert(c.toggle(l,true,16000));l.drop();c.tick(l,16001);assert(!c.engaged()&&c.stopRequested);
 ReliableLink w(11);CombinedAction wrap;connect(w);assert(wrap.toggle(w,true,0xfffffff0U));ack(w,0xfffffff1U);wrap.tick(w,0xfffffff1U);wrap.tick(w,3984U);assert(w.desired==1);wrap.tick(w,3985U);assert(w.desired==2);
 puts("PASS dancing fountain: 4s alternating masks, ACK gating, both-pump stop, failures and rollover");
}
