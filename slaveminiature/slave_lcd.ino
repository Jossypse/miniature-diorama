void setupLCD(){Wire.begin(cfg::LCD_SDA,cfg::LCD_SCL);Wire.setTimeOut(20);lcd.init();lcd.backlight();}
void updateLCDDisplay() {
 static uint32_t lastUpdate=0;static char previous[2][17]={{0},{0}};
 if(!elapsed(millis(),lastUpdate,200))return;lastUpdate=millis();
 char text[48],rows[2][17];
 if(!slaveLink.connected)snprintf(text,sizeof text,"LINK OFF APP OFF");
 else snprintf(text,sizeof text,"L:OK A:%s %s",slaveLink.status.app?"ON":"OFF",slaveLink.status.automatic?"AUTO":"MAN");
 lcdRow(rows[0],text);
 if((millis()/2500)%2==0){snprintf(text,sizeof text,"P1:%s P2:%s",(slaveLink.relays&1)?"ON":"OFF",(slaveLink.relays&2)?"ON":"OFF");lcdRow(rows[1],text);}
 else {
  uint8_t offset=slaveEvents.size()?uint8_t((millis()/5000)%slaveEvents.size()):0;
  lcdRow(rows[1],eventText(slaveEvents.at(offset)));
 }
 for(uint8_t row=0;row<2;++row)if(strcmp(previous[row],rows[row])!=0){lcd.setCursor(0,row);lcd.print(rows[row]);memcpy(previous[row],rows[row],17);}
}
