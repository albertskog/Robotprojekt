// Sensor plattorm
// Written by: Albert Skog 11-10-06
// update by: Karl Westerberg
// test inpaket N1#D2;2#E3;3#S4 

#include <Wire.h>
#include <AverageList.h>

#define PACKAGE_LENGTH 40

typedef int sample;
const byte MAX_NUMBER_OF_READINGS = 5;
sample storage[MAX_NUMBER_OF_READINGS] = {
  0};
AverageList<sample> distance = AverageList<sample>( storage, MAX_NUMBER_OF_READINGS );

// Compass
byte data[7];
int x, y, z;
int compass;

//Variables
int inPackageLength = 15;// (33?)
boolean cheakInPackage;
char dataPackage[PACKAGE_LENGTH];
byte packageNumber = 0;
int i;

//UV sensor
int eco = 3;
int trig = 7;
int USsensor;

//in package
int inpackageNumber;
int firstDestinationX;
int firstDestinationY;
int secondDestinationX;
int secondDestinationY;
int velocity;

void setup()
{
  Serial.begin(115200); //Depends on the BT-module

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

void parseInPackage(char inPackage[])
{
   inpackageNumber = inPackage[1];
   firstDestinationX = inPackage[4];
   firstDestinationY = inPackage[6];
   secondDestinationX = inPackage[9];
   secondDestinationY = inPackage[11];
   velocity = inPackage[14];   
//   printPackage();
}
 
void getInPackage()
{
  i = 0;
  char inPackage[inPackageLength-1];

  if(Serial.available() /*&& (Serial.peek() == 'N')*/) // Package starts whit N
  {
    while(Serial.available() /*&& (i < inPackageLength)*/)
    {
      inPackage[i++] = Serial.read();
    }
  }
  else
  {
    Serial.flush(); // clearing the serial 
  }
  // cheking the array
  if((inPackage[0] == 'N') && (inPackage[3] == 'D') && (inPackage[8] == 'E') && (inPackage[13] == 'S'))
  {
  // Serial.println("lyckat paket");
    parseInPackage(inPackage);
  } 
  else
  {  
  }
}

void prepareDataPackage()
{
  dataPackage[0] = 'N';
  dataPackage[2] = '#';
  dataPackage[3] = 'P';
  dataPackage[5] = ';';
  dataPackage[7] = ';';
  dataPackage[9] = '#';
  dataPackage[10] = 'C';
  dataPackage[13] = '#';
  dataPackage[14] = 'U';
  dataPackage[16] = ';';
  dataPackage[18] = ';';
  dataPackage[20] = ';';
  dataPackage[22] = ';';
  dataPackage[24] = ';';
  dataPackage[26] = '#';
  dataPackage[27] = 'V';
  dataPackage[29] = '#';
  dataPackage[30] = 'D';
  dataPackage[32] = '#';
  dataPackage[33] = 'S';
  dataPackage[35] = '#';
  dataPackage[36] = 'L';
  dataPackage[38] = '#';
  dataPackage[39] = 10;
}

/*int getCompassData()
{
  int heading;
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
*/
void buildDataPackage()
{
  dataPackage[1] = packageNumber++;
  dataPackage[4] = firstDestinationX;
  dataPackage[6] = firstDestinationY;
  dataPackage[8] = '_';
  dataPackage[11] = '_';
  dataPackage[15] = '_';
  dataPackage[17] = secondDestinationX;
  dataPackage[19] = secondDestinationY;
  dataPackage[21] = '_';
  dataPackage[23] = '_';
  dataPackage[25] = velocity;
  dataPackage[28] = '_';
  dataPackage[31] = '_';
  dataPackage[34] = '_';
  dataPackage[37] = inpackageNumber;  
}

void loop()
{
  prepareDataPackage();
  buildDataPackage();
//  USsensor = getUSData();
//  compass = getCompassData();
  getInPackage();

  for(int a = 0; a < PACKAGE_LENGTH; a++)
  {
  Serial.print(dataPackage[a]);
  }
  
  delay(500);
}
