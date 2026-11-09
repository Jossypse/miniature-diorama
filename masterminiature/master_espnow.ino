QueueHandle_t masterRxQueue=nullptr;
void onMasterReceive(const esp_now_recv_info_t* info,const uint8_t* data,int len) {
 if(!info || !masterRxQueue || memcmp(info->src_addr,cfg::SLAVE_MAC,6)!=0 || len!=sizeof(Packet))return;
 ReceivedPacket rx;rx.receivedAt=millis();if(decodePacket(rx.packet,data,size_t(len)))xQueueSend(masterRxQueue,&rx,0);
}
bool sendMasterPacket(const Packet& p) {
 if(!radioReady)return false;
 esp_err_t result=esp_now_send(cfg::SLAVE_MAC,reinterpret_cast<const uint8_t*>(&p),sizeof p);
 if(result!=ESP_OK)Serial.printf("ESP-NOW send rejected: %d\n",int(result));return result==ESP_OK;
}
void setupESPNowMaster() {
 masterRxQueue=xQueueCreate(12,sizeof(ReceivedPacket));
 if(!masterRxQueue || esp_now_init()!=ESP_OK){Serial.println("ESP-NOW init failed");return;}
 esp_now_peer_info_t peer{};memcpy(peer.peer_addr,cfg::SLAVE_MAC,6);peer.channel=cfg::CHANNEL;peer.ifidx=WIFI_IF_STA;
 if(esp_now_add_peer(&peer)!=ESP_OK || esp_now_register_recv_cb(onMasterReceive)!=ESP_OK){Serial.println("ESP-NOW peer/callback failed");return;}
 radioReady=true;Serial.print("Master STA MAC: ");Serial.println(WiFi.macAddress());
}
void serviceMasterLink() {
 static uint32_t lastBeat=0,sentEvent=0;static bool wasConnected=false,wasPending=false;
 masterLink.tick(millis());
 ReceivedPacket rx;Packet p;
 while(masterRxQueue && xQueueReceive(masterRxQueue,&rx,0)==pdTRUE) {
  p=rx.packet;if(elapsed(millis(),rx.receivedAt,STALE_MS))continue;
  if(masterLink.receive(p,rx.receivedAt) && p.kind==Kind::Telemetry) {
   device.history.observe(p,rx.receivedAt);++device.revision;
   readings.ir=p.ir;readings.sound=readings.sound||p.sound;readings.joy=p.joy;readings.color=p.color;lastTelemetry=rx.receivedAt;
  }
 }
 masterLink.tick(millis());if(masterLink.retryDue(millis()))sendMasterPacket(masterLink.command);
 if(masterLink.connected!=wasConnected) {
  wasConnected=masterLink.connected;logEvent(wasConnected?Event::LinkOnline:Event::LinkLost);
  if(!wasConnected){readings=SensorState{};stopMotor();combined.cancel(masterLink,millis());}
 }
 if(wasPending && !masterLink.pending)logEvent(masterLink.failed?Event::PumpFailed:Event::PumpConfirmed);
 wasPending=masterLink.pending;
 if(elapsed(millis(),lastBeat,HEARTBEAT_MS)) {
  lastBeat=millis();p=masterLink.heartbeat(millis());p.automatic=controller.automatic;p.app=appPresence.online(millis());
  uint32_t behind=uint32_t(events.sequence-sentEvent);
  if(behind>events.size()){sentEvent=events.sequence-events.size();behind=events.size();}
  if(behind){p.event=events.at(uint8_t(behind-1));p.eventSequence=++sentEvent;}
  else {p.event=events.latest();p.eventSequence=events.sequence;}
  sendMasterPacket(p);
 }
}
