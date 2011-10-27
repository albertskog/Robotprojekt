// Main program to collect sensor data, communicate over bluetooth
// and control veichle over I2C
// Written by: Albert Skog 11-10-11

#include <Wire.h>
byte inPackage;
byte ang = 90t;
byte vel = 88;

void setup()
{
  Wire.begin();
  Serial.begin(9600);
}

void parseInPackage()
{
  if (inPackage == 66) { 
    vel -= 2; 
  }//upp
  else if (inPackage == 65) { 
    vel += 2; 
  }//ner
  else if (inPackage == 68) { 
    ang += 10; 
  }//h
  else if (inPackage == 67) { 
    ang -= 10; 
  }//v
  else if (inPackage == 32) { 
    ang = 90; 
    vel = 88; 
  }

  inPackage = 0;
}

void loop()
{
  //Check for new instructions
  inPackage = 0;
  if(Serial.available())
  {
    inPackage = char(Serial.read());

    Serial.println(inPackage, DEC);
    parseInPackage();

    Wire.beginTransmission(4);
    Wire.send(vel);
    Wire.send(ang);
    Wire.endTransmission();
    Serial.println(vel, DEC);
    Serial.println(ang, DEC);
  }
}


