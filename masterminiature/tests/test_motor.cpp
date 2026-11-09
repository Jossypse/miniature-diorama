#include <cassert>
#include <cstdio>
#include <vector>
#include "master_config.h"
constexpr int LOW=0,HIGH=1,OUTPUT=1;
int levels[40]={},pwm[40]={},modes[40]={};
struct Write {int pin,value;};std::vector<Write> pwmWrites;
void pinMode(int pin,int mode){modes[pin]=mode;}
void digitalWrite(int pin,int value){levels[pin]=value;}
void analogWrite(int pin,int value){pwm[pin]=value;pwmWrites.push_back({pin,value});}
#include "master_motor.ino"
int main(){
 setupMotor();assert(pwm[4]==0 && levels[18]==0 && levels[5]==0);
 assert(modes[4]==OUTPUT && modes[18]==OUTPUT && modes[5]==OUTPUT);
 motorForward(180);assert(levels[18]==HIGH && levels[5]==LOW && pwm[4]==180);
 pwmWrites.clear();motorReverse(200);
 assert(pwmWrites.size()==2 && pwmWrites[0].pin==4 && pwmWrites[0].value==0);
 assert(levels[18]==LOW && levels[5]==HIGH && pwm[4]==200);
 stopMotor();assert(pwm[4]==0 && levels[18]==LOW && levels[5]==LOW);
 puts("PASS actual motor adapter: safe boot, assigned pins, direction, zero PWM before reversal, stop");
}
