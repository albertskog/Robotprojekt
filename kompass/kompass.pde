// Program for testing compass module HMC5843
// Written by: Albert Skog 11-10-10
// Inspired by:
// http://aeroquad.com/showthread.php?691-Hold-your-heading-with-HMC5843-Magnetometer

#include <Wire.h>

byte data[6];
int  i;

void setup()
{
  Serial.begin(9600);

  Wire.begin();

  //init compass
  Wire.beginTransmission(0x1E); //Factory default address is 0x1E
  Wire.send(0x02); //enter register 2
  Wire.send(0x00); //Enter all zeros to enter continous mode
  Wire.endTransmission();
}

void loop()
{
  Wire.requestFrom(0x1E, 6);    // request 6 bytes
  
  i = 0;
  while(Wire.available())    // slave may send less than requested
  { 
    data[i++] = Wire.receive(); // receive a byte as character
  }
  Serial.println(data[0]);
}

