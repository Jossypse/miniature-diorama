#pragma once
#include "miniature_protocol.h"
namespace mini {
class ReliableLink {
 uint32_t seq=0,lastTelemetrySeq=0,confirmedSequence=0,retiredPeers[4]={0,0,0,0};uint8_t retiredHead=0;
 bool sawTelemetry=false,unsent=false;
 bool retired(uint32_t boot) const {for(uint8_t i=0;i<4;++i)if(retiredPeers[i]==boot)return true;return false;}
public:
 uint32_t session, peer=0,lastRx=0,lastSend=0; uint8_t confirmed=0,desired=0,retries=0;
 bool connected=false,pending=false,failed=false; Packet command{},latest{};
 explicit ReliableLink(uint32_t boot):session(boot?boot:1){}
 void drop() {
  if(peer && !retired(peer)){retiredPeers[retiredHead]=peer;retiredHead=uint8_t((retiredHead+1)%4);}
  peer=0;connected=pending=false;desired=confirmed=0;confirmedSequence=0;failed=true;
 }
 Packet heartbeat(uint32_t) {
  Packet p; p.session=session; p.target=peer; p.sequence=++seq;
  p.kind=connected?Kind::Heartbeat:Kind::Hello; return p;
 }
 bool receive(const Packet& p,uint32_t now) {
  tick(now); // an expired link cannot be refreshed by a delayed queued packet
  if(!validatePacket(p,sizeof p) || (p.kind!=Kind::Telemetry && p.kind!=Kind::Ack)) return false;
  if(p.kind==Kind::Telemetry && p.target==0) {
   if(retired(p.session)) return false;
   if(peer!=p.session) { drop(); peer=p.session; sawTelemetry=false; }
   return false; // discovery is not evidence of an established link
  }
  if(p.target!=session || p.session!=peer) return false;
  if(p.kind==Kind::Telemetry) {
   if(sawTelemetry && !newerSequence(p.sequence,lastTelemetrySeq)) return false;
   sawTelemetry=true; lastTelemetrySeq=p.sequence; latest=p; lastRx=now;
   if(!connected) { desired=0; pending=false; failed=false; }
   connected=true;
   if(!newerSequence(confirmedSequence,p.ack)){confirmed=p.relays;confirmedSequence=p.ack;}
   return true;
  }
  if(!connected || !pending || p.ack!=command.sequence) return false;
  confirmed=p.relays;confirmedSequence=p.ack;
  if(confirmed==desired) { pending=false; failed=false; } else { pending=false; failed=true; }
  return true;
 }
 bool requestRelay(uint8_t relay,bool on,uint32_t now) {
  if(!connected || relay<1 || relay>2) return false;
  const uint8_t bit=uint8_t(1U<<(relay-1));
  desired=on?uint8_t(desired|bit):uint8_t(desired&~bit);
  command=Packet{}; command.kind=Kind::Command; command.session=session; command.target=peer;
  command.sequence=++seq; command.relays=desired;
  pending=true; unsent=true; failed=false; retries=0; lastSend=now; return true;
 }
 bool retryDue(uint32_t now) {
  if(pending && unsent) { unsent=false;lastSend=now;return true; }
  if(!pending || !elapsed(now,lastSend,RETRY_MS)) return false;
  if(retries>=3) { drop(); return false; }
  ++retries; lastSend=now; return true;
 }
 void tick(uint32_t now) { if(connected && elapsed(now,lastRx,STALE_MS)) drop(); }
};
class SlaveController {
 uint32_t master=0,lastControlSeq=0,lastHeartbeatSeq=0,teleSeq=0;
 bool sawControl=false; uint32_t lastRx=0;
public:
 uint32_t session; uint8_t relays=0; bool connected=false;
 Packet status{};
 explicit SlaveController(uint32_t boot):session(boot?boot:1){}
 bool receive(const Packet& p,uint32_t now) {
  if(!validatePacket(p,sizeof p) || p.target!=session) return false;
  if(p.kind==Kind::Hello) {
   if(connected && p.session!=master) return false;
   if(!connected) { master=p.session; connected=true; relays=0; lastControlSeq=0; sawControl=false; }
   else if(!newerSequence(p.sequence,lastHeartbeatSeq)) return false;
   lastHeartbeatSeq=p.sequence; lastRx=now; status=p; return true;
  }
  if(!connected || p.session!=master) return false;
  if(p.kind==Kind::Heartbeat) {
   if(!newerSequence(p.sequence,lastHeartbeatSeq)) return false;
   lastHeartbeatSeq=p.sequence; lastRx=now; status=p; return true;
  }
  if(p.kind!=Kind::Command) return false;
  // Commands do not refresh heartbeat watchdog. Duplicate ON is acknowledged, never replayed.
  if(sawControl && p.sequence==lastControlSeq) return true;
  if(sawControl && !newerSequence(p.sequence,lastControlSeq)) return false;
  sawControl=true; lastControlSeq=p.sequence; relays=p.relays; return true;
 }
 Packet telemetry(uint32_t) {
  Packet p; p.kind=Kind::Telemetry; p.session=session; p.target=connected?master:0;
  p.sequence=++teleSeq; p.relays=relays;p.ack=sawControl?lastControlSeq:0;return p;
 }
 Packet acknowledgment(const Packet& command) const {
  Packet p; p.kind=Kind::Ack; p.session=session; p.target=master; p.ack=command.sequence; p.relays=relays; return p;
 }
 bool tick(uint32_t now,uint32_t nextSession) {
  if(!connected || !elapsed(now,lastRx,STALE_MS)) return false;
  connected=false; relays=0; master=0; sawControl=false;
  session=nextSession?nextSession:1; if(session==status.target) ++session;
  if(!session) session=1;
  return true;
 }
};
}
