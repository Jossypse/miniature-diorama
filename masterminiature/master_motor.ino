void setupMotor() {
 digitalWrite(cfg::MOTOR_A,LOW);digitalWrite(cfg::MOTOR_B,LOW);
 pinMode(cfg::MOTOR_A,OUTPUT);pinMode(cfg::MOTOR_B,OUTPUT);pinMode(cfg::MOTOR_PWM,OUTPUT);
 analogWrite(cfg::MOTOR_PWM,0);
}
void motorForward(int speed) {
 analogWrite(cfg::MOTOR_PWM,0);digitalWrite(cfg::MOTOR_A,HIGH);digitalWrite(cfg::MOTOR_B,LOW);analogWrite(cfg::MOTOR_PWM,speed);
}
void motorReverse(int speed) {
 analogWrite(cfg::MOTOR_PWM,0);digitalWrite(cfg::MOTOR_A,LOW);digitalWrite(cfg::MOTOR_B,HIGH);analogWrite(cfg::MOTOR_PWM,speed);
}
void stopMotor() { analogWrite(cfg::MOTOR_PWM,0);digitalWrite(cfg::MOTOR_A,LOW);digitalWrite(cfg::MOTOR_B,LOW); }
