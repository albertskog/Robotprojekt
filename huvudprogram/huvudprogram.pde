// Main program to collect sensor data, communicate over bluetooth
// and control veichle over I2C
// Written by: Albert Skog 11-10-11

#include <Wire.h>
byte inPackage, s, v;

void setup()
{
  Wire.begin();
  Serial.begin(57600);
}

void parseInPackage()
{
    if (inPackage == 66) { vel = 100; }//upp
    else if (inPackage == 65) { vel = 80; }//ner
    else if (inPackage == 68) { ang = 60; }//h
    else if (inPackage == 67) { ang = 120; }//v
    else if (inPackage == 99) { ang = 90; vel = 90; }
    else if (inPackage == 0) { vel = 0; }
    else{ vel = 0; }
    inPackage = 0;
}

void loop()
{
  //Check for new instructions
  inPackage = 0;
  if(Serial.available())
  {
    inPackage = char(Serial.read());
  }
  parseInPackage();
  
  Wire.beginTransmission(4);
  Wire.send(vel);
  Wire.send(ang);
  Wire.endTransmission();
}

