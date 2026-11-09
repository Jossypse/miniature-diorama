#pragma once
#include <stdint.h>
#include <stddef.h>
#include <string.h>

namespace mini {
constexpr uint32_t HEARTBEAT_MS=200, STALE_MS=1000, RETRY_MS=250, APP_MS=5000;
inline bool elapsed(uint32_t now,uint32_t since,uint32_t interval) { return uint32_t(now-since)>=interval; }
inline bool newerSequence(uint32_t a,uint32_t b) { return a!=b && uint32_t(a-b)<0x80000000U; }
enum class Kind:uint8_t { Hello=1, Heartbeat, Telemetry, Command, Ack };
enum class Color:uint8_t { None, Red, Green, Blue, Yellow, White };
enum class Event:uint8_t {
  Boot, AutoMode, ManualMode, Button1, Button2, Button3, Button4, Button5,
  AutoOwnsLights, FountainOn, FountainOff, BuildingOn, BuildingOff, RgbOn, RgbOff,
  MotorUp, MotorDown, MotorStop, LinkOnline, LinkLost, PumpPending, PumpConfirmed,
  PumpFailed, AudioPlay, AudioStop, AudioUnavailable, AudioError, CombinedOn,
  CombinedOff, AppOnline, AppOffline, Count
};
inline const char* eventText(Event e) {
  static const char* const names[]={"Boot","Automatic mode","Manual mode","Button 1","Button 2","Button 3","Button 4","Button 5",
    "Use manual mode","Fountain on","Fountain off","Building on","Building off","RGB cycle on","RGB off",
    "Flag up","Flag down","Flag stopped","Master link OK","Master link lost","Pump pending","Pump confirmed",
    "Pump cmd failed","Audio requested","Audio stopped","Audio not ready","Audio error","Fountain show on",
    "Fountain show off","App online","App offline"};
  return uint8_t(e)<uint8_t(Event::Count)?names[uint8_t(e)]:"Unknown event";
}
// Both boards are ESP32, but packed fixed-width fields also make the wire ABI explicit.
#pragma pack(push,1)
struct Packet {
  uint32_t magic=0x4d494e49U;
  uint8_t version=1;
  Kind kind=Kind::Hello;
  uint32_t session=0, target=0, sequence=0, ack=0;
  uint16_t joy=2048;
  Color color=Color::None;
  uint8_t ir=0, sound=0, relays=0, automatic=1, app=0;
  Event event=Event::Boot;
  uint32_t eventSequence=0;
};
#pragma pack(pop)
static_assert(sizeof(Packet)==35,"Protocol layout changed; bump version on both boards");
struct ReceivedPacket { Packet packet;uint32_t receivedAt; };
inline bool validatePacket(const Packet& p,size_t size) {
  return size==sizeof(Packet) && p.magic==0x4d494e49U && p.version==1 && p.session!=0 &&
    uint8_t(p.kind)>=1 && uint8_t(p.kind)<=5 && p.joy<=4095 && uint8_t(p.color)<=5 &&
    p.ir<=1 && p.sound<=1 && p.relays<=3 && p.automatic<=1 && p.app<=1 && uint8_t(p.event)<uint8_t(Event::Count);
}
inline bool decodePacket(Packet& p,const uint8_t* data,size_t size) {
  if(!data || size!=sizeof(Packet)) return false;
  memcpy(&p,data,sizeof p); return validatePacket(p,size);
}
struct SensorState { bool fresh=false, ir=false, sound=false; uint16_t joy=2048; Color color=Color::None; };
}
