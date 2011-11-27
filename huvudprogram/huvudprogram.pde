#include <Wire.h>
#include <AverageList.h>

#define PACKAGE_LENGTH 40
#define INPACKAGE_LENGTH 15
#define SENSORPACKAGE_LENGTH 8

typedef int sample;
const byte MAX_NUMBER_OF_READINGS = 5;
sample storage[MAX_NUMBER_OF_READINGS] = {
  0};
AverageList<sample> distance = AverageList<sample>( storage, MAX_NUMBER_OF_READINGS );

//out package
char dataPackage[PACKAGE_LENGTH];
byte packageNumber = 0;

//in package
int inpackageNumber;
int firstDestinationX;
int firstDestinationY;
int secondDestinationX;
int secondDestinationY;
int velocity;

//in I2C
byte inSensorPackage[SENSORPACKAGE_LENGTH];

//US sensors
// boolean cheakSensors = true;
byte front;
byte frontRight;
byte frontLeft;
byte right;
byte left;
byte back;

//GPS 
byte xPos;
byte yPos;
byte dataAge;

// Compass
byte data[7];
int x, y, z;
int compassInValue;

int i;

void setup()
{
  Serial.begin(115200); //Depends on the BT-module
  Wire.begin();
}

void getSensorPackage()
{
  Wire.requestFrom(2, 9);    // request 9 bytes
  i = 0;
  while(Wire.available())    // slave may send less than requested
  { 
    inSensorPackage[i++] = Wire.receive();
  }
  parseSensorPackage(); 
}

void parseSensorPackage()
{
   front = inSensorPackage[0];
   frontLeft = inSensorPackage[1];
   frontRight = inSensorPackage[2];
   left = inSensorPackage[3];
   right = inSensorPackage[4];
   back = inSensorPackage[5]; 
   xPos = inSensorPackage[6]; 
   yPos = inSensorPackage[7]; 
   dataAge = inSensorPackage[8]; 
   
   if(front < 30 || frontLeft < 30 || frontRight < 30)
   {
   cheakSensors();
   }
}

void cheakSensors()
{
  if(front < 30)
  {
   stopRun();
  }
  else if(front < 30)
  {
   stopRun();
  }
  else if(front < 30)
  {
   stopRun();
  }
  else
  {
  }
}

void stopRun()
{
  Serial.println("nu är det still"); 
}

void getCompassData()
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

  compassInValue = (atan2(x,y))*180/M_PI; // argument of (x-axis)/(y-axis) and to degrees.  
}

void parseInPackage(char inPackage[])
{
   inpackageNumber = inPackage[1];
   firstDestinationX = inPackage[4];
   firstDestinationY = inPackage[6];
   secondDestinationX = inPackage[9];
   secondDestinationY = inPackage[11];
   velocity = inPackage[14];   
}
 
void getInPackage()
{
  i = 0;
  char inPackage[INPACKAGE_LENGTH-1];

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

void buildDataPackage()
{
  dataPackage[1] = packageNumber++;
  dataPackage[4] = xPos; // GPS x-pos   
  dataPackage[6] = yPos; // GPS y-pos
  dataPackage[8] = dataAge; // Age of GPS data
  dataPackage[11] = compassInValue;  // compass
  dataPackage[15] = front;  // US sensors
  dataPackage[17] = frontLeft;
  dataPackage[19] = frontRight;
  dataPackage[21] = left;
  dataPackage[23] = right;
  dataPackage[25] = back;
  dataPackage[28] = '_'; // Voltage for batary levl
  dataPackage[31] = '_'; // Distanc
  dataPackage[34] = '_'; // Status
  dataPackage[37] = inpackageNumber;  
}

void loop()
{
  // BT 
  prepareDataPackage();
//  getCompassData();
  //sendDataPackage(); // sist
  getInPackage();
    
  // I^2C
  getSensorPackage();
  parseSensorPackage(); 
  buildDataPackage();
  //  buildDrivePackage();

  for(int a = 0; a < PACKAGE_LENGTH; a++)
  {
  Serial.print(dataPackage[a]);
  }
  Serial.print("front:");
  Serial.println(front, DEC);
  
  Serial.print("x:");
  Serial.print(xPos, DEC);
  Serial.print(" y:");
  Serial.print(yPos, DEC);
  Serial.print(" age:");
  Serial.println(dataAge, DEC);
  delay(500);
}
