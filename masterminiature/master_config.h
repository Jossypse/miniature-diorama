#pragma once
#include <stdint.h>
namespace cfg {
constexpr uint8_t BUTTONS[]={13,12,14,27,26};
constexpr uint8_t FOUNTAIN=33, BUILDING=25, MOTOR_A=18, MOTOR_B=5, MOTOR_PWM=4;
constexpr uint8_t RGB_R=19, RGB_G=21, RGB_B=22, AUDIO_RX=17, AUDIO_TX=16;
constexpr uint16_t FOUNTAIN_COUNT=30, BUILDING_COUNT=30;
constexpr uint32_t FOUNTAIN_STEP_MS=4000;
constexpr uint8_t BRIGHTNESS=50, CHANNEL=1, MOTOR_SPEED=255;
constexpr uint16_t JOY_LOW=1000, JOY_HIGH=3000;
constexpr bool MOTOR_REVERSED=false, RGB_COMMON_ANODE=false;
constexpr uint8_t SLAVE_MAC[]={0xB0,0x3F,0xD3,0x5A,0xF2,0xC4};
constexpr uint8_t pins[]={13,12,14,27,26,33,25,18,5,4,19,21,22,17,16};
constexpr bool uniquePins() { for(unsigned i=0;i<sizeof(pins);++i) for(unsigned j=i+1;j<sizeof(pins);++j) if(pins[i]==pins[j]) return false; return true; }
static_assert(uniquePins(),"Master GPIO conflict");
}
