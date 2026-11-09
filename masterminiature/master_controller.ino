void logEvent(Event event) { events.push(event);Serial.println(eventText(event)); }
void serviceController() {
 static int8_t lastMotor=0;static bool lastApp=false,lastCombined=false;
 readings.fresh=masterLink.connected && !elapsed(millis(),lastTelemetry,STALE_MS);
 const bool soundReceived=readings.sound;
 controller.tick(millis(),readings);readings.sound=false;
 static bool soundLogStarted=false,soundSinceLog=false,lastBuilding=false,lastSoundFresh=false,lastSoundAuto=false;
 static uint32_t lastSoundLog=0;
 soundSinceLog=soundSinceLog || soundReceived;
 const bool soundChanged=controller.out.building!=lastBuilding || readings.fresh!=lastSoundFresh || controller.automatic!=lastSoundAuto;
 if(!soundLogStarted || ((soundSinceLog || soundChanged) && elapsed(millis(),lastSoundLog,100)) || elapsed(millis(),lastSoundLog,2000)){
  soundLogStarted=true;lastSoundLog=millis();lastBuilding=controller.out.building;
  lastSoundFresh=readings.fresh;lastSoundAuto=controller.automatic;
  const char* reason=!controller.automatic?"MANUAL_BUTTON_OR_WEB":(!readings.fresh?"NO_FRESH_TELEMETRY":(controller.out.building?"SOUND_HOLD_2000MS":"NO_SOUND"));
  Serial.printf("[Sound master] receivedSinceLog=%s telemetry=%s ageMs=%lu mode=%s building=%s reason=%s stripGPIO=%u\n",
   soundSinceLog?"TRIGGER":"NONE",readings.fresh?"FRESH":"STALE_OR_MISSING",
   (unsigned long)(millis()-lastTelemetry),controller.automatic?"AUTO":"MANUAL",
   controller.out.building?"ON":"OFF",reason,unsigned(cfg::BUILDING));
  soundSinceLog=false;
 }
 static bool irLogStarted=false,lastIr=false,lastFresh=false,lastAuto=false,lastRgb=false;
 static uint32_t lastIrLog=0;
 const bool irChanged=readings.ir!=lastIr || readings.fresh!=lastFresh || controller.automatic!=lastAuto || controller.out.rgb!=lastRgb;
 if(!irLogStarted || (irChanged && elapsed(millis(),lastIrLog,100)) || elapsed(millis(),lastIrLog,2000)){
  irLogStarted=true;lastIrLog=millis();lastIr=readings.ir;lastFresh=readings.fresh;lastAuto=controller.automatic;lastRgb=controller.out.rgb;
  const char* reason=!controller.automatic?"MANUAL_BUTTON_OR_WEB":(!readings.fresh?"NO_FRESH_TELEMETRY":(readings.ir?"IR_DETECTED":"NO_OBJECT"));
  Serial.printf("[IR master] received=%s telemetry=%s ageMs=%lu mode=%s RGB=%s reason=%s\n",
   readings.ir?"DETECTED":"CLEAR",readings.fresh?"FRESH":"STALE_OR_MISSING",
   (unsigned long)(millis()-lastTelemetry),controller.automatic?"AUTO":"MANUAL",
   controller.out.rgb?"ON":"OFF",reason);
 }
 applyLighting(controller.out);
 int8_t logicalMotor=device.motor(millis());
 int8_t motor=cfg::MOTOR_REVERSED?-logicalMotor:logicalMotor;
 if(motor!=lastMotor) {
  if(motor>0)motorForward(cfg::MOTOR_SPEED);else if(motor<0)motorReverse(cfg::MOTOR_SPEED);else stopMotor();
  lastMotor=motor;logEvent(motor>0?Event::MotorUp:(motor<0?Event::MotorDown:Event::MotorStop));
 }
 bool app=appPresence.online(millis());if(app!=lastApp){lastApp=app;logEvent(app?Event::AppOnline:Event::AppOffline);}
 if(combined.active!=lastCombined){lastCombined=combined.active;if(lastCombined)logEvent(Event::CombinedOn);}
}
void applyCombinedRequests() {
 // Combined audio/relay intent is serviced by the shared WifiController state owner.
}
