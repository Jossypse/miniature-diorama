#pragma once
#include "wifi_controller.h"
#include "wifi_json.h"
#include "feedback.h"
#include "audio_monitor.h"
namespace mini {
struct DeviceSnapshot{
 uint32_t boot=1,revision=0,now=0,age=0,leaseRemaining=0,motionSequence=0;
 bool automatic=true,appOnline=false,slaveOnline=false,seen=false,relayPending=false;
 SensorState sensors;SensorHistory history;Outputs outputs;AudioState audio;EventLog events;
 uint8_t desired=0,confirmed=0,motorOwner=0;int8_t motor=0;const char* combined="off";
};
inline DeviceSnapshot makeDeviceSnapshot(WifiController& d,const Controller& c,const ReliableLink& l,const CombinedAction& b,const EventLog& e,bool app,uint32_t now){
 DeviceSnapshot s;s.boot=d.registry.boot();s.revision=d.revision;s.now=now;s.automatic=c.automatic;s.appOnline=app;s.slaveOnline=l.connected;
 s.seen=d.history.seen;s.age=now-d.history.receivedAt;s.sensors=d.sensors;s.history=d.history;s.outputs=c.out;s.audio=d.audio;s.events=e;
 s.desired=l.desired;s.confirmed=l.confirmed;s.relayPending=l.pending;s.motor=d.motor(now);s.motorOwner=d.motorOwner;s.leaseRemaining=d.motion.remaining(now);s.motionSequence=d.motion.highWater();
 s.combined=b.active?"active":(b.pending?"starting":(d.combinedFailed?"failed":"off"));return s;
}
inline std::string serializeStatus(const DeviceSnapshot& s){
 JsonDocument d;char boot[9];snprintf(boot,9,"%08lx",(unsigned long)s.boot);
 d["apiVersion"]=1;d["bootId"]=boot;d["revision"]=s.revision;d["uptimeMs"]=s.now;d["mode"]=s.automatic?"automatic":"manual";d["app"]["online"]=s.appOnline;
 auto slave=d["slave"].to<JsonObject>();slave["connected"]=s.slaveOnline;slave["fresh"]=s.sensors.fresh;if(s.slaveOnline&&s.seen)slave["ageMs"]=s.age;else slave["ageMs"]=nullptr;
 auto sensor=d["sensors"].to<JsonObject>();sensor["fresh"]=s.sensors.fresh;
 static const char* const colors[]={"NONE","RED","GREEN","BLUE","YELLOW","WHITE"};
 if(s.sensors.fresh){sensor["color"]=colors[unsigned(s.sensors.color)];sensor["ir"]=s.sensors.ir;sensor["joyY"]=s.sensors.joy;}
 else{sensor["color"]=nullptr;sensor["ir"]=nullptr;sensor["joyY"]=nullptr;}
 auto sound=sensor["sound"].to<JsonObject>();sound["sequence"]=s.history.soundSequence;
 if(s.sensors.fresh){sound["detected"]=s.history.detected(s.now);if(s.history.soundSeen)sound["lastTriggerAgeMs"]=uint32_t(s.now-s.history.lastSoundAt);else sound["lastTriggerAgeMs"]=nullptr;}
 else{sound["detected"]=nullptr;sound["lastTriggerAgeMs"]=nullptr;}
 auto out=d["outputs"].to<JsonObject>();out["fountain"]["enabled"]=s.outputs.fountain!=Color::None;out["fountain"]["color"]=colors[unsigned(s.outputs.fountain)];out["building"]["enabled"]=s.outputs.building;out["rgb"]["enabled"]=s.outputs.rgb;out["rgb"]["effect"]="cycle";
 out["relays"]["known"]=s.slaveOnline;out["relays"]["desired"]=s.desired;if(s.slaveOnline)out["relays"]["confirmed"]=s.confirmed;else out["relays"]["confirmed"]=nullptr;out["relays"]["pending"]=s.relayPending;
 auto a=d["audio"].to<JsonObject>();a["ready"]=s.audio.ready;a["requested"]=s.audio.requested;a["state"]=audioName(s.audio.phase);if(s.audio.track)a["trackId"]=s.audio.track;else a["trackId"]=nullptr;a["volumePercent"]=s.audio.volume;a["completionSequence"]=s.audio.completionSequence;if(s.audio.error==Reason::None)a["lastError"]=nullptr;else a["lastError"]=reasonName(s.audio.error);
 auto diag=a["diagnostics"].to<JsonObject>();const auto& ad=s.audio.diagnostics;
 diag["startupReady"]=ad.startupReady;diag["eventCount"]=ad.eventCount;diag["errorCount"]=ad.errorCount;
 if(ad.seen){diag["lastEventType"]=ad.lastType;diag["lastEventCommand"]=ad.lastCommand;diag["lastEventValue"]=ad.lastValue;diag["lastEventAtMs"]=ad.lastAt;}
 else{diag["lastEventType"]=nullptr;diag["lastEventCommand"]=nullptr;diag["lastEventValue"]=nullptr;diag["lastEventAtMs"]=nullptr;}
 if(ad.failed){diag["lastErrorType"]=ad.errorType;diag["lastErrorCommand"]=ad.errorCommand;diag["lastErrorValue"]=ad.errorValue;diag["lastErrorAtMs"]=ad.errorAt;diag["detail"]=dfPlayerErrorText(ad.errorType,ad.errorValue);}
 else{diag["lastErrorType"]=nullptr;diag["lastErrorCommand"]=nullptr;diag["lastErrorValue"]=nullptr;diag["lastErrorAtMs"]=nullptr;diag["detail"]=nullptr;}
 d["combined"]["state"]=s.combined;auto motor=d["motor"].to<JsonObject>();motor["direction"]=s.motor>0?"raising":(s.motor<0?"lowering":"stopped");motor["owner"]=s.motorOwner==1?"joystick":(s.motorOwner==2?"app":"none");motor["leaseRemainingMs"]=s.leaseRemaining;motor["sequence"]=s.motionSequence;motor["positionPercent"]=nullptr;
 auto cap=d["capabilities"].to<JsonObject>();cap["wifi"]=true;cap["bluetooth"]=false;cap["flagApp"]=true;cap["flagPosition"]=false;cap["audioPause"]=true;cap["audioVolume"]=true;cap["autoNarration"]=false;cap["phonePlayback"]=false;
 auto tracks=cap["tracks"].to<JsonArray>();for(int id=1;id<=2;++id){auto t=tracks.add<JsonObject>();t["id"]=id;t["title"]=id==1?"Track 1":"Track 2";}
 auto logs=d["logs"].to<JsonArray>();for(uint8_t i=0;i<s.events.size();++i){auto log=logs.add<JsonObject>();log["sequence"]=uint32_t(s.events.sequence-i);log["code"]=unsigned(s.events.at(i));log["message"]=eventText(s.events.at(i));}
 return jsonText(d);
}
}
