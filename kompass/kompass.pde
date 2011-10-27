// Program for testing compass module HMC5843
// Written by: Albert Skog 11-10-10
// Inspired by:
// http://aeroquad.com/showthread.php?691-Hold-your-heading-with-HMC5843-Magnetometer

#include <Wire.h>

byte data[7];
int  i;
int x, y, z;
int heading;

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
  Wire.requestFrom(0x1E, 7);    // request 7 bytes
  i = 0;
  while(Wire.available())    // slave may send less than requested
  { 
    data[i++] = Wire.receive();
  }
  
  //Parse data from DXRA, DXRB, DYRA, DYRB, DZRA, DZRB intp x, y, z
  x = -((((int)data[0]) << 8) | data[1]);
  y = -((((int)data[2]) << 8) | data[3]);
  z = -((((int)data[4]) << 8) | data[5]);  

  heading = (atan2(x,y))*180/M_PI; // argument of (x-axis)/(y-axis) and to degrees. 
  Serial.println(heading, DEC);
  /*
  //Print raw xyz-data
  Serial.print(x, DEC);
  Serial.print(' ');
  Serial.print(y, DEC);
  Serial.print(' ');
  Serial.print(z, DEC);
  Serial.println();
  */
  delay(100);
}

