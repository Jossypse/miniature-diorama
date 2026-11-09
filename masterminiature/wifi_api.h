#pragma once
#include "miniature_protocol.h"
#include <string>
#include <ctype.h>
namespace mini {
enum class ApiAction:uint8_t { Mode,Light,Relay,Combined,Play,Pause,Resume,Stop,Volume,FlagMove,FlagStop };
enum class Reason:uint8_t { None,BadRequest,InvalidId,BootMismatch,ModeRejected,InvalidArgument,Unsupported,SlaveOffline,AudioUnavailable,QueueFull,Superseded,LinkLost,AudioTimeout,CommandTimeout,MotionExpired,JoystickOverride,MotionLimit,MotionBusy,UnknownId,Internal };
inline const char* reasonName(Reason r){
 static const char* const names[]={"","BAD_REQUEST","INVALID_ID","BOOT_MISMATCH","MODE_REJECTED","INVALID_ARGUMENT","UNSUPPORTED","SLAVE_OFFLINE","AUDIO_UNAVAILABLE","QUEUE_FULL","SUPERSEDED","LINK_LOST","AUDIO_TIMEOUT","COMMAND_TIMEOUT","MOTION_EXPIRED","JOYSTICK_OVERRIDE","MOTION_LIMIT","MOTION_BUSY","UNKNOWN_ID","INTERNAL"};
 return names[unsigned(r)];
}
inline int reasonHttp(Reason r){
 switch(r){case Reason::None:return 200;case Reason::InvalidArgument:case Reason::Unsupported:return 422;
 case Reason::ModeRejected:case Reason::BootMismatch:case Reason::Superseded:case Reason::MotionExpired:case Reason::JoystickOverride:case Reason::MotionLimit:case Reason::MotionBusy:return 409;
 case Reason::SlaveOffline:case Reason::AudioUnavailable:case Reason::QueueFull:case Reason::LinkLost:return 503;
 case Reason::UnknownId:return 404;default:return 400;}
}
inline bool validId(const char* id){if(!id)return false;size_t n=strlen(id);if(!n || n>48)return false;for(size_t i=0;i<n;++i){char c=id[i];if(!((c>='a'&&c<='z')||(c>='A'&&c<='Z')||(c>='0'&&c<='9')||c=='_'||c=='-'))return false;}return true;}
struct ApiCommand {
 char id[49]{},lease[49]{};uint32_t boot=0,sequence=0,number=0;ApiAction action=ApiAction::Stop;bool enabled=false;int8_t direction=0;
 bool samePayload(const ApiCommand& b)const{return boot==b.boot&&action==b.action&&number==b.number&&sequence==b.sequence&&enabled==b.enabled&&direction==b.direction&&strcmp(lease,b.lease)==0;}
};
struct ApiError{Reason reason=Reason::BadRequest;};
enum class CommandStatus:uint8_t { Pending,Applied,Failed };
struct CommandResult{char id[49]{};CommandStatus status=CommandStatus::Pending;Reason reason=Reason::None;uint32_t acceptedAt=0,finishedAt=0;};
struct CommandRecord{
 bool used=false,executed=false;ApiCommand command;CommandResult result;
 uint8_t wait=0,concern=0,desired=0;uint32_t audioGeneration=0;
};
struct Admission{int code=503;bool enqueue=false;Reason reason=Reason::QueueFull;CommandResult result;};
class CommandRegistry {
 uint32_t boot_;
public:
 CommandRecord records[16];
 explicit CommandRegistry(uint32_t boot=1):boot_(boot){}
 uint32_t boot()const{return boot_;}
 Admission admit(const ApiCommand& c,uint32_t now){
  if(c.boot!=boot_)return {409,false,Reason::BootMismatch,{}};
  if(!validId(c.id))return {400,false,Reason::InvalidId,{}};
  CommandRecord* slot=nullptr;CommandRecord* oldest=nullptr;uint32_t age=0;
  for(auto& r:records){
   if(r.used&&strcmp(c.id,r.command.id)==0){if(!c.samePayload(r.command))return {409,false,Reason::Superseded,{}};return {r.result.status==CommandStatus::Pending?202:200,false,Reason::None,r.result};}
   if(!r.used&&!slot)slot=&r;
   if(r.used&&r.result.status!=CommandStatus::Pending&&(!oldest||uint32_t(now-r.result.acceptedAt)>age)){oldest=&r;age=now-r.result.acceptedAt;}
  }
  if(!slot)slot=oldest;if(!slot)return {};
  *slot=CommandRecord{};slot->used=true;slot->command=c;strcpy(slot->result.id,c.id);slot->result.acceptedAt=now;
  return {202,true,Reason::None,slot->result};
 }
 CommandRecord* record(const char* id){for(auto& r:records)if(r.used&&strcmp(id,r.command.id)==0)return &r;return nullptr;}
 bool lookup(const char* id,CommandResult& out)const{for(const auto& r:records)if(r.used&&strcmp(id,r.command.id)==0){out=r.result;return true;}return false;}
 bool finish(const char* id,CommandStatus s,Reason reason,uint32_t now){auto* r=record(id);if(!r||r->result.status!=CommandStatus::Pending)return false;r->result.status=s;r->result.reason=reason;r->result.finishedAt=now;return true;}
};
enum class AudioPhase:uint8_t{Stopped,Starting,Playing,Paused,Error};
inline const char* audioName(AudioPhase p){static const char* const n[]={"stopped","starting","playing","paused","error"};return n[unsigned(p)];}
enum class AudioOp:uint8_t { Play,Pause,Resume,Stop,Volume };
struct AudioEffect{AudioOp op=AudioOp::Stop;uint16_t value=0;uint32_t generation=0;};
struct AudioDiagnostics{
 bool startupReady=false,seen=false,failed=false;
 uint8_t lastType=0,lastCommand=0,errorType=0,errorCommand=0;uint16_t lastValue=0,errorValue=0;
 uint32_t lastAt=0,errorAt=0,eventCount=0,errorCount=0;
 void observe(uint8_t type,uint8_t command,uint16_t value,uint32_t now,bool error){
  seen=true;lastType=type;lastCommand=command;lastValue=value;lastAt=now;++eventCount;
  if(error){failed=true;errorType=type;errorCommand=command;errorValue=value;errorAt=now;++errorCount;}
 }
};
struct AudioState{AudioDiagnostics diagnostics;bool ready=false,requested=false;AudioPhase phase=AudioPhase::Stopped;uint16_t track=0;uint8_t volume=83;uint32_t generation=0,completionSequence=0,startedAt=0;Reason error=Reason::None;};
struct ApiReply{int code=400;std::string body;bool enqueue=false;ApiCommand command;};
struct ApiHttpRequest{std::string method,path,body;uint32_t now=0;bool automatic=true,slaveOnline=false,audioReady=false;};
}
