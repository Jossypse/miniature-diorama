#include <cassert>
#include <cstdio>
#if __has_include("reliable_link.h")
#include "reliable_link.h"
using namespace mini;
void connect(ReliableLink& m,SlaveController& s,uint32_t t) {
 Packet tele=s.telemetry(t); m.receive(tele,t);
 Packet hello=m.heartbeat(t); assert(hello.kind==Kind::Hello); assert(s.receive(hello,t));
 m.receive(s.telemetry(t),t); assert(m.connected);
}
int main(){
 ReliableLink m(11); SlaveController s(22); connect(m,s,1);
 assert(m.requestRelay(1,true,2)); Packet on=m.command;
 assert(s.receive(on,2)); assert(s.relays==1);
 assert(s.receive(on,3)); assert(s.relays==1); // duplicate is harmless, ack again
 m.receive(s.acknowledgment(on),3); assert(!m.pending && m.confirmed==1);
 assert(m.requestRelay(1,false,4)); auto off=m.command; s.receive(off,4); assert(s.relays==0);
 s.receive(on,5); assert(s.relays==0); // older ON cannot overtake OFF
 m.receive(s.acknowledgment(on),5); assert(m.pending); // old ack cannot settle new command
 m.receive(s.acknowledgment(off),6); assert(!m.pending && m.confirmed==0);
 assert(m.requestRelay(2,true,7)); assert(m.retryDue(7)); // initial send must not wait 250 ms
 assert(!m.retryDue(256)); assert(m.retryDue(257));
 assert(m.retryDue(507)); assert(m.retryDue(757)); assert(!m.retryDue(1007));
 assert(!m.pending && m.failed);
 ReliableLink m2(33); SlaveController s2(44); connect(m2,s2,1);
 assert(m2.requestRelay(1,true,2)); auto old=m2.command; s2.receive(old,2);
 assert(s2.tick(1001,55)); assert(s2.relays==0 && s2.session==55);
 assert(!s2.receive(old,1002)); assert(s2.relays==0);
 m2.tick(1001); assert(!m2.connected && !m2.pending);
 connect(m2,s2,1002); assert(!m2.pending && m2.desired==0);
 assert(!s2.receive(old,1003));
 Packet invalid=s2.telemetry(1003); invalid.target=999; m2.receive(invalid,1003);
 assert(m2.lastRx==1002);
 ReliableLink m3(66);SlaveController s3(77);connect(m3,s3,1);
 m3.tick(1001);assert(!m3.connected && m3.peer==0);
 auto stale=s3.telemetry(1002);assert(!m3.receive(stale,1002));assert(!m3.connected);
 assert(!s3.receive(m3.heartbeat(1002),1002)); // no fresh heartbeat to retired session
 assert(s3.tick(1002,88));connect(m3,s3,1003);assert(m3.connected && m3.desired==0);
 Packet retiredDiscovery;retiredDiscovery.kind=Kind::Telemetry;retiredDiscovery.session=77;
 m3.receive(retiredDiscovery,1004);assert(m3.connected && m3.peer==88); // delayed pre-reset discovery
 ReliableLink m4(101);SlaveController s4(202);connect(m4,s4,1);
 auto before=s4.telemetry(2);assert(m4.requestRelay(1,true,3));s4.receive(m4.command,3);
 m4.receive(s4.acknowledgment(m4.command),4);assert(m4.confirmed==1);
 m4.receive(before,5);assert(m4.confirmed==1); // earlier telemetry cannot undo later ACK
 assert(m4.requestRelay(2,true,6));auto waiting=m4.command;
 m4.receive(s4.telemetry(1005),1005);assert(!m4.connected && !m4.pending);
 (void)waiting;
 puts("PASS link: handshake, acks, retries, reordered commands, stale sessions, reconnect");
}
#else
int main(){puts("FAIL: reliable link not implemented");return 1;}
#endif
