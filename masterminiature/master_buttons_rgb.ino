DebouncedButton buttons[5];
void setupButtonsAndRGB() {
 for(uint8_t i=0;i<5;++i) {
  pinMode(cfg::BUTTONS[i],INPUT_PULLUP);
  buttons[i].update(digitalRead(cfg::BUTTONS[i])==LOW,millis());
 }
}
void handleButton(uint8_t button) {
 logEvent(static_cast<Event>(uint8_t(Event::Button1)+button-1));
 if(button==5) {
  if(!device.setCombined(!combined.engaged(),millis())) logEvent(audioReady?Event::PumpFailed:Event::AudioUnavailable);
  else logEvent(combined.engaged()?Event::PumpPending:Event::CombinedOff);
  applyCombinedRequests(); return;
 }
 if(!controller.press(button,millis())) logEvent(Event::AutoOwnsLights);
 else if(button==4) { device.motion.revoke(millis());stopMotor(); logEvent(controller.automatic?Event::AutoMode:Event::ManualMode); }
}
void handleButtons() {
 for(uint8_t i=0;i<5;++i)
  if(buttons[i].update(digitalRead(cfg::BUTTONS[i])==LOW,millis())) handleButton(i+1);
}
