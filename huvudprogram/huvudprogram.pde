// Main program to collect sensor data, communicate over bluetooth
// and control veichle over I2C
// Written by: Albert Skog 11-10-11

#include <Wire.h>
byte inPackage,s, v;

void setup()
{
  Wire.begin();
  Serial.begin(57600);
}

void parseInPackage()
{
    if (inPackage == 66) { v += 10; }//upp
    if (inPackage == 65) { v -= 10; }//ner
    if (inPackage == 68) { s += 10; }//h
    if (inPackage == 67) { s -= 10; }//v
    if (inPackage == 99) { s = 0; v = 0; }

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
  Wire.send(v);
  Wire.send(s);
  Wire.endTransmission();
}

