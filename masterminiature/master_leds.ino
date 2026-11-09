Adafruit_NeoPixel fountainStrip(cfg::FOUNTAIN_COUNT,cfg::FOUNTAIN,NEO_GRB+NEO_KHZ800);
Adafruit_NeoPixel buildingStrip(cfg::BUILDING_COUNT,cfg::BUILDING,NEO_GRB+NEO_KHZ800);
void setRgbColor(int r,int g,int b) {
 analogWrite(cfg::RGB_R,cfg::RGB_COMMON_ANODE?255-r:r);
 analogWrite(cfg::RGB_G,cfg::RGB_COMMON_ANODE?255-g:g);
 analogWrite(cfg::RGB_B,cfg::RGB_COMMON_ANODE?255-b:b);
 static bool started=false,lastOn=false;static uint32_t lastLog=0;
 const bool on=(r||g||b);
 if(!started || (on!=lastOn && elapsed(millis(),lastLog,100)) || elapsed(millis(),lastLog,2000)){
  started=true;lastOn=on;lastLog=millis();
  Serial.printf("[RGB master] GPIO R=%u G=%u B=%u common=%s PWM R=%d G=%d B=%d\n",
   unsigned(cfg::RGB_R),unsigned(cfg::RGB_G),unsigned(cfg::RGB_B),cfg::RGB_COMMON_ANODE?"ANODE":"CATHODE",
   cfg::RGB_COMMON_ANODE?255-r:r,cfg::RGB_COMMON_ANODE?255-g:g,cfg::RGB_COMMON_ANODE?255-b:b);
 }
}
uint32_t pixelColor(Color color) {
 switch(color) {
  case Color::Red:return fountainStrip.Color(255,0,0);
  case Color::Green:return fountainStrip.Color(0,255,0);
  case Color::Blue:return fountainStrip.Color(0,0,255);
  case Color::Yellow:return fountainStrip.Color(255,255,0);
  case Color::White:return fountainStrip.Color(255,255,255);
  default:return 0;
 }
}
void setupLEDs() {
 fountainStrip.begin();buildingStrip.begin();
 fountainStrip.setBrightness(cfg::BRIGHTNESS);buildingStrip.setBrightness(cfg::BRIGHTNESS);
 fountainStrip.clear();buildingStrip.clear();fountainStrip.show();buildingStrip.show();
 pinMode(cfg::RGB_R,OUTPUT);pinMode(cfg::RGB_G,OUTPUT);pinMode(cfg::RGB_B,OUTPUT);setRgbColor(0,0,0);
}
void applyLighting(const Outputs& out) {
 static Color lastColor=Color::None;static bool lastBuilding=false,lastRgb=false;static uint32_t lastFrame=0;
 if(out.fountain!=lastColor) {
  fountainStrip.fill(pixelColor(out.fountain));fountainStrip.show();lastColor=out.fountain;
  logEvent(out.fountain==Color::None?Event::FountainOff:Event::FountainOn);
 }
 if(out.building!=lastBuilding) {
  buildingStrip.fill(out.building?buildingStrip.Color(255,255,0):0);buildingStrip.show();lastBuilding=out.building;
  logEvent(out.building?Event::BuildingOn:Event::BuildingOff);
 }
 if(out.rgb!=lastRgb) {lastRgb=out.rgb;logEvent(out.rgb?Event::RgbOn:Event::RgbOff);if(!out.rgb)setRgbColor(0,0,0);}
 if(out.rgb && elapsed(millis(),lastFrame,20)) {
  lastFrame=millis();uint16_t phase=uint16_t((millis()/12)%768);int r=0,g=0,b=0;
  if(phase<256){r=255-phase;g=phase;}else if(phase<512){g=511-phase;b=phase-256;}else{b=767-phase;r=phase-512;}
  setRgbColor(r,g,b);
 }
}
