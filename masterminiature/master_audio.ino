HardwareSerial audioSerial(2);
DFRobotDFPlayerMini player;
void setupDFPlayer(){
 audioSerial.begin(9600,SERIAL_8N1,cfg::AUDIO_RX,cfg::AUDIO_TX);player.setTimeOut(200);
 audioReady=player.begin(audioSerial,true,true);device.audio.diagnostics.startupReady=audioReady;
 if(!audioReady){uint8_t type=player.readType(),command=player.readCommand();uint16_t value=player.read();device.audio.diagnostics.observe(type,command,value,millis(),true);Serial.printf("DFPlayer startup failure type=%u cmd=0x%02x value=%u detail=%s\n",type,command,value,dfPlayerErrorText(type,value));}
 player.begin(audioSerial,false,false);
 device.audio.ready=audioReady;if(audioReady){player.volume(25);player.stop();}
 Serial.println(audioReady?"DFPlayer ready":"DFPlayer unavailable; check SD/wiring");
}
bool playAudioTrack(int number){bool ok=device.play(uint16_t(number),millis());logEvent(ok?Event::AudioPlay:Event::AudioUnavailable);return ok;}
void stopAudio(){device.stopAudio(millis());logEvent(Event::AudioStop);}
void serviceAudio(){
 static uint32_t monitorGeneration=0;static bool finishCandidate=false;
 AudioEffect effect;uint8_t count=0;
 while(count++<4 && device.takeEffect(effect)){
  if(effect.op!=AudioOp::Volume && effect.generation!=device.audio.generation)continue;
  switch(effect.op){
   case AudioOp::Play:
    while(player.available()){player.readType();player.read();}
    player.playMp3Folder(effect.value);audioMonitor.start(millis());monitorGeneration=effect.generation;finishCandidate=false;break;
   case AudioOp::Resume:player.start();audioMonitor.start(millis());monitorGeneration=effect.generation;finishCandidate=false;break;
   case AudioOp::Pause:player.pause();audioMonitor.stop();finishCandidate=false;break;
   case AudioOp::Stop:player.stop();audioMonitor.stop();finishCandidate=false;break;
   case AudioOp::Volume:player.volume(uint8_t(effect.value));break;
  }
 }
 if(device.audio.phase==AudioPhase::Paused||device.audio.phase==AudioPhase::Stopped||device.audio.phase==AudioPhase::Error)audioMonitor.stop();
 // Read replies before evaluating deadline, so an on-time buffered reply is consumed.
 if(player.available()){
  uint8_t type=player.readType(),command=player.readCommand();uint16_t value=player.read();
  const bool isError=type==DFPlayerError||type==DFPlayerCardRemoved||type==TimeOut||type==WrongStack;
  device.audio.diagnostics.observe(type,command,value,millis(),isError);
  if(type==DFPlayerFeedBack&&command==0x42&&monitorGeneration==device.audio.generation){
   if((value&0xff)==1){audioMonitor.response(true,millis());device.playing(millis());finishCandidate=false;}
   else if((value&0xff)==0&&finishCandidate&&device.audio.phase==AudioPhase::Playing){device.finished(device.audio.track,millis());audioMonitor.stop();finishCandidate=false;logEvent(Event::AudioStop);}
  }else if(type==DFPlayerPlayFinished&&value==device.audio.track&&device.audio.phase==AudioPhase::Playing){finishCandidate=true;}
  else if(type==DFPlayerError||type==DFPlayerCardRemoved||type==TimeOut||type==WrongStack){
   Serial.printf("DFPlayer error type=%u cmd=0x%02x value=%u detail=%s\n",type,command,value,dfPlayerErrorText(type,value));logEvent(Event::AudioError);device.audioError(Reason::AudioUnavailable,millis());audioMonitor.stop();
  }else if(type==DFPlayerCardOnline||type==DFPlayerCardInserted)device.audio.ready=true;
 }
 audioMonitor.tick(millis());
 if(audioMonitor.failed){device.audioError(Reason::AudioTimeout,millis());audioMonitor.stop();logEvent(Event::AudioError);}
 if(audioMonitor.probeDue(millis())){uint8_t q[10];makeStateQuery(q);audioSerial.write(q,sizeof q);}
 audioReady=device.audio.ready;audioRequested=device.audio.requested;
}
