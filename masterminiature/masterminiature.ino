#include <Arduino.h>
#include <esp_now.h>
#include <esp_wifi.h>
#include <esp_system.h>
#include <WiFi.h>
#include <WebServer.h>
#include <HardwareSerial.h>
#include <DFRobotDFPlayerMini.h>
#include <Adafruit_NeoPixel.h>
#include <freertos/semphr.h>
#include "master_config.h"
#include "master_controller.h"
#include "combined_action.h"
#include "feedback.h"
#include "audio_monitor.h"
#include "web_bridge.h"
#include "wifi_status.h"
using namespace mini;
extern QueueHandle_t webActions;
extern SemaphoreHandle_t webSnapshotMutex;
extern String apiStatusJson;
WebServer server(80);
Controller controller;
ReliableLink masterLink(1);
CombinedAction combined;
AppPresence appPresence;
EventLog events;
AudioMonitor audioMonitor;
WifiController device(controller,masterLink,combined,1);
SensorState readings;
bool audioReady=false,audioRequested=false,radioReady=false;
uint32_t lastTelemetry=0;
void setupMotor(); void stopMotor(); void setupLEDs(); void setupButtonsAndRGB();
void setupDFPlayer(); void setupWiFiAP(); void setupESPNowMaster(); void setupWebServerRoutes();
void serviceMasterLink(); void handleButtons(); void serviceAudio(); void serviceController();
void logEvent(Event event); void applyCombinedRequests();
void serviceWebActions();void publishWebStatus();void startWebTask();
void serviceApiResults();void setupApiRoutes();
void setup() {
 Serial.begin(115200);
 setupMotor(); setupLEDs(); setupButtonsAndRGB();
 combined.intervalMs=cfg::FOUNTAIN_STEP_MS;
 controller.joyLow=cfg::JOY_LOW; controller.joyHigh=cfg::JOY_HIGH;
 masterLink=ReliableLink(esp_random()|1U);
 device.registry=CommandRegistry(masterLink.session);
 setupDFPlayer();
 setupWiFiAP(); setupESPNowMaster(); setupWebServerRoutes(); server.begin();publishWebStatus();startWebTask();
 logEvent(Event::Boot);
}
void loop() {
 serviceMasterLink();readings.fresh=masterLink.connected && !elapsed(millis(),lastTelemetry,STALE_MS);device.sensors=readings;
 serviceWebActions();handleButtons(); serviceAudio();serviceApiResults();
 serviceController();publishWebStatus();delay(1);
}
