#pragma once
#include "wifi_api.h"
#include "master_controller.h"
#include "combined_action.h"
#include "motion_lease.h"
namespace mini {
struct SensorHistory{
 bool seen=false,soundSeen=false;uint32_t receivedAt=0,lastSoundAt=0,soundSequence=0;
 void observe(const Packet& p,uint32_t at){seen=true;receivedAt=at;if(p.sound){soundSeen=true;lastSoundAt=at;++soundSequence;}}
 bool detected(uint32_t now)const{return soundSeen&&!elapsed(now,lastSoundAt,2000);}
};
class WifiController{
 Controller& lights;ReliableLink& link;CombinedAction& combined;
 AudioEffect effects[8]{};uint8_t effectHead=0,effectCount=0;
 bool effect(AudioOp op,uint16_t value=0){if(effectCount==8){if(op!=AudioOp::Stop)return false;effectHead=0;effectCount=0;effects[effectCount++]={AudioOp::Volume,uint16_t((unsigned(audio.volume)*30+50)/100),audio.generation};}effects[(effectHead+effectCount)%8]={op,value,audio.generation};++effectCount;return true;}
 void supersedeRelayChanges(uint32_t now){
  for(auto& r:registry.records)if(r.used&&r.executed&&r.result.status==CommandStatus::Pending&&(r.wait&1)&&((link.desired&r.concern)!=r.desired))registry.finish(r.command.id,CommandStatus::Failed,Reason::Superseded,now);
 }
 void detachCombined(uint32_t now){if(combined.engaged()){combined.cancel(link,now);supersedeRelayChanges(now);combined.stopRequested=false;combined.playRequested=false;}}
public:
 CommandRegistry registry;AudioState audio;SensorHistory history;MotionLease motion;SensorState sensors;
 uint32_t revision=0;uint8_t motorOwner=0;bool combinedFailed=false;
 WifiController(Controller& c,ReliableLink& l,CombinedAction& b,uint32_t boot):lights(c),link(l),combined(b),registry(boot){}
 bool takeEffect(AudioEffect& e){if(!effectCount)return false;e=effects[effectHead];effectHead=uint8_t((effectHead+1)%8);--effectCount;return true;}
 bool play(uint16_t track,uint32_t now,bool independent=true){
  if(!audio.ready||track<1||track>2||effectCount==8)return false;
  if(independent)detachCombined(now);++audio.generation;audio.track=track;audio.startedAt=now;audio.phase=AudioPhase::Starting;audio.requested=true;audio.error=Reason::None;return effect(AudioOp::Play,track);
 }
 bool pause(uint32_t now){
  if(!audio.ready||!audio.track||audio.phase==AudioPhase::Stopped||audio.phase==AudioPhase::Error||effectCount==8)return false;if(audio.phase==AudioPhase::Paused)return true;
  detachCombined(now);++audio.generation;audio.phase=AudioPhase::Paused;audio.requested=false;return effect(AudioOp::Pause);
 }
 bool resume(uint32_t now){if(audio.phase==AudioPhase::Playing||audio.phase==AudioPhase::Starting)return true;if(!audio.ready||audio.phase!=AudioPhase::Paused||effectCount==8)return false;detachCombined(now);++audio.generation;audio.startedAt=now;audio.phase=AudioPhase::Starting;audio.requested=true;audio.error=Reason::None;return effect(AudioOp::Resume);}
 void stopAudio(uint32_t now){detachCombined(now);if(audio.phase==AudioPhase::Stopped)return;++audio.generation;audio.phase=AudioPhase::Stopped;audio.requested=false;audio.error=Reason::None;effect(AudioOp::Stop);}
 bool volume(uint8_t percent){if(!audio.ready||percent>100||effectCount==8)return false;audio.volume=percent;return effect(AudioOp::Volume,uint16_t((unsigned(percent)*30+50)/100));}
 bool setCombined(bool on,uint32_t now){
  if(on){if(combined.engaged())return true;if(!audio.ready||!link.connected||effectCount==8)return false;
   if(!combined.toggle(link,true,now))return false;supersedeRelayChanges(now);combined.playRequested=false;combined.stopRequested=false;combinedFailed=false;return play(1,now,false);
  }
  if(combined.engaged()){combined.cancel(link,now);supersedeRelayChanges(now);combined.stopRequested=false;stopAudio(now);}return true;
 }
 bool setRelay(uint8_t relay,bool on,uint32_t now){if(!link.connected)return false;if(combined.engaged()){detachCombined(now);stopAudio(now);}bool ok=link.requestRelay(relay,on,now);if(ok)supersedeRelayChanges(now);return ok;}
 void playing(uint32_t now){if(audio.phase==AudioPhase::Starting||audio.phase==AudioPhase::Playing){audio.phase=AudioPhase::Playing;audio.error=Reason::None;(void)now;}}
 void audioError(Reason reason,uint32_t now){detachCombined(now);combinedFailed=true;++audio.generation;audio.phase=AudioPhase::Error;audio.requested=false;audio.error=reason;audio.ready=false;effect(AudioOp::Stop);}
 void finished(uint16_t track,uint32_t now){if(audio.phase!=AudioPhase::Playing||track!=audio.track)return;detachCombined(now);++audio.completionSequence;audio.phase=AudioPhase::Stopped;audio.requested=false;}
 int8_t motor(uint32_t now){
  const int8_t joystick=lights.joystickDirection(now,sensors);
  if(lights.automatic||!sensors.fresh||sensors.joy>4095){motion.revoke(now);motorOwner=0;return 0;}
  if(joystick){motion.revoke(now);motorOwner=1;return joystick;}
  auto app=motion.direction(now);motorOwner=app?2:0;return app;
 }
 Reason execute(const ApiCommand& cmd,uint32_t now){
  auto* record=registry.record(cmd.id);if(record&&record->result.status!=CommandStatus::Pending)return record->result.reason;if(record)record->executed=true;
  Reason error=Reason::None;uint8_t wait=0,concern=0;bool wasCombined=combined.engaged();
  if(cmd.boot!=registry.boot())error=Reason::BootMismatch;
  else switch(cmd.action){
   case ApiAction::Mode:if(lights.automatic!=cmd.enabled)motion.revoke(now);lights.setMode(cmd.enabled,now);break;
   case ApiAction::Light:if(!lights.setLight(uint8_t(cmd.number),cmd.enabled))error=Reason::ModeRejected;break;
   case ApiAction::Relay:if(!setRelay(uint8_t(cmd.number),cmd.enabled,now))error=Reason::SlaveOffline;else{wait=1;concern=uint8_t(1U<<(cmd.number-1));}break;
   case ApiAction::Combined:
    if(!setCombined(cmd.enabled,now))error=!link.connected?Reason::SlaveOffline:Reason::AudioUnavailable;
    else{if(link.pending&&(wasCombined||cmd.enabled)){wait|=1;concern=3;}if(cmd.enabled&&audio.phase==AudioPhase::Starting)wait|=2;}break;
   case ApiAction::Play:if(!play(uint16_t(cmd.number),now))error=Reason::AudioUnavailable;else wait=2;break;
   case ApiAction::Pause:if(!pause(now))error=Reason::AudioUnavailable;break;
   case ApiAction::Resume:if(!resume(now))error=Reason::AudioUnavailable;else if(audio.phase==AudioPhase::Starting)wait=2;break;
   case ApiAction::Stop:stopAudio(now);break;
   case ApiAction::Volume:if(!volume(uint8_t(cmd.number)))error=Reason::AudioUnavailable;break;
   case ApiAction::FlagMove:
    if(lights.automatic)error=Reason::ModeRejected;else if(!sensors.fresh||sensors.joy>4095)error=Reason::SlaveOffline;
    else if(lights.joystickDirection(now,sensors))error=Reason::JoystickOverride;
    else error=motion.move(cmd.lease,cmd.sequence,cmd.direction,now);break;
   case ApiAction::FlagStop:error=motion.stop(cmd.lease,cmd.sequence,now);break;
  }
  if(wasCombined&&!combined.engaged()&&link.pending){wait|=1;concern|=3;}
  if(record){record->wait=wait;record->concern=concern;record->desired=link.desired&concern;record->audioGeneration=audio.generation;}
  if(error!=Reason::None)registry.finish(cmd.id,CommandStatus::Failed,error,now);
  else if(!wait)registry.finish(cmd.id,CommandStatus::Applied,Reason::None,now);
  ++revision;return error;
 }
 void tick(uint32_t now){
  const bool was=combined.engaged();combined.tick(link,now,audio.phase==AudioPhase::Playing);
  if(combined.stopRequested){combined.stopRequested=false;stopAudio(now);if(was)combinedFailed=true;}
  if(combined.playRequested){combined.playRequested=false;play(1,now,false);}
  for(auto& r:registry.records){
   if(!r.used||r.result.status!=CommandStatus::Pending)continue;
   if(!r.executed){if(elapsed(now,r.result.acceptedAt,2000))registry.finish(r.command.id,CommandStatus::Failed,Reason::CommandTimeout,now);continue;}
   Reason fail=Reason::None;bool waiting=false;
   if(r.wait&1){if(!link.connected||link.failed)fail=Reason::LinkLost;else if((link.desired&r.concern)!=r.desired)fail=Reason::Superseded;else if(link.pending||(link.confirmed&r.concern)!=r.desired)waiting=true;}
   if(r.wait&2){if(audio.phase==AudioPhase::Error)fail=audio.error;else if(audio.generation!=r.audioGeneration)fail=Reason::Superseded;else if(audio.phase!=AudioPhase::Playing)waiting=true;}
   if(fail==Reason::None&&elapsed(now,r.result.acceptedAt,2000))fail=Reason::CommandTimeout;
   if(fail!=Reason::None)registry.finish(r.command.id,CommandStatus::Failed,fail,now);
   else if(!waiting)registry.finish(r.command.id,CommandStatus::Applied,Reason::None,now);
  }
 }
};
}
