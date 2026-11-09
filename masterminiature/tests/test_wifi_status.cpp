#include <cassert>
#include <cstdio>
#include "wifi_status.h"
using namespace mini;
int main(){
 Controller c;ReliableLink l(1);CombinedAction b;WifiController d(c,l,b,0xa1b2c3d4);EventLog e;e.push(Event::Boot);
 auto s=makeDeviceSnapshot(d,c,l,b,e,false,2000);auto json=serializeStatus(s);JsonDocument value;assert(!deserializeJson(value,json));
 assert(value["apiVersion"]==1);assert(value["bootId"]=="a1b2c3d4");assert(value["sensors"]["ir"].isNull());assert(value["outputs"]["relays"]["confirmed"].isNull());
 assert(value["capabilities"]["tracks"].size()==2);assert(value["motor"]["positionPercent"].isNull());
 d.audio.ready=true;assert(d.play(1,2100));d.playing(2200);d.tick(2200);assert(d.pause(2300));d.tick(5000);assert(d.audio.phase==AudioPhase::Paused);
 assert(d.resume(5001));assert(d.audio.phase==AudioPhase::Starting);d.playing(5100);d.finished(2,5200);assert(d.audio.completionSequence==0);d.finished(1,5200);d.finished(1,5300);assert(d.audio.completionSequence==1);
 assert(d.volume(50));AudioEffect effect;bool found=false;while(d.takeEffect(effect))if(effect.op==AudioOp::Volume){assert(effect.value==15);found=true;}assert(found);
 puts("PASS status/audio: unknown values, capabilities, pause/resume, completion and volume");
}
