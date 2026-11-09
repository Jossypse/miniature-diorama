void selectColorFilter(uint8_t channel) {
 // TCS3200 red LOW/LOW, green HIGH/HIGH, blue LOW/HIGH.
 digitalWrite(cfg::TCS_S2,channel==1?HIGH:LOW);digitalWrite(cfg::TCS_S3,channel==0?LOW:HIGH);
}
void setupSensors() {
 pinMode(cfg::JOY,INPUT);pinMode(cfg::IR,INPUT);pinMode(cfg::SOUND,INPUT);
 pinMode(cfg::TCS_S2,OUTPUT);pinMode(cfg::TCS_S3,OUTPUT);pinMode(cfg::TCS_OUT,INPUT);
 analogReadResolution(12);selectColorFilter(0);
}
void serviceSensors() {
 static uint8_t channel=0;static uint32_t selectedAt=0,lastDebug=0;
 static uint32_t pulses[3]={0,0,0};static bool selected=false;
 sensors.joy=uint16_t(analogRead(cfg::JOY));
 const int irRaw=digitalRead(cfg::IR);
 sensors.ir=(irRaw==(cfg::IR_ACTIVE_HIGH?HIGH:LOW));
 // Print transitions (at most 10/s) plus a heartbeat even when the input is stuck.
 static int lastIrLogged=-1;static uint32_t lastIrLog=0;
 if(lastIrLogged<0 || (irRaw!=lastIrLogged && elapsed(millis(),lastIrLog,100)) || elapsed(millis(),lastIrLog,2000)){
  lastIrLogged=irRaw;lastIrLog=millis();
  Serial.printf("[IR slave] GPIO=%u raw=%s active=%s detected=%s masterLink=%s\n",
   unsigned(cfg::IR),irRaw==HIGH?"HIGH":"LOW",cfg::IR_ACTIVE_HIGH?"HIGH":"LOW",
   sensors.ir?"YES":"NO",slaveLink.connected?"ONLINE":"OFFLINE");
 }
 const int soundRaw=digitalRead(cfg::SOUND);
 const bool soundActive=(soundRaw==(cfg::SOUND_ACTIVE_HIGH?HIGH:LOW));
 sensors.sound=sensors.sound || soundActive;
 // Retain short rising events for the next log even if the input has gone quiet.
 static int lastSoundLogged=-1;static bool lastSoundSample=false,soundSinceLog=false;
 static uint32_t lastSoundLog=0;
 if(soundActive && !lastSoundSample)soundSinceLog=true;
 lastSoundSample=soundActive;
 if(lastSoundLogged<0 || ((soundRaw!=lastSoundLogged || soundSinceLog) && elapsed(millis(),lastSoundLog,100)) || elapsed(millis(),lastSoundLog,2000)){
  lastSoundLogged=soundRaw;lastSoundLog=millis();
  Serial.printf("[Sound slave] GPIO=%u raw=%s active=%s triggered=%s pulseSinceLog=%s latchedForTelemetry=%s masterLink=%s\n",
   unsigned(cfg::SOUND),soundRaw==HIGH?"HIGH":"LOW",cfg::SOUND_ACTIVE_HIGH?"HIGH":"LOW",
   soundActive?"YES":"NO",soundSinceLog?"YES":"NO",sensors.sound?"YES":"NO",
   slaveLink.connected?"ONLINE":"OFFLINE");
  soundSinceLog=false;
 }
 if(!selected){selectColorFilter(channel);selectedAt=millis();selected=true;return;}
 if(!elapsed(millis(),selectedAt,5))return;
 // At most 3 ms per loop, one filter at a time. Missing pulse returns zero.
 pulses[channel]=pulseIn(cfg::TCS_OUT,LOW,cfg::COLOR_PULSE_TIMEOUT_US);
 selected=false;++channel;
 if(channel==3){
  channel=0;sensors.color=classifyColor({pulses[0],pulses[1],pulses[2]},colorCalibration);
  if(elapsed(millis(),lastDebug,1000)){
   lastDebug=millis();Serial.printf("TCS us R=%lu G=%lu B=%lu color=%u\n",(unsigned long)pulses[0],(unsigned long)pulses[1],(unsigned long)pulses[2],unsigned(sensors.color));
  }
 }
}
