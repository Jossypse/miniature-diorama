#pragma once
#include "reliable_link.h"
namespace mini {
class CombinedAction {
 uint8_t pump=0;uint32_t phaseAt=0;bool switching=false;
 bool requestPumps(ReliableLink& link,uint8_t mask,uint32_t now){
  if(!link.connected)return false;
  // Only the final mask is transmitted by the main loop, after this method returns.
  // Queue the outgoing pump OFF before the incoming pump ON.
  if(mask==1){link.requestRelay(2,false,now);return link.requestRelay(1,true,now);}
  link.requestRelay(1,false,now);return link.requestRelay(2,mask==2,now);
 }
public:
 uint32_t intervalMs=4000;
 bool pending=false,active=false,playRequested=false,stopRequested=false;
 bool engaged()const{return pending||active;}
 void cancel(ReliableLink& link,uint32_t now){
  const bool was=engaged();pending=active=playRequested=switching=false;pump=0;
  if(was){stopRequested=true;requestPumps(link,0,now);}
 }
 bool toggle(ReliableLink& link,bool audioReady,uint32_t now){
  if(engaged()){cancel(link,now);return true;}
  if(!audioReady||!requestPumps(link,1,now))return false;
  pump=1;phaseAt=now;switching=false;pending=true;playRequested=true;stopRequested=false;return true;
 }
 void tick(ReliableLink& link,uint32_t now,bool audioVerified=true){
  if(!engaged())return;
  if(!link.connected||link.failed){cancel(link,now);return;}
  if(pending){
   if(!link.pending&&audioVerified){if((link.confirmed&3)==pump){pending=false;active=true;phaseAt=now;}else cancel(link,now);}
   return;
  }
  if(!audioVerified){cancel(link,now);return;}
  if(switching){
   if(!link.pending){if((link.confirmed&3)!=pump){cancel(link,now);return;}switching=false;phaseAt=now;}
   return;
  }
  if(!link.pending&&elapsed(now,phaseAt,intervalMs)){
   pump=pump==1?2:1;
   if(requestPumps(link,pump,now))switching=true;else cancel(link,now);
  }
 }
};
}
