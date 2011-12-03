//N1#D2;3#E4;5#S5
#include <Wire.h>
#include <AverageList.h>

#define PACKAGE_LENGTH 46
#define INPACKAGE_LENGTH 16
#define SENSORPACKAGE_LENGTH 14
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
byte wayPointLon[4];
byte wayPointLat[4];
byte velocity = 30; 
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
byte stat = 3;

//GPS 
byte lonByte[4]; // x-axis
byte latByte[4]; // y-axis
long lat, lon;
byte dataAge;

// Compass
byte compassData[2];
int compassInValue;
int newCompassDirection;
int i;
long lat2 = 5859010;
long lon2 = 1617592;
long deltaLAT;
long deltaLON;
int fi_direction;

void setup()
{
	Serial.begin(115200); //Depends on the BT-module
	Wire.begin();
	prepareDataPackage();
}

void directionGpsWayPoint() // get angel between Gps and wqypint   
{
	lat = (
		   (((long)inSensorPackage[6])<<24) |
		   (((long)inSensorPackage[7])<<16) |
		   (((long)inSensorPackage[8])<<8) |
		   ((long)inSensorPackage[9]));
	lon = (
		   (((long)inSensorPackage[10])<<24) |
		   (((long)inSensorPackage[11])<<16) |
		   (((long)inSensorPackage[12])<<8) |
		   ((long)inSensorPackage[13]));
	
	deltaLAT = abs(lat-lat2);
	deltaLON = abs(lon-lon2); 
	fi_direction = atan(deltaLAT/deltaLON);
	
	// Get new direction
	stat = 1; // start to drive
	if(lon < lon2 && lat < lat2) // check if first qvadrant 
	{
		newCompassDirection = 90 - fi_direction;
	}
	else if(lon > lon2 && lat < lat2) // check second qvadrant
	{
		newCompassDirection = 270 + fi_direction;
	}
	else if(lon > lon2 && lat > lat2) // check third qvadrant
	{
		newCompassDirection = 270 - fi_direction;
	}  
	else if(lon < lon2 && lat > lat2) // check fouth qvadrant
	{
		newCompassDirection = 90 + fi_direction;
	}
	else
	{
	}
}


void getSensorPackage() // sensorpackage from sensorarduino 
{
	Wire.requestFrom(2, 14);    // request 9 bytes from adress 2
	i = 0;
	while(Wire.available())    // slave may send less than requested
	{ 
		inSensorPackage[i++] = Wire.receive();
	}
	if(inSensorPackage[0] < 100)
	{
		checkSensors();
	}
	else
	{
		
	}	
	parseSensorPackage(); // parse sensor data 
	checkDestination();
} 

void checkDestination()
{
	if ((lat == (lat2+1) && lon == (lon2+1)) || ((lat == (lat2-1)) && (lon == (lon2-1))) || ((lat == (lat2+1)) && (lon == (lon2-1))) || ((lat == (lat2-1)) && (lon == (lon2+1))))
	{
		stat = 3;
		velocity = -60;
	}
}

void parseSensorPackage()	// Build package from sensorarduino
{
	front = inSensorPackage[0];
	frontLeft = inSensorPackage[1];
	frontRight = inSensorPackage[2];
	left = inSensorPackage[3];
	right = inSensorPackage[4];
	back = inSensorPackage[5]; 
	
	lonByte[0] = inSensorPackage[6];
	lonByte[1] = inSensorPackage[7];
	lonByte[2] = inSensorPackage[8];
	lonByte[3] = inSensorPackage[9];
	
	latByte[0] = inSensorPackage[10];
	latByte[1] = inSensorPackage[11];
	latByte[2] = inSensorPackage[12];
	latByte[3] = inSensorPackage[13];
	dataAge = inSensorPackage[14]; 
}

void checkSensors() // sensor value to smal (Work whit)
{
	if(front < 100)
	{
		stopRun();
	}
}

void stopRun() // stop
{
	updateDirective();
	delay(500);
	// sätt status till hinder och skicka till kts?. 
}

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
		
		lat2 = (
				(((long)wayPointLat[0])<<24) |
				(((long)wayPointLat[1])<<16) |
				(((long)wayPointLat[2])<<8) |
				((long)wayPointLat[3]));
		
		lon2 = (
				(((long)wayPointLon[0])<<24) |
				(((long)wayPointLon[1])<<16) |
				(((long)wayPointLon[2])<<8) |
				((long)wayPointLon[3]));
	} 
	else
	{  
	}
	//directionGpsWayPoint(); // get the new direction
}

void parseInPackage(char inPackage[])	// Waypoint byte
{ 
	inpackageNumber = inPackage[1];
	
	wayPointLon[0] = inPackage[4];
	wayPointLon[1] = inPackage[5];
	wayPointLon[2] = inPackage[6];
	wayPointLon[3] = inPackage[7];
	
	wayPointLat[0] = inPackage[9];
	wayPointLat[1] = inPackage[10];
	wayPointLat[2] = inPackage[11];
	wayPointLat[3] = inPackage[12];
	
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
	
	dataPackage[4] = lonByte[0]; // GPS x-pos 
	dataPackage[5] = lonByte[1];
	dataPackage[6] = lonByte[2];
	dataPackage[7] = lonByte[3];
	
	dataPackage[9] = latByte[0]; // GPS y-pos
	dataPackage[10] = latByte[1];
	dataPackage[11] = latByte[2];
	dataPackage[12] = latByte[3];
	
	dataPackage[14] = dataAge; // Age of GPS data 
	dataPackage[17] = compassData[0];  // compass MSB
	dataPackage[18] = compassData[1];
	dataPackage[21] = front;// front;  // US sensors
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
	for(int a = 0; a < PACKAGE_LENGTH; a++)
	{
		Serial.print(dataPackage[a]);
	}
	Serial.println(stat, DEC);
	Serial.println(velocity, DEC);
	Serial.print("lat= ");
	Serial.print(latByte[3],DEC);
	Serial.print("/");
	Serial.print(lat2 & 0xf,DEC);
	Serial.print("  lon= ");
	Serial.print(lonByte[3],DEC);
	Serial.print("/");
	Serial.println(lon2 & 0xf,DEC);
}

void loop()
{
<<<<<<< HEAD
	getSensorPackage();	// för att få gps 
	getInPackage();		// för att få önskad waypiot
	
	updateDirective();  // skicka via I2C till styrarduino
	
	getCompassData();
	
	buildDataPackage();
	
	directionGpsWayPoint();
	
	sendDataPackage();
=======
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
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> d3ce049aa70394a2ca1e807f388f8de759ad90c0
=======
>>>>>>> d3ce049aa70394a2ca1e807f388f8de759ad90c0
=======
>>>>>>> d3ce049aa70394a2ca1e807f388f8de759ad90c0
}
