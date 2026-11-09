#pragma once
#include <stdint.h>
namespace cfg {
constexpr uint8_t RELAY1=23, RELAY2=19, JOY=34, IR=4, SOUND=5;
constexpr uint8_t TCS_S2=25,TCS_S3=26,TCS_OUT=27,LCD_SDA=21,LCD_SCL=22;
constexpr uint8_t LCD_ADDRESS=0x27, CHANNEL=1;
constexpr bool RELAY_ACTIVE_HIGH=true, IR_ACTIVE_HIGH=false, SOUND_ACTIVE_HIGH=true;
constexpr uint8_t MASTER_MAC[]={0x40,0x22,0xD8,0x33,0xC5,0x40};
// S0/S1 are externally wired: recommended 20% frequency scaling (HIGH/LOW).
constexpr uint32_t COLOR_PULSE_TIMEOUT_US=3000;
constexpr uint8_t pins[]={23,19,34,5,4,25,26,27,21,22};
constexpr bool uniquePins() { for(unsigned i=0;i<sizeof(pins);++i) for(unsigned j=i+1;j<sizeof(pins);++j) if(pins[i]==pins[j]) return false; return true; }
static_assert(uniquePins(),"Slave GPIO conflict");
}
