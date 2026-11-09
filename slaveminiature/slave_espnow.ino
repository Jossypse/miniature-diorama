QueueHandle_t slaveRxQueue=nullptr;
void onSlaveReceive(const esp_now_recv_info_t* info,const uint8_t* data,int len) {
 if(!info || !slaveRxQueue || memcmp(info->src_addr,cfg::MASTER_MAC,6)!=0 || len!=sizeof(Packet))return;
 ReceivedPacket rx;rx.receivedAt=millis();if(decodePacket(rx.packet,data,size_t(len)))xQueueSend(slaveRxQueue,&rx,0);
}
void applyRelays() {
 bool r1=(slaveLink.relays&1)!=0,r2=(slaveLink.relays&2)!=0;
 digitalWrite(cfg::RELAY1,(r1==cfg::RELAY_ACTIVE_HIGH)?HIGH:LOW);
 digitalWrite(cfg::RELAY2,(r2==cfg::RELAY_ACTIVE_HIGH)?HIGH:LOW);
}
bool sendSlavePacket(const Packet& p) {
 if(!radioReady)return false;
 esp_err_t result=esp_now_send(cfg::MASTER_MAC,reinterpret_cast<const uint8_t*>(&p),sizeof p);
 if(result!=ESP_OK)Serial.printf("ESP-NOW send rejected: %d\n",int(result));return result==ESP_OK;
}
void setupESPNowSlave() {
 WiFi.mode(WIFI_STA);WiFi.setSleep(false);
 if(esp_wifi_set_channel(cfg::CHANNEL,WIFI_SECOND_CHAN_NONE)!=ESP_OK){Serial.println("Radio channel failed");return;}
 slaveRxQueue=xQueueCreate(12,sizeof(ReceivedPacket));
 if(!slaveRxQueue || esp_now_init()!=ESP_OK){Serial.println("ESP-NOW init failed");return;}
 esp_now_peer_info_t peer{};memcpy(peer.peer_addr,cfg::MASTER_MAC,6);peer.channel=cfg::CHANNEL;peer.ifidx=WIFI_IF_STA;
 if(esp_now_add_peer(&peer)!=ESP_OK || esp_now_register_recv_cb(onSlaveReceive)!=ESP_OK){Serial.println("Peer/callback failed");return;}
 radioReady=true;Serial.print("Slave STA MAC: ");Serial.println(WiFi.macAddress());
}
void serviceSlaveLink() {
 static uint32_t lastTelemetry=0,lastEvent=0;static bool wasConnected=false;
 // Enforce watchdog before dequeuing old commands.
 if(slaveLink.tick(millis(),esp_random()|1U)){applyRelays();slaveEvents.push(Event::LinkLost);lastEvent=0;}
 Packet p;ReceivedPacket rx;
 while(slaveRxQueue && xQueueReceive(slaveRxQueue,&rx,0)==pdTRUE) {
  p=rx.packet;if(elapsed(millis(),rx.receivedAt,STALE_MS))continue;
  if(!slaveLink.receive(p,rx.receivedAt))continue;
  applyRelays();
  if(p.kind==Kind::Command){sendSlavePacket(slaveLink.acknowledgment(p));slaveEvents.push(Event::PumpConfirmed);}
  else if(p.eventSequence!=lastEvent){lastEvent=p.eventSequence;slaveEvents.push(p.event);}
 }
 if(slaveLink.connected!=wasConnected){wasConnected=slaveLink.connected;if(wasConnected)slaveEvents.push(Event::LinkOnline);}
 if(elapsed(millis(),lastTelemetry,HEARTBEAT_MS)){
  lastTelemetry=millis();p=slaveLink.telemetry(millis());p.joy=sensors.joy;p.ir=sensors.ir;p.sound=sensors.sound;p.color=sensors.color;
  if(sendSlavePacket(p))sensors.sound=false;
 }
}
