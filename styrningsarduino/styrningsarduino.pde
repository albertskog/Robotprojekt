// Speed & steering control over I2C
// Written by: Stefan Sundin 11-10-10

#include <Wire.h>
#include <Servo.h>

#define I2C_ADDRESS 4

unsigned int data[2] = {
  0,0}; /* data[0]=hastighet, data[1]=vinkel */

Servo speed;
Servo angle;

void setup()
{
  Wire.begin(I2C_ADDRESS);		// join i2c bus with address #4
  Wire.onReceive(receiveEvent);		// register event

  speed.attach(3);
  angle.attach(4);
}

void loop()
{

}

void receiveEvent()
{
  byte i = 0;
  while(1 < Wire.available())		// loop through all but the last
  {
    data[i++] = Wire.receive();		// receive byte as a character
  }
  run();
}

void run()
{
  speed.write(data[0]);
  angle.write(data[1]);
}

