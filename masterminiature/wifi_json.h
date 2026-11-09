#pragma once
#include "wifi_api.h"
#include <ArduinoJson.h>
namespace mini {
inline std::string jsonText(const JsonDocument& d){std::string out;serializeJson(d,out);return out;}
inline std::string serializeError(Reason r){JsonDocument d;d["apiVersion"]=1;d["error"]["code"]=reasonName(r);d["error"]["message"]=reasonName(r);return jsonText(d);}
inline std::string serializeResult(const CommandResult& r,uint32_t boot){
 JsonDocument d;char b[9];snprintf(b,9,"%08lx",(unsigned long)boot);d["apiVersion"]=1;d["bootId"]=b;d["id"]=r.id;
 d["status"]=r.status==CommandStatus::Pending?"pending":(r.status==CommandStatus::Applied?"applied":"failed");
 if(r.reason==Reason::None)d["reason"]=nullptr;else d["reason"]=reasonName(r.reason);
 d["acceptedAtMs"]=r.acceptedAt;if(r.status==CommandStatus::Pending)d["finishedAtMs"]=nullptr;else d["finishedAtMs"]=r.finishedAt;return jsonText(d);
}
inline bool decodeApiCommand(const char* text,size_t length,ApiCommand& c,ApiError& e){
 c=ApiCommand{};e.reason=Reason::BadRequest;if(!text||length>512)return false;
 JsonDocument d;if(deserializeJson(d,text,length,DeserializationOption::NestingLimit(4)))return false;
 auto o=d.as<JsonObjectConst>();if(o.size()!=4||!o["id"].is<const char*>()||!o["bootId"].is<const char*>()||!o["action"].is<const char*>()||!o["args"].is<JsonObjectConst>())return false;
 const char* id=o["id"];if(!validId(id)){e.reason=Reason::InvalidId;return false;}strcpy(c.id,id);
 const char* boot=o["bootId"];if(strlen(boot)!=8)return false;
 for(int i=0;i<8;++i){char ch=boot[i];if(!((ch>='0'&&ch<='9')||(ch>='a'&&ch<='f')))return false;c.boot=(c.boot<<4)|uint32_t(ch<='9'?ch-'0':ch-'a'+10);}
 const char* action=o["action"];auto a=o["args"].as<JsonObjectConst>();e.reason=Reason::InvalidArgument;
 if(strcmp(action,"mode.set")==0){if(a.size()!=1||!a["automatic"].is<bool>())return false;c.action=ApiAction::Mode;c.enabled=a["automatic"];}
 else if(strcmp(action,"light.set")==0){
  if(a.size()!=2||!a["target"].is<const char*>()||!a["enabled"].is<bool>())return false;
  const char* t=a["target"];c.number=strcmp(t,"fountain")==0?1:(strcmp(t,"rgb")==0?2:(strcmp(t,"building")==0?3:0));if(!c.number)return false;c.action=ApiAction::Light;c.enabled=a["enabled"];
 }else if(strcmp(action,"relay.set")==0){if(a.size()!=2||!a["relay"].is<uint32_t>()||!a["enabled"].is<bool>())return false;c.action=ApiAction::Relay;c.number=a["relay"];c.enabled=a["enabled"];if(c.number<1||c.number>2)return false;}
 else if(strcmp(action,"combined.set")==0){if(a.size()!=1||!a["enabled"].is<bool>())return false;c.action=ApiAction::Combined;c.enabled=a["enabled"];}
 else if(strcmp(action,"audio.play")==0){if(a.size()!=1||!a["trackId"].is<uint32_t>())return false;c.action=ApiAction::Play;c.number=a["trackId"];if(c.number<1||c.number>2)return false;}
 else if(strcmp(action,"audio.volume")==0){if(a.size()!=1||!a["percent"].is<uint32_t>())return false;c.action=ApiAction::Volume;c.number=a["percent"];if(c.number>100)return false;}
 else if(strcmp(action,"audio.pause")==0||strcmp(action,"audio.resume")==0||strcmp(action,"audio.stop")==0){if(a.size())return false;c.action=strcmp(action,"audio.pause")==0?ApiAction::Pause:(strcmp(action,"audio.resume")==0?ApiAction::Resume:ApiAction::Stop);}
 else if(strcmp(action,"flag.move")==0||strcmp(action,"flag.stop")==0){
  const bool move=strcmp(action,"flag.move")==0;if(a.size()!=(move?3U:2U)||!a["leaseId"].is<const char*>()||!validId(a["leaseId"])||!a["sequence"].is<uint32_t>())return false;
  strcpy(c.lease,a["leaseId"]);c.sequence=a["sequence"];c.action=move?ApiAction::FlagMove:ApiAction::FlagStop;
  if(move){if(!a["direction"].is<const char*>())return false;const char* dir=a["direction"];c.direction=strcmp(dir,"raising")==0?1:(strcmp(dir,"lowering")==0?-1:0);if(!c.direction)return false;}
 }else{e.reason=Reason::BadRequest;return false;}
 e.reason=Reason::None;return true;
}
inline ApiReply handleApiRequest(const ApiHttpRequest& req,CommandRegistry& registry){
 ApiReply out;const std::string prefix="/api/v1/commands/";
 if(req.method=="GET"&&req.path.compare(0,prefix.size(),prefix)==0){
  auto id=req.path.substr(prefix.size());CommandResult r;if(!validId(id.c_str())){out.code=400;out.body=serializeError(Reason::InvalidId);return out;}
  if(!registry.lookup(id.c_str(),r)){out.code=404;out.body=serializeError(Reason::UnknownId);}else{out.code=200;out.body=serializeResult(r,registry.boot());}return out;
 }
 if(req.method!="POST"||req.path!="/api/v1/commands"){out.code=404;out.body=serializeError(Reason::UnknownId);return out;}
 ApiError e;if(!decodeApiCommand(req.body.c_str(),req.body.size(),out.command,e)){out.code=reasonHttp(e.reason);out.body=serializeError(e.reason);return out;}
 // Existing IDs are looked up before mode/hardware admission checks so polling a duplicate is stable.
 CommandResult existing;bool duplicate=registry.lookup(out.command.id,existing);
 Reason guard=Reason::None;
 if(out.command.boot!=registry.boot())guard=Reason::BootMismatch;
 else if(!duplicate){
  if((out.command.action==ApiAction::Light||out.command.action==ApiAction::FlagMove)&&req.automatic)guard=Reason::ModeRejected;
  else if((out.command.action==ApiAction::Relay||out.command.action==ApiAction::Combined||out.command.action==ApiAction::FlagMove)&&!req.slaveOnline)guard=Reason::SlaveOffline;
  else if((out.command.action==ApiAction::Play||out.command.action==ApiAction::Resume||(out.command.action==ApiAction::Combined&&out.command.enabled))&&!req.audioReady)guard=Reason::AudioUnavailable;
 }
 if(guard!=Reason::None){out.code=reasonHttp(guard);out.body=serializeError(guard);return out;}
 auto admission=registry.admit(out.command,req.now);out.code=admission.code;out.enqueue=admission.enqueue;out.body=admission.reason==Reason::None?serializeResult(admission.result,registry.boot()):serializeError(admission.reason);return out;
}
}
