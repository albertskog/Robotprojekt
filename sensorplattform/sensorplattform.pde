//N1#D2;3#E4;5#S5
#include <Wire.h>
#include <AverageList.h>

#define PACKAGE_LENGTH 46
#define INPACKAGE_LENGTH 16
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
byte inpackageNumber;
byte wayPointX1[4];
byte wayPointY1[4];
byte velocity;
/*
 byte wayPointX2[4];
 byte wayPointY2[4];
 byte velocity;
 */

//in I2C
byte inSensorPackage[SENSORPACKAGE_LENGTH];

// out I2C
byte directiveData[DIRECTIONDATA_LENGTH];

//US sensors
byte front;
byte frontRight;
byte frontLeft;
byte right;
byte left;
byte back;

//GPS 
byte gpsPosX[4];
byte gpsPosY[4];
byte dataAge;

// Compass
byte compassData[2];
int compassInValue;
int newCompassDirection;
int i;
float deltaX;
float deltaY;


void setup()
{
	Serial.begin(115200); //Depends on the BT-module
	Wire.begin();
	prepareDataPackage();	
}
/* bort för test som sensorplattform
 void directionGpsWayPoint() // get angel between Gps and wqypint   
 {
 deltaY = abs(gpsPosY-wayPointY);
 deltaX = abs(gpsPosX-wayPointX); 
 fi_direction = atan(deltaY/deltaX);
 
 // Get new direction
 if(gpsPosX < wayPointX && gpsPosY < wayPointY) // cheak if first qvadrant 
 {
 newCompasDirection = 90 - fi_direction;
 }
 if else(gpsPosX > wayPointX && gpsPosY < wayPointY) // cheak second qvadrant
 {
 newCompasDirection = 270 + fi_direction;
 }
 if else(gpsPosX > wayPointX && gpsPossY > wayPointY) // cheak third qvadrant
 {
 newCompasDirection = 270 - fi_direction;
 }  
 if else(gpsPosX < wayPointX && gpsPosY > wayPointY) // cheak fouth qvadrant
 {
 newCompasDirection = 90 + fi_direction;
 }
 else
 }
 */
/* inte i sensorprog
 void getSensorPackage() // sensorpackage from sensorarduino 
 {
 Wire.requestFrom(2, 9);    // request 9 bytes from adress 2
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
 velocity = 15;		// test
 }	
 parseSensorPackage(); // parse sensor data 
 }
 
 void parseSensorPackage()	// Build package from sensorarduino
 {
 front = inSensorPackage[0];
 frontLeft = inSensorPackage[1];
 frontRight = inSensorPackage[2];
 left = inSensorPackage[3];
 right = inSensorPackage[4];
 back = inSensorPackage[5]; 
 gpsPosX = inSensorPackage[6]; // ev ändra
 gpsPosY = inSensorPackage[7]; 
 dataAge = inSensorPackage[8]; 
 }
 
 void cheakSensors() // sensor value to smal (Work whit)
 {
 if(front < 100)
 {
 stopRun();
 }
 }
 
 void stopRun() // stop
 {
 velocity = 0;
 updateDirective();
 delay(500);
 // sätt status till hinder och skicka till kts?. 
 }
 */
void updateDirective() // Build package to controlarduino and sends it 
{
	directiveData[0] = (newCompassDirection >> 8);
	directiveData[1] = newCompassDirection;
	directiveData[2] = velocity;
	
	Wire.beginTransmission(1);           // transmit to device #4
	Wire.send(directiveData, 3);         // sends five bytes 
	Wire.endTransmission();              // stop transmitting
}

void getCompassData() // get compass data from I2C
{
	Wire.beginTransmission(0x21);
	Wire.send("A");              // The "Get Data" command
	Wire.endTransmission();
	delay(10);                   // The HMC6352 needs at least a 70us (microsecond) delay
	
	Wire.requestFrom(0x21, 2);        // Request the 2 byte heading (MSB comes first)
	i = 0;
	while(Wire.available() && i < 2)
	{ 
		compassData[i] = Wire.receive();
		i++;
	}	
}

void getInPackage() // Package from BT, includes parseInPackage
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
	else // if not start whit N
	{
		Serial.flush(); // clearing the serial 
	}
	// cheking array
	if((inPackage[0] == 'N') && (inPackage[3] == 'D') && /*(inPackage[8] == 'E') &&*/ (inPackage[14] == 'S'))
	{
		parseInPackage(inPackage);
	} 
	else
	{  
	}
	//directionGpsWayPoint(); // get the new direction
}

void parseInPackage(char inPackage[])	// Waypoint byte
{ 
	inpackageNumber = inPackage[1];
	
	wayPointX1[0] = inPackage[4];
	wayPointX1[1] = inPackage[5];
	wayPointX1[2] = inPackage[6];
	wayPointX1[3] = inPackage[7];
	
	wayPointY1[0] = inPackage[9];
	wayPointY1[1] = inPackage[10];
	wayPointY1[2] = inPackage[11];
	wayPointY1[3] = inPackage[12];
	
	velocity = inPackage[15];
	/*
	 wayPointX2 = inPackage[9];
	 wayPointY2 = inPackage[11];
	 velocity = inPackage[14];   
	 */
}

void prepareDataPackage() // basis for the Data package BT (one time only). +6 på allt 
{
	dataPackage[0] = 'N';
	dataPackage[2] = '#';
	dataPackage[3] = 'P';
	dataPackage[8] = ';';
	dataPackage[13] = ';';
	dataPackage[15] = '#';
	dataPackage[16] = 'C'; 
	dataPackage[19] = '#';
	dataPackage[20] = 'U';
	dataPackage[22] = ';';
	dataPackage[24] = ';';
	dataPackage[26] = ';';
	dataPackage[28] = ';';
	dataPackage[30] = ';';
	dataPackage[32] = '#';
	dataPackage[33] = 'V';
	dataPackage[35] = '#';
	dataPackage[36] = 'D';
	dataPackage[38] = '#';
	dataPackage[39] = 'S';
	dataPackage[41] = '#';
	dataPackage[42] = 'L';
	dataPackage[44] = '#';
	dataPackage[45] = 10;

}

void buildDataPackage() // Build data package BT.
{

	dataPackage[1] = packageNumber++;
	
	dataPackage[4] = wayPointX1[0];//gpsPosX[0]; // GPS x-pos 
	dataPackage[5] = wayPointX1[1];//gpsPosX[1];
	dataPackage[6] = wayPointX1[2];//gpsPosX[2];
	dataPackage[7] = wayPointX1[3];//gpsPosX[3];
	
	dataPackage[9] = wayPointY1[0];//gpsPosY[0]; // GPS y-pos
	dataPackage[10] = wayPointY1[1];//gpsPosY[1];
	dataPackage[11] = wayPointY1[2];//gpsPosY[2];
	dataPackage[12] = wayPointY1[3];//gpsPosY[3];
	
	dataPackage[14] = dataAge; // Age of GPS data 
	dataPackage[17] = compassData[0];  // compass MSB
	dataPackage[18] = compassData[1];
	dataPackage[21] = velocity;// front;  // US sensors
	dataPackage[23] = frontLeft;
	dataPackage[25] = frontRight;
	dataPackage[27] = left;
	dataPackage[29] = right;
	dataPackage[31] = back;
	dataPackage[34] = '_'; // Voltage for batary levl
	dataPackage[37] = '_'; // Distanc
	dataPackage[40] = '_'; // Status
	dataPackage[43] = inpackageNumber;  
}

void sendDataPackage() // at BT.
{
	//	if((millis()-t) > 500)
	//{
		for(int a = 0; a < PACKAGE_LENGTH; a++)
		{
			Serial.print(dataPackage[a]);
		}
		//		Serial.println(front, DEC);
		//t = millis();
		//		Serial.println(compassInValue, DEC);
	//}

}

void loop()
{

	//	getSensorPackage();	// för att få gps

	getInPackage();		// för att få önskad waypiot
      
	//	updateDirective();  // skicka via I2C till styrarduino
	
	getCompassData();
	
	buildDataPackage();
        delay(500);
	sendDataPackage();        

}
