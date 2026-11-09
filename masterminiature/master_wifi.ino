QueueHandle_t webActions=nullptr;
SemaphoreHandle_t webSnapshotMutex=nullptr;
WebSnapshot webSnapshot;
bool webEnabled=false;
String apiStatusJson="{}";
void executeQueuedApi(const ApiCommand& command);
void setupWiFiAP() {
 WiFi.mode(WIFI_AP_STA);WiFi.setSleep(false);
 if(!WiFi.softAP("ESP32_Master_Diorama","password123",cfg::CHANNEL))Serial.println("AP startup failed");
 if(esp_wifi_set_channel(cfg::CHANNEL,WIFI_SECOND_CHAN_NONE)!=ESP_OK)Serial.println("Radio channel setup failed");
 Serial.print("Control page: http://");Serial.println(WiFi.softAPIP());
}
String buildStatusJson() {
 char text[96];escapeJson(text,sizeof text,eventText(events.latest()));
 String json="{\"automatic\":";json+=controller.automatic?"true":"false";
 json+=",\"link\":";json+=masterLink.connected?"true":"false";
 json+=",\"app\":";json+=appPresence.online(millis())?"true":"false";
 json+=",\"pending\":";json+=masterLink.pending?"true":"false";
 json+=",\"failed\":";json+=masterLink.failed?"true":"false";
 json+=",\"relaysKnown\":";json+=masterLink.connected?"true":"false";
 json+=",\"relays\":";json+=masterLink.confirmed;
 json+=",\"audioReady\":";json+=audioReady?"true":"false";
 json+=",\"audioRequested\":";json+=audioRequested?"true":"false";
 json+=",\"combined\":";json+=combined.engaged()?"true":"false";
 json+=",\"event\":\"";json+=text;json+="\",\"logs\":[";
 for(uint8_t i=0;i<events.size();++i){if(i)json+=',';escapeJson(text,sizeof text,eventText(events.at(i)));json+='"';json+=text;json+='"';}
 json+="]}";return json;
}
WebSnapshot readWebSnapshot(){
 WebSnapshot result;
 if(webSnapshotMutex && xSemaphoreTake(webSnapshotMutex,pdMS_TO_TICKS(5))==pdTRUE){result=webSnapshot;xSemaphoreGive(webSnapshotMutex);}
 return result;
}
void publishWebStatus(){
 static uint32_t lastPublish=0;
 if(!webSnapshotMutex || !elapsed(millis(),lastPublish,100))return;
 lastPublish=millis();WebSnapshot next;next.automatic=controller.automatic;next.link=masterLink.connected;next.audioReady=audioReady;
 String json=buildStatusJson();json.toCharArray(next.json,sizeof next.json);
 ++device.revision;auto snapshot=makeDeviceSnapshot(device,controller,masterLink,combined,events,appPresence.online(millis()),millis());
 std::string typed=serializeStatus(snapshot);
 if(xSemaphoreTake(webSnapshotMutex,0)==pdTRUE){webSnapshot=next;apiStatusJson=typed.c_str();xSemaphoreGive(webSnapshotMutex);}
}
bool queueWebAction(WebOp op,uint8_t argument,bool on){
 WebAction action{op,argument,on};return webActions && xQueueSend(webActions,&action,0)==pdTRUE;
}
void respondQueued(WebOp op,uint8_t argument,bool on){
 if(queueWebAction(op,argument,on))server.send(202,"text/plain","Action queued; check confirmed status and events");
 else server.send(503,"text/plain","Controller busy; try again");
}
void webLight(uint8_t light,bool on){
 if(readWebSnapshot().automatic){server.send(409,"text/plain","Switch to manual mode to control lights.");return;}
 respondQueued(WebOp::Light,light,on);
}
void webPump(uint8_t relay,bool on){
 if(!readWebSnapshot().link){server.send(503,"text/plain","Slave offline; pump state unknown");return;}
 respondQueued(WebOp::Relay,relay,on);
}
void webAudio(int track){
 if(track && !readWebSnapshot().audioReady){server.send(503,"text/plain","DFPlayer not ready");return;}
 respondQueued(WebOp::Audio,uint8_t(track),false);
}
void serviceWebActions(){
 WebAction a;
 // One bounded batch; all actuator mutations remain on the Arduino control task.
 for(uint8_t count=0;count<8 && webActions && xQueueReceive(webActions,&a,0)==pdTRUE;++count){
  switch(a.op){
   case WebOp::Poll:appPresence.poll(millis());break;
   case WebOp::Light:if(!controller.setLight(a.argument,a.on))logEvent(Event::AutoOwnsLights);break;
   case WebOp::Mode:handleButton(4);break;
   case WebOp::Combined:handleButton(5);break;
   case WebOp::Relay:
    logEvent(device.setRelay(a.argument,a.on,millis())?Event::PumpPending:Event::PumpFailed);break;
   case WebOp::Audio:
    if(!a.argument)stopAudio();else if(!playAudioTrack(a.argument))logEvent(Event::AudioUnavailable);break;
   case WebOp::Api:executeQueuedApi(a.command);break;
  }
 }
}
void webTask(void*){for(;;){server.handleClient();vTaskDelay(pdMS_TO_TICKS(2));}}
void startWebTask(){
 if(!webEnabled)return;
 if(xTaskCreate(webTask,"control-http",8192,nullptr,1,nullptr)!=pdPASS)Serial.println("HTTP task creation failed");
}
void setupWebServerRoutes() {
 webActions=xQueueCreate(12,sizeof(WebAction));webSnapshotMutex=xSemaphoreCreateMutex();
 if(!webActions || !webSnapshotMutex){Serial.println("HTTP bridge allocation failed");return;}webEnabled=true;
 setupApiRoutes();
 server.on("/",HTTP_GET,[](){
  server.sendHeader("Cache-Control","no-store");
  server.send(200,"text/html",R"HTML(<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Diorama Control Panel</title>
<style>body{font:16px Arial,sans-serif;max-width:650px;margin:24px auto;padding:0 16px;background:#f4f4f9;color:#222}section{background:white;padding:16px;margin:14px 0;border-radius:8px}button{padding:12px;margin:4px;cursor:pointer}#message{min-height:2em}li{margin:5px 0}</style>
<h1>Diorama Control Panel</h1><p id="status" role="status">Connecting...</p><p id="message" role="alert"></p>
<section><h2>Mode</h2><button data-path="/mode/toggle">Toggle automatic / manual</button><p>Lighting buttons operate in manual mode. The joystick operates in manual mode.</p></section>
<section><h2>Lighting</h2><p>Fountain: <button data-path="/fountain/on">Blue ON</button><button data-path="/fountain/off">OFF</button></p><p>Building: <button data-path="/building/on">Yellow ON</button><button data-path="/building/off">OFF</button></p><p>RGB: <button data-path="/rgb/on">Color cycle ON</button><button data-path="/rgb/off">OFF</button></p></section>
<section><h2>Fountain show</h2><button data-path="/combined/toggle">Toggle track 1 + pump 1</button><h2>Pumps</h2><p id="pumps">Unknown</p><button data-path="/pump1/on">Pump 1 ON</button><button data-path="/pump1/off">Pump 1 OFF</button><button data-path="/pump2/on">Pump 2 ON</button><button data-path="/pump2/off">Pump 2 OFF</button></section>
<section><h2>Audio</h2><p id="audio"></p><button data-path="/audio/track1">Track 1</button><button data-path="/audio/track2">Track 2</button><button data-path="/audio/stop">Stop audio</button></section>
<section><h2>Recent events</h2><ul id="logs"></ul></section>
<script>
const byId=id=>document.getElementById(id);
document.querySelectorAll('button[data-path]').forEach(b=>b.onclick=async()=>{b.disabled=true;try{const r=await fetch(b.dataset.path,{cache:'no-store'});byId('message').textContent=await r.text();}catch(e){byId('message').textContent='Command failed: connection unavailable';}finally{b.disabled=false;}});
async function poll(){try{const r=await fetch('/status',{cache:'no-store'});if(!r.ok)throw Error();const s=await r.json();byId('status').textContent=(s.automatic?'AUTOMATIC':'MANUAL')+' | Slave '+(s.link?'online':'offline');byId('pumps').textContent=s.relaysKnown?'Confirmed outputs: P1 '+((s.relays&1)?'ON':'OFF')+', P2 '+((s.relays&2)?'ON':'OFF')+(s.pending?' â€” command pending':'')+(s.failed?' â€” command failed':''):'Pump state unknown â€” slave offline';byId('audio').textContent=s.audioReady?(s.audioRequested?'Playback requested':'DFPlayer ready'):'DFPlayer unavailable';const ul=byId('logs');ul.replaceChildren(...s.logs.map(t=>{const li=document.createElement('li');li.textContent=t;return li;}));}catch(e){byId('status').textContent='App disconnected';byId('pumps').textContent='Pump state unknown';}finally{setTimeout(poll,1000);}}poll();
</script></html>)HTML");
 });
 server.on("/status",HTTP_GET,[](){queueWebAction(WebOp::Poll,0,false);WebSnapshot snapshot=readWebSnapshot();server.sendHeader("Cache-Control","no-store");server.send(200,"application/json",snapshot.json);});
 server.on("/fountain/on",HTTP_GET,[](){webLight(1,true);});server.on("/fountain/off",HTTP_GET,[](){webLight(1,false);});
 server.on("/building/on",HTTP_GET,[](){webLight(3,true);});server.on("/building/off",HTTP_GET,[](){webLight(3,false);});
 server.on("/rgb/on",HTTP_GET,[](){webLight(2,true);});server.on("/rgb/off",HTTP_GET,[](){webLight(2,false);});
 server.on("/mode/toggle",HTTP_GET,[](){respondQueued(WebOp::Mode,0,false);});
 server.on("/combined/toggle",HTTP_GET,[](){respondQueued(WebOp::Combined,0,false);});
 server.on("/pump1/on",HTTP_GET,[](){webPump(1,true);});server.on("/pump1/off",HTTP_GET,[](){webPump(1,false);});
 server.on("/pump2/on",HTTP_GET,[](){webPump(2,true);});server.on("/pump2/off",HTTP_GET,[](){webPump(2,false);});
 server.on("/audio/track1",HTTP_GET,[](){webAudio(1);});server.on("/audio/track2",HTTP_GET,[](){webAudio(2);});server.on("/audio/stop",HTTP_GET,[](){webAudio(0);});
}

