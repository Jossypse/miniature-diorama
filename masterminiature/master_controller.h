#pragma once
#include "miniature_protocol.h"
namespace mini {
struct Outputs { Color fountain=Color::None; bool building=false,rgb=false; int8_t motor=0; };
class DebouncedButton {
 bool initialized=false, raw=false, stable=false, armed=false; uint32_t changed=0;
public:
 bool update(bool pressed,uint32_t now) {
  if(!initialized) { initialized=true; raw=stable=pressed; armed=!pressed; changed=now; return false; }
  if(raw!=pressed) { raw=pressed; changed=now; }
  if(raw!=stable && elapsed(now,changed,30)) {
   stable=raw;
   if(!stable) armed=true;
   else if(armed) { armed=false; return true; }
  }
  return false;
 }
};
class Controller {
 bool fountain=false,building=false,rgb=false,soundHeld=false; uint32_t lastSound=0;
 bool joystickArmed=false,joystickCentering=false;uint32_t joystickNeutralAt=0;
public:
 bool automatic=true; Outputs out;
 uint16_t joyLow=1000,joyHigh=3000;
 uint32_t joyNeutralMs=250;
 void setMode(bool mode,uint32_t) { if(automatic==mode)return;automatic=mode; fountain=building=rgb=soundHeld=false; out=Outputs{};joystickArmed=joystickCentering=false; }
 bool setLight(uint8_t light,bool on) {
  if(automatic) return false;
  if(light==1) fountain=on; else if(light==2) rgb=on; else if(light==3) building=on; else return false;
  return true;
 }
 bool press(uint8_t button,uint32_t now) {
  if(button==4) { setMode(!automatic,now); return true; }
  if(automatic) return false;
  if(button==1) fountain=!fountain; else if(button==2) rgb=!rgb; else if(button==3) building=!building; else return false;
  return true;
 }
 int8_t joystickDirection(uint32_t now,const SensorState& s){
  if(automatic||!s.fresh||s.joy>4095){joystickArmed=joystickCentering=false;return 0;}
  const bool neutral=s.joy>=joyLow&&s.joy<=joyHigh;
  if(!joystickArmed){
   if(!neutral){joystickCentering=false;return 0;}
   if(!joystickCentering){joystickCentering=true;joystickNeutralAt=now;}
   if(elapsed(now,joystickNeutralAt,joyNeutralMs))joystickArmed=true;
   return 0;
  }
  return s.joy>joyHigh?1:(s.joy<joyLow?-1:0);
 }
 void tick(uint32_t now,const SensorState& s) {
  out.motor=joystickDirection(now,s);
  if(!automatic) { out.fountain=fountain?Color::Blue:Color::None; out.building=building; out.rgb=rgb; return; }
  if(!s.fresh) { soundHeld=false; out=Outputs{}; return; }
  if(s.sound) { soundHeld=true; lastSound=now; }
  if(soundHeld && elapsed(now,lastSound,2000)) soundHeld=false;
  out.fountain=uint8_t(s.color)<=5?s.color:Color::None; out.rgb=s.ir; out.building=soundHeld;
 }
};
// Keeps app freshness independent of uptime and millis rollover.
struct AppPresence {
 bool seen=false; uint32_t last=0;
 void poll(uint32_t now) { seen=true; last=now; }
 bool online(uint32_t now) const { return seen && !elapsed(now,last,APP_MS); }
};
}
