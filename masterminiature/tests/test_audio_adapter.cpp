#include <cassert>
#include <cstdio>
#include <deque>
#include "wifi_status.h"
#include "audio_monitor.h"
#include "master_config.h"
using namespace mini;
constexpr int SERIAL_8N1=0;
constexpr uint8_t TimeOut=0,WrongStack=1,DFPlayerCardInserted=2,DFPlayerCardRemoved=3,DFPlayerCardOnline=4,DFPlayerPlayFinished=5,DFPlayerError=6,DFPlayerFeedBack=11;
uint32_t testNow=100;uint32_t millis(){return testNow;}
struct HardwareSerial{explicit HardwareSerial(int){}void begin(int,int,uint8_t,uint8_t){}void write(const uint8_t*,size_t){}};
struct Frame{uint8_t type,command;uint16_t value;};
struct DFRobotDFPlayerMini{
 std::deque<Frame> frames;bool startupReady=true;int plays=0;
 void setTimeOut(int){}bool begin(HardwareSerial&,bool ack,bool){return !ack||startupReady;}
 void volume(uint8_t){}void stop(){}void pause(){}void start(){}void playMp3Folder(uint16_t){++plays;}
 bool available(){return !frames.empty();}
 uint8_t readType(){return frames.empty()?TimeOut:frames.front().type;}
 uint8_t readCommand(){return frames.empty()?0:frames.front().command;}
 uint16_t read(){if(frames.empty())return 0;auto value=frames.front().value;frames.pop_front();return value;}
};
struct SerialMock{template<class... Args>void printf(const char*,Args...){}void println(const char*){}}Serial;
Controller controller;ReliableLink masterLink(1);CombinedAction combined;WifiController device(controller,masterLink,combined,1);AudioMonitor audioMonitor;
bool audioReady=false,audioRequested=false;EventLog events;void logEvent(Event e){events.push(e);}
#include "master_audio.ino"
int main(){
 setupDFPlayer();assert(device.audio.ready);
 player.frames.push_back({DFPlayerError,0x40,5});serviceAudio();assert(device.audio.phase==AudioPhase::Error);
 auto snapshot=makeDeviceSnapshot(device,controller,masterLink,combined,events,false,testNow);
 JsonDocument json;deserializeJson(json,serializeStatus(snapshot));
 assert(json["audio"]["diagnostics"]["lastErrorValue"].as<int>()==5);
 assert(json["audio"]["diagnostics"]["lastErrorType"].as<int>()==DFPlayerError);
 assert(json["audio"]["diagnostics"]["lastErrorCommand"].as<int>()==0x40);
 player.frames.push_back({DFPlayerCardOnline,0x3f,2});++testNow;serviceAudio();
 snapshot=makeDeviceSnapshot(device,controller,masterLink,combined,events,false,testNow);deserializeJson(json,serializeStatus(snapshot));
 assert(json["audio"]["diagnostics"]["lastErrorValue"].as<int>()==5);
 puts("PASS actual audio adapter: DFPlayer error details survive later card events");
}
