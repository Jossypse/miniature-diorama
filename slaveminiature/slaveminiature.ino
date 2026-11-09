#include <Arduino.h>
#include <esp_now.h>
#include <esp_wifi.h>
#include <esp_system.h>
#include <WiFi.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include "slave_config.h"
#include "reliable_link.h"
#include "slave_color.h"
#include "feedback.h"
using namespace mini;
SlaveController slaveLink(1);
LiquidCrystal_I2C lcd(cfg::LCD_ADDRESS,16,2);
EventLog slaveEvents;
SensorState sensors;
ColorCalibration colorCalibration;
bool radioReady=false;
void setupLCD();void setupSensors();void setupESPNowSlave();void serviceSensors();
void serviceSlaveLink();void updateLCDDisplay();void applyRelays();
void setup() {
 Serial.begin(115200);slaveLink=SlaveController(esp_random()|1U);
 digitalWrite(cfg::RELAY1,cfg::RELAY_ACTIVE_HIGH?LOW:HIGH);digitalWrite(cfg::RELAY2,cfg::RELAY_ACTIVE_HIGH?LOW:HIGH);
 pinMode(cfg::RELAY1,OUTPUT);pinMode(cfg::RELAY2,OUTPUT);applyRelays();
 setupSensors();setupLCD();setupESPNowSlave();slaveEvents.push(Event::Boot);
}
void loop(){serviceSlaveLink();serviceSensors();updateLCDDisplay();delay(1);}
