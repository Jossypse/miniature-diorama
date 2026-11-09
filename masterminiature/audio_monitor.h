#pragma once
#include "miniature_protocol.h"
namespace mini {
inline const char* dfPlayerErrorText(uint8_t type,uint16_t value){
 if(type==0)return "Serial timeout";if(type==1)return "Malformed serial frame";if(type==3)return "SD card removed";
 if(type==6){switch(value){case 1:return "SD card not found";case 2:return "Player sleeping";case 3:return "Command format rejected";case 4:return "Command checksum rejected";case 5:return "File index out of range";case 6:return "File not found";case 7:return "Advertisement active";default:return "Module error";}}
 return "Unknown audio event";
}
class AudioMonitor {
 uint32_t began=0,lastGood=0,lastProbe=0;bool probed=false;
public:
 bool requested=false,verified=false,failed=false;
 void start(uint32_t now){requested=true;verified=failed=probed=false;began=lastGood=lastProbe=now;}
 void stop(){requested=verified=failed=false;}
 bool probeDue(uint32_t now){
  if(!requested || failed || !elapsed(now,began,100) || (probed && !elapsed(now,lastProbe,250)))return false;
  probed=true;lastProbe=now;return true;
 }
 void response(bool playing,uint32_t now){if(requested && playing){verified=true;lastGood=now;}}
 void tick(uint32_t now){if(requested && elapsed(now,verified?lastGood:began,1000)){failed=true;verified=false;}}
};
inline void makeStateQuery(uint8_t (&q)[10]){
 const uint8_t command[]={0x7e,0xff,6,0x42,0,0,0,0xfe,0xb9,0xef};memcpy(q,command,10);
}
}
