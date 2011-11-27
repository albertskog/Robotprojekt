//N1#D2;3#E4;5#S5
#include <Wire.h>
#include <AverageList.h>

#define PACKAGE_LENGTH 40
#define INPACKAGE_LENGTH 15
#define SENSORPACKAGE_LENGTH 9
#define DIRECTIONDATA_LENGTH 3

typedef int sample;
const byte MAX_NUMBER_OF_READINGS = 5;
sample storage[MAX_NUMBER_OF_READINGS] = {
  0};
AverageList<sample> distance = AverageList<sample>( storage, MAX_NUMBER_OF_READINGS );

long t = 0;

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

// out I2C
byte directiveData[DIRECTIONDATA_LENGTH];

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
  prepareDataPackage();
}

void getSensorPackage()
{
  Wire.requestFrom(2, 9);    // request 9 bytes
  i = 0;
  while(Wire.available())    // slave may send less than requested
  { 
    inSensorPackage[i++] = Wire.receive();
  }
  if(inSensorPackage[0] < 100)
  {
    cheakSensors();
  }
  else
  {
    velocity = 15; 
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
}

void cheakSensors()
{
  if(front < 100)
  {
    stopRun();
  }
}

void stopRun()
{
  velocity = 0;
  updateDirective();
  delay(500);
  // sätt status till hinder och skicka till kts. 
}

void updateDirective()
{
  directiveData[0] = (compassInValue >> 8);
  directiveData[1] = compassInValue;
  directiveData[2] = velocity;

  Wire.beginTransmission(1);           // transmit to device #4
  Wire.send(directiveData, 3);         // sends five bytes 
  Wire.endTransmission();              // stop transmitting
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

void getInPackage() // BT
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
  dataPackage[11] = (compassInValue >> 8);  // compass
  dataPackage[12] = compassInValue;
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
  //getCompassData();

  getCompassData();
  getInPackage();

  // I^2C
  getSensorPackage();
  parseSensorPackage(); 

  buildDataPackage();

  //  sendDataPackage(); // sist

  //  buildDrivePackage();
  updateDirective();
  if((millis()-t) > 500)
  {
     buildDataPackage();
    for(int a = 0; a < PACKAGE_LENGTH; a++)
    {
      Serial.print(dataPackage[a]);
    }
    Serial.println(front, DEC);
    t = millis();
	Serial.println(compassInValue, DEC);
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

