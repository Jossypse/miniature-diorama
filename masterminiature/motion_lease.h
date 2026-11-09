#pragma once
#include "wifi_api.h"
namespace mini {
class MotionLease{
 char owner[49]{},ended[4][49]{};uint8_t nextEnded=0;uint32_t sequence=0,began=0,renewed=0;int8_t dir=0;bool sequenced=false;
 bool closed(const char* id)const{for(const auto& e:ended)if(strcmp(e,id)==0)return true;return false;}
 void remember(const char* id){if(!validId(id)||closed(id))return;strcpy(ended[nextEnded],id);nextEnded=uint8_t((nextEnded+1)%4);}
public:
 uint32_t highWater()const{return sequence;}
 void revoke(uint32_t){if(dir)remember(owner);dir=0;owner[0]=0;}
 int8_t direction(uint32_t now){if(dir&&(elapsed(now,renewed,1000)||elapsed(now,began,5000)))revoke(now);return dir;}
 uint32_t remaining(uint32_t now){if(!direction(now))return 0;uint32_t a=1000-uint32_t(now-renewed),b=5000-uint32_t(now-began);return a<b?a:b;}
 Reason move(const char* id,uint32_t seq,int8_t requested,uint32_t now){
  direction(now);if(!validId(id)||!requested)return Reason::InvalidArgument;if(closed(id))return Reason::MotionExpired;
  if(dir&&strcmp(id,owner)!=0)return Reason::MotionBusy;
  if(dir){if(!newerSequence(seq,sequence))return Reason::Superseded;}else{if(sequenced&&!newerSequence(seq,sequence))return Reason::Superseded;strcpy(owner,id);began=now;}
  sequenced=true;sequence=seq;renewed=now;dir=requested;return Reason::None;
 }
 Reason stop(const char* id,uint32_t seq,uint32_t now){
  direction(now);if(!validId(id))return Reason::InvalidArgument;
  if(dir&&strcmp(id,owner)==0){if(!newerSequence(seq,sequence))return Reason::Superseded;sequence=seq;revoke(now);}else {remember(id);if(!dir&&(!sequenced||newerSequence(seq,sequence))){sequence=seq;sequenced=true;}}return Reason::None;
 }
};
}
