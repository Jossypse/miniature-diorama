SemaphoreHandle_t apiMutex=nullptr;
void executeQueuedApi(const ApiCommand& command){
 if(apiMutex && xSemaphoreTake(apiMutex,pdMS_TO_TICKS(5))==pdTRUE){
  device.execute(command,millis());xSemaphoreGive(apiMutex);
 }else if(apiMutex && xSemaphoreTake(apiMutex,pdMS_TO_TICKS(5))==pdTRUE){device.registry.finish(command.id,CommandStatus::Failed,Reason::QueueFull,millis());xSemaphoreGive(apiMutex);}
}
void serviceApiResults(){if(apiMutex && xSemaphoreTake(apiMutex,pdMS_TO_TICKS(5))==pdTRUE){device.tick(millis());xSemaphoreGive(apiMutex);}}
void handleApiHttp(){
 ApiHttpRequest req;req.method=server.method()==HTTP_POST?"POST":"GET";req.path=server.uri().c_str();req.body=server.arg("plain").c_str();req.now=millis();
 WebSnapshot state=readWebSnapshot();req.automatic=state.automatic;req.slaveOnline=state.link;req.audioReady=state.audioReady;
 if(!apiMutex || xSemaphoreTake(apiMutex,pdMS_TO_TICKS(10))!=pdTRUE){server.send(503,"application/json",serializeError(Reason::QueueFull).c_str());return;}
 ApiReply reply=handleApiRequest(req,device.registry);xSemaphoreGive(apiMutex);
 if(reply.enqueue){WebAction action{WebOp::Api,0,false};action.command=reply.command;
  if(xQueueSend(webActions,&action,0)!=pdTRUE){
   if(xSemaphoreTake(apiMutex,pdMS_TO_TICKS(10))==pdTRUE){device.registry.finish(reply.command.id,CommandStatus::Failed,Reason::QueueFull,millis());xSemaphoreGive(apiMutex);}
   reply.code=503;reply.body=serializeError(Reason::QueueFull);
  }
 }
 server.sendHeader("Cache-Control","no-store");server.send(reply.code,"application/json",reply.body.c_str());
}
void setupApiRoutes(){
 apiMutex=xSemaphoreCreateMutex();
 server.on("/api/v1/status",HTTP_GET,[](){
  queueWebAction(WebOp::Poll,0,false);String json;
  if(webSnapshotMutex && xSemaphoreTake(webSnapshotMutex,pdMS_TO_TICKS(10))==pdTRUE){json=apiStatusJson;xSemaphoreGive(webSnapshotMutex);}
  if(json.isEmpty()){server.send(503,"application/json",serializeError(Reason::Internal).c_str());return;}
  server.sendHeader("Cache-Control","no-store");server.send(200,"application/json",json);
 });
 server.on("/api/v1/commands",HTTP_POST,handleApiHttp);
 server.onNotFound([](){if(server.uri().startsWith("/api/v1/commands/"))handleApiHttp();else server.send(404,"text/plain","Not found");});
}
