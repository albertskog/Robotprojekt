// Sensor plattorm
// Written by: Albert Skog 11-10-06
// update by: Karl Westerberg

#include <Wire.h>
#include <AverageList.h>

typedef int sample;
const byte MAX_NUMBER_OF_READINGS = 5;
sample storage[MAX_NUMBER_OF_READINGS] = {0};
AverageList<sample> distance = AverageList<sample>( storage, MAX_NUMBER_OF_READINGS );

// Compass
byte data[7];
int x, y, z;
int heading;
int compass;

//Variables
char inPackage[10];
String dataPackage;
byte packageNumber;
int i;

//UV sensor
int eco = 3;
int trig = 7;
int USsensor;

boolean cheak = true;

void setup()
{
  Serial.begin(9600); //Depends on the BT-module
  
  Wire.begin();
  //init compass
  Wire.beginTransmission(0x1E); //Factory default address is 0x1E
  Wire.send(0x02); //enter register 2
  Wire.send(0x00); //Enter all zeros to enter continous mode
  Wire.endTransmission();
  
  //init US sensor
  pinMode(eco, INPUT);
  pinMode(trig, OUTPUT); 
}

void getPackage()
{
  i = 0;
  int w = 0;
  boolean cheak = true;
  //Check for new instructions    
    while(Serial.available())
    {
      if(i < 11)
      {
        inPackage[i++] = char(Serial.read());
      }
      else
      { 
        cheak = false;
        break;
      }
    }
      if(cheak == false)
      {
      Serial.println("Fel fel fel, Send ett nytt!");
      }
      else
      {
        while(w != i)
        {
          Serial.print(inPackage[w++]);
        }
      }      
}

void parseInPackage()
{
  //Did we get the beginning of a package?
  if(inPackage[0] == '$')
  {
    //Extract pkg nr
    if(inPackage[1] == 'N')
    {
      while(inPackage[i] != '#')
      {
//        inNr = 
      }
    }
    
    
  }//inPackage[1] == "$"
}

int getCompassData()
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
  //Serial.println(heading, DEC);
  delay(10);
  
  return heading; 
}

int getUSData()
{
  int meanValue;
  digitalWrite(trig,HIGH);
  delayMicroseconds(2);
  digitalWrite(trig,LOW);
  delayMicroseconds(2);
  int sencData = pulseIn(eco,HIGH)/58;
  distance.addValue(sencData);
  //Serial.println(distance.getAverage()); 
  meanValue = distance.getAverage();
  
  return meanValue;
}

void buildDataPackage()
{
  dataPackage = "";
  //Begin data package
  dataPackage += '$';
  //Put a number on it
  dataPackage += 'N';
  dataPackage += String(packageNumber++,DEC);
  dataPackage += '#';
  
  // GPS data
  dataPackage += 'P';
  dataPackage += "0000";
  dataPackage += ';';
  dataPackage += "0000";
  dataPackage += ';';
  dataPackage += "0000";
  dataPackage += '#';
  
  //Compass data
  dataPackage += "C ";
  dataPackage += String(compass,DEC);
  dataPackage += " #";
  
  //UV-sensor data
  dataPackage += "U ";
  dataPackage += String(USsensor,DEC); // data from US sensor;
  dataPackage += " ;";
  dataPackage += "000";
  dataPackage += ';';
  dataPackage += "000";
  dataPackage += ';';
  dataPackage += "000";
  dataPackage += ';';
  dataPackage += "000";
  dataPackage += ';';
  dataPackage += "000";
  dataPackage += '#';
  
  //Steering angel
  dataPackage += 'A';
  dataPackage += "000";
  dataPackage += '#';
  
  //Distance
  dataPackage += 'D';
  dataPackage += "0000";
  dataPackage += '#';
  
  //Package nr
  dataPackage += 'L';
//  dataPackage += inPackage;
  dataPackage += '#';
 
  dataPackage += char(10);
}

void loop()
{
  if (Serial.available())
  {
    getPackage();
  }
  parseInPackage();
  USsensor = getUSData();
  compass = getCompassData();
  

  //Build sensor data package
  buildDataPackage();
  
  //Send the package
  Serial.print(dataPackage);
  
  delay(500);
}
