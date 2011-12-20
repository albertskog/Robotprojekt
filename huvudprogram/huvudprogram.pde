//N1#D2;3#E4;5#S5
// watchdog http://tushev.org/articles/electronics/48-arduino-and-watchdog-timer
#include <Wire.h>
#include <AverageList.h>
#include <avr/wdt.h>

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
long inPackageTimeout = 0;
long directiveTimeout = 0;
int angleUpdate = 0;

byte speed = 35;
byte reverse = 130;

// Led pins
byte redPin = 2;
byte yellowPin = 3;
byte greenPin = 4;

// summer pin
byte sum = 5;

//out package
char dataPackage[PACKAGE_LENGTH];
byte packageNumber = 0;

//in package
byte inpackageNumber;
byte wayPointLon[4];
byte wayPointLat[4];
byte velocity = 0;

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
byte back = 255;

byte voltage;

// status: 3 = driving, still = 1
boolean reacheWP = false;
byte stat = 1;
byte sens = 0;

//GPS 
byte lonByte[4]; // x-axis
byte latByte[4]; // y-axis
long lat, lon; // Robot possision 
byte dataAge;

// Compass
byte compassData[2];
int compassInValue;
int i;
long latWP = 0;
long lonWP = 0;
long latWPref = 0;
long lonWPref = 0;

// calculation of direction
int newCompassDirection;
long deltaLAT;
long deltaLON;
double angle;
double pi = 3.1415926;
int fi_direction;


void setup()
{
	pinMode(redPin, OUTPUT); // led pins for status!
	pinMode(yellowPin, OUTPUT); // digitalWrite(ledPin, HIGH);
	pinMode(greenPin, OUTPUT);
	pinMode(sum, OUTPUT);
	Serial.begin(115200); //Depends on the BT-module
	Wire.begin();
	prepareDataPackage();
	digitalWrite(redPin, HIGH);
	digitalWrite(yellowPin, HIGH);
	digitalWrite(greenPin, HIGH);
	wdt_enable(WDTO_8S);
	velocity = 0;
}
// get angel between Gps and waypint at start
void directionGpsWayPoint()    
{	
	//check gps while running
	if (stat == 3 || stat == 2)
	{
		
		getSensorPackage();
		
		// error stop!
		if (lon == 0 && lat == 0)
		{
			velocity = 0;
			stat = 1;
			updateDirective();
			digitalWrite(yellowPin,LOW);
		} 
	}
	///get proper gps position and calculate new desired compass heading
	if(stat == 1)
	{
		byte n = 5;
		deltaLAT = 0;
		deltaLON = 0;
		for (byte i = 0; i<n; i++)
		{
			//get new gps data
			getSensorPackage();
			
			//parse gps data
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
			
			//add to mean 
			deltaLAT += lat-latWP;
			deltaLON += lon-lonWP; 
		}
		
		deltaLAT = (deltaLAT)/n;
		deltaLON = (deltaLON)/n;
		
		angle = atan2(abs(deltaLAT),abs(deltaLON));
		fi_direction = angle*180/pi;
		
		// Calculate the new compass direction
		if(deltaLON <= 0 && deltaLAT <= 0) // check if first qvadrant 
		{
			newCompassDirection = 90 - fi_direction;
		}
		else if(deltaLON > 0 && deltaLAT < 0) // check second qvadrant
		{
			newCompassDirection = 270 + fi_direction;
		}
		else if(deltaLON >= 0 && deltaLAT >= 0) // check third qvadrant
		{
			newCompassDirection = 270 - fi_direction;
		}  
		else if(lon < lonWP && lat > latWP)//(deltaLON < 0 && deltaLAT > 0) // check fouth qvadrant
		{
			newCompassDirection = 90 + fi_direction;
		}
		
		digitalWrite(greenPin,LOW);
		stat = 3; // start drive!
	}
}
// angel between GPS and waypoint while running
void directionWhileRunning() 
{
	//get new gps data
	getSensorPackage();
	
	//parse gps data
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
	
	
	deltaLAT = abs(deltaLAT);
	deltaLON = abs(deltaLON);
	
	angle = atan2(deltaLAT,deltaLON);
	fi_direction = angle*180/pi;
	
	// Calculate the new compass direction
	if(lon <= lonWP && lat <= latWP) // check if first qvadrant 
	{
		newCompassDirection = fi_direction;
	}
	else if(lon > lonWP && lat < latWP) // check second qvadrant
	{
		newCompassDirection = 270 + fi_direction;
	}
	else if(lon >= lonWP && lat >= latWP) // check third qvadrant
	{
		newCompassDirection = 270 - fi_direction;
	}  
	else if(lon < lonWP && lat > latWP) // check fouth qvadrant
	{
		newCompassDirection = 90 + fi_direction;
	}
	else
	{
	}
}
// sensorpackage from sensorarduino
void getSensorPackage()  
{
	Wire.requestFrom(2, 14);    // request 9 bytes from adress 2
	i = 0;
	
	while(Wire.available())    // slave may send less than requested
	{ 
		inSensorPackage[i++] = Wire.receive();
	}
	
	parseSensorPackage(); // parse sensor data 
	if(stat != 1) // if not stationary
	{
		checkSensors();
		checkDestination();
	}
} 
// 
void checkDestination()
{
	if(abs(lat-latWP) <= 5 && abs(lon-lonWP) <= 5)
	{
		stat = 1;
		reacheWP = true;
		velocity = 0;
		updateDirective();		// to 
		latWPref = latWP;		// ref in getInPackage
		lonWPref = lonWP;		//
		
		digitalWrite(redPin, LOW);
		digitalWrite(sum, HIGH);
		delay(2000);
		digitalWrite(sum,LOW);
		Serial.flush();
	}
}
// Build package from sensorarduino to ADM
void parseSensorPackage()	
{
	right = inSensorPackage[0];		// US sensors! 
	frontRight = inSensorPackage[1];
	front = inSensorPackage[2];
	frontLeft = inSensorPackage[3];
	left = inSensorPackage[4];
	
	voltage = inSensorPackage[5]; 
	
	lonByte[0] = inSensorPackage[6];		// GPS data
	lonByte[1] = inSensorPackage[7];
	lonByte[2] = inSensorPackage[8];
	lonByte[3] = inSensorPackage[9];
	
	latByte[0] = inSensorPackage[10];
	latByte[1] = inSensorPackage[11];
	latByte[2] = inSensorPackage[12];
	latByte[3] = inSensorPackage[13];
	
	dataAge = inSensorPackage[14];			// GPS age
}
// sensor value to smal (Work whit)
void checkSensors() 
{
	if(front < 100)
	{                 
		turn();
	}
	else if(frontRight < 60)
	{
		sens = 1;
		leftTurn();
	}
	else if(frontLeft < 60)
	{
		sens = 1;
		rightTurn();
	}
	else if(left < 30)
	{
		sens = 2;
		rightTurn();
	}
	else if(right < 30)
	{
		sens = 2;
		leftTurn();
	}
	else
	{
	}
	
}
// Build package to controlarduino and sends it 
void updateDirective() 
{
	directiveData[0] = (newCompassDirection >> 8);
	directiveData[1] = newCompassDirection;
	directiveData[2] = velocity;
	
	Wire.beginTransmission(1);           // transmit to device #4
	Wire.send(directiveData, 3);         // sends five bytes 
	Wire.endTransmission();              // stop transmitting
}
// get compass data from I2C
void getCompassData()
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
	compassInValue = (compassData[0]*256 + compassData[1])/10;  // Put the MSB and LSB together
}
// Package from BT, includes parseInPackage
void getInPackage()
{
	while(reacheWP) // wait for new waypoint! 
	{
		digitalWrite(sum, HIGH);
		delay(100);
		digitalWrite(sum,LOW);
        i = 0;
        char inPackage[INPACKAGE_LENGTH-1];
		while(Serial.available())
		{
			inPackage[i++] = Serial.read();
		}
		
		
		if((inPackage[0] == 'N') && (inPackage[3] == 'D') && (inPackage[14] == 'S')) // cheking array
		{
			digitalWrite(yellowPin,LOW);
			parseInPackage(inPackage); 
			
			latWP = (
					 (((long)wayPointLat[0])<<24) |
					 (((long)wayPointLat[1])<<16) |
					 (((long)wayPointLat[2])<<8) |
					 ((long)wayPointLat[3]));
			
			lonWP = (
					 (((long)wayPointLon[0])<<24) |
					 (((long)wayPointLon[1])<<16) |
					 (((long)wayPointLon[2])<<8) |
					 ((long)wayPointLon[3]));
			
			if(latWPref != latWP || lonWPref != lonWP)
			{
				digitalWrite(sum,HIGH);
				reacheWP = false;
				latWP = 0;
				lonWP = 0;
				delay(1000);
				digitalWrite(sum,LOW);
				Serial.flush();
			}
			
			if((inPackage[0] != 'N') || (inPackage[3] != 'D') || (inPackage[14] != 'S')) 
			{
				digitalWrite(greenPin, LOW);
				Serial.flush();
			}
		}
		wdt_reset();
	}
	if (stat == 2)
	{
		Serial.flush();
		delay(500);
		latWP = 0;
		lonWP = 0;
	}
	i = 0;
	char inPackage[INPACKAGE_LENGTH-1];
	
	while(Serial.available()) // read serial package BT
	{
		inPackage[i++] = Serial.read();
	}
	
	if((inPackage[0] == 'N') && (inPackage[3] == 'D') && (inPackage[14] == 'S')) // cheking array
	{
		latWPref = latWP;	// reference waypoint
		lonWPref = lonWP;
		
		parseInPackage(inPackage); 
		
		latWP = (
				 (((long)wayPointLat[0])<<24) |
				 (((long)wayPointLat[1])<<16) |
				 (((long)wayPointLat[2])<<8) |
				 ((long)wayPointLat[3]));
		
		lonWP = (
				 (((long)wayPointLon[0])<<24) |
				 (((long)wayPointLon[1])<<16) |
				 (((long)wayPointLon[2])<<8) |
				 ((long)wayPointLon[3]));
		
		//Check for emergency stop
		if (latWP == 0 || lonWP == 0) 
		{
			stat = 4;
			velocity = 0;
			updateDirective();
		}
		if ((latWPref != latWP || lonWPref != lonWP) && stat != 4 && reacheWP == false) // check if new waipoint
		{
			stat = 1; // still to calc direction 
			velocity = 0;
			updateDirective();
			/*	digitalWrite(sum,HIGH); // ?
			 delay(200);
			 digitalWrite(sum,LOW);*/
		}
		if(reacheWP == false)
		{
			directionGpsWayPoint(); // get a new direction
			updateDirective();
		}
		inPackageTimeout = millis(); //reset bluetooth timeout
	} 
	
}
// Waypoint byte
void parseInPackage(char inPackage[])	
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
	
	reverse = inPackage[15]+100;
	/*
	 wayPointX2 = inPackage[9];
	 wayPointY2 = inPackage[11];
	 velocity = inPackage[14];   
	 */
}
// basis for the Data package BT (one time only). +6 på allt
void prepareDataPackage()  
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
	dataPackage[31] = back;
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
// Build data package BT.
void buildDataPackage() 
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
	
	dataPackage[34] = voltage; // Voltage for batary levl
	dataPackage[37] = '_'; // Distanc
	dataPackage[40] = stat; // Status
	dataPackage[43] = inpackageNumber;  
}
// at BT.
void sendDataPackage() 
{
	if (millis() - t > 500)
	{
		for(int a = 0; a < PACKAGE_LENGTH; a++)
		{
			Serial.print(dataPackage[a]);
		}
		
		t = millis();
	}
}
// turn if frontsensor is activated
void turn()
{
	velocity = reverse;	// brake
	updateDirective();// to sensorarduino
	delay(200);
	velocity = 0;
	updateDirective();
	
	delay(300);
	velocity = reverse;
	updateDirective();
	velocity = 0;
	delay(1500);
	updateDirective();
	
	// check which turn
	if (frontLeft < frontRight || left < right)
	{
		newCompassDirection = compassInValue + 90;
	}
	else if (frontLeft > frontRight || left > right)
	{
		newCompassDirection = compassInValue + 270;
	}
	else // dosent matter 
	{
		newCompassDirection = compassInValue + 90;
	}
	
	velocity = speed;
	delay(2000);
	updateDirective();
	delay(2000);
	velocity = 0;
	updateDirective();
	stat = 2;
}
// turn if right sensors are activated 
void leftTurn()
{
	if(sens == 1)
	{
		velocity = reverse;	// brake
		updateDirective();// to sensorarduino
		digitalWrite(redPin, LOW);
		delay(200);
		velocity = 0;
		updateDirective();
		delay(500);
		velocity = reverse;
		updateDirective();
		velocity = 0;
		delay(1500);
		updateDirective();
		
		newCompassDirection = (compassInValue + 270)%360;
		velocity = speed;
		delay(1500);
		updateDirective();
		delay(2000);
		velocity = 0;
		updateDirective();
		stat = 2;
		sens = 0;
	}
	else if(sens == 2)
	{
		newCompassDirection = (compassInValue + 350)%360;
		updateDirective();
		stat = 2;
		sens = 0;
	}
}
// turn if left sensors are activated
void rightTurn()
{ 
	if(sens == 1)
	{
		velocity = reverse;	// brake
		updateDirective();
		digitalWrite(redPin, LOW);
		delay(200);
		velocity = 0;
		updateDirective();
		delay(500);
		velocity = reverse; 
		updateDirective();
		velocity = 0;
		delay(1500);
		updateDirective();
		
		newCompassDirection = (compassInValue + 90)%360;
		velocity = speed;	
		delay(1500);
		updateDirective();
		delay(2000);
		velocity = 0;
		updateDirective();
		stat = 2;
		sens = 0;
	}
	else if(sens == 2)
	{
		newCompassDirection = (compassInValue + 10)%360;
		updateDirective();
		stat = 2;
		sens = 0;
	}
}

void loop()
{
	//Check for bluetooth timeout
	/*	if (millis() - inPackageTimeout > 5000)
	 {
	 velocity = 0;
	 stat = 4;		//Error status!
	 updateDirective();
	 } */
	if (Serial.available())
	{
		getInPackage();
	}
	
	getSensorPackage();
	
	if (stat == 3 && (millis()-directiveTimeout > 5000)) // if running
	{
		updateDirective();  // skicka via I2C till styrarduino
		directiveTimeout = millis();
	}
	if (angleUpdate > 10) // update direction during run
	{
		directionWhileRunning();	
		angleUpdate = 0;
	}
	getCompassData();
	buildDataPackage();
	
	sendDataPackage();
	inPackageTimeout = millis(); // test!
	angleUpdate++;
	wdt_reset();
}