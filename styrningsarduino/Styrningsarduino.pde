/*Styrningsarduino, den nuvarande koden kr�ver att hallPin �r p� pin3 p� arduinon dvs, inte om det nuvarande PCB-kortet (rev1)*/

#include <Servo.h>
#include <Wire.h>

#define servoPin 4
#define motorPin 5
#define hallPin 3

#define wireAdress 3
#define servoMax 110
#define servoMin 60
#define maximumForward 120
#define maximumBackwards 40
#define servoCenter 90
#define noSpeed 88 //v�rde d� fartreglaget �r i neutral

#define angleP 1 //v�rde f�r P-reglering. dvs differens mellan kompassv�rde och styrvinkel
#define speedP 1 //v�rde f�r P-reglering. dvs hur mycket differansen mellan verklig hastighet och t�nkt spelar inp� inskickat v�rde till motorstyrningen

Servo Speed;
Servo Angle;

int compassData;
int direction; //inskickad riktning fr�n huvudarduino
int desiredSpeed; //inskickad hastighet fr�n huvudarduino 0 = max bak�t 127 = stillast�ende 255 = max framm�t
int actualSpeed;

long revsTotal = 0; //antal snurrade varv p� kardanaxeln, anv�nds inte atm
int revs = 0; //antal varv sedan senast ber�knat RPM-v�rde.
int timeStamp= 0; //tid vid senast ber�knat RPM-v�rde.

void hallInterrupt()
{
  revs++;
}
void setup()
{
	//Inst�llningar f�r I2C
	Wire.begin(wireAdress);       // join i2c bus with address #4
	Wire.onReceive(receiveEvent); // register event
	Wire.onRequest(requestEvent); // register event
	
	//Servoinst�llningar
	Speed.attach(motorPin);
	Angle.attach(servoPin);
	Speed.write(noSpeed);
	Angle.write(servoCenter);

	//Hallsensorinst�llningar
	pinMode(hallPin, OUTPUT);
	digitalWrite(hallPin, HIGH);
	attachInterrupt(1, hallInterrupt, RISING);
}

void loop()
{
	getSpeed();
	getDataCompass();
	setDirection();
	setSpeed();
}
void getSpeed()
{
	revsTotal = revsTotal + revs;
	int deltaT = millis() - timeStamp;
	
	/* varv per millisekund p� kardanaxeln, omr�knat till hastighet*/
 	actualSpeed = /* konstant * (revs/deltaT) */(revs/deltaT);
	
	revs = 0;
	timeStamp = millis();
	/* R�knar ut aktuell hastighet utifr�n hall-sensordata */
}
void getDataCompass()
{
	/* H�mta kompassdata, sm�tt modifierad fr�n sensorplattformen */
	
	Wire.requestFrom(0x1E, 7);    // request 7 bytes
	unsigned int i = 0;
	byte data[7]; //array to temporarily store parameters from compass
	while(Wire.available())    // slave may send less than requested
	{ 
		data[i++] = Wire.receive();
	}
	//Parse data from DXRA, DXRB, DYRA, DYRB, DZRA, DZRB intp x, y, z
	int x = - ((((int)data[0]) << 8) | data[1]);
	int y = - ((((int)data[2]) << 8) | data[3]);
	int z = - ((((int)data[4]) << 8) | data[5]);  
	
	compassData = (atan2(x,y))*180/M_PI; // argument of (x-axis)/(y-axis) and to degrees. 
}
void setSpeed()
{
	/*  V�lj hastighet utifr�n nuvarande hastighet, r�kna om till grader, PID-reglering */
	newSpeed = noSpeed+speedP*(desiredSpeed - actualSpeed);
	if(newSpeed < maximumForward)
		newSpeed = maximumForward;
	if(newSpeed > maximumBackwards)
		newSpeed = maximumBackwards;

	Speed.write(newSpeed);
}
void setDirection()
{
	int newAngle = servoCenter+angleP*(direction-compassData); /*Kan h�nda att det ska vara 90-compassP*... */
	
	if(newAngle < servoMin)
		newAngle = servoMin;
	if(newAngle > servoMax)
		newAngle = servoMax;
		
	Angle.write(newAngle);
}
void requestEvent()
{
	Wire.send(actualSpeed);
	Wire.send(revsTotal/* multiplicerat med konstant f�r att f� i �nskv�rd storhet */);
}
void receiveEvent(int howMany/* howMany kommer inte anv�ndas */)
{
	byte data[2];
	unsigned int i = 0;
	while(Wire.available()) // loop through all but the last
	{
		data[i] = Wire.receive(); // receive byte as a character
		i++;
	}
	direction = data[0];
	desiredSpeed = data[1]; /*OBS! m�ste r�knas om till RPM, eller vad vi nu ska anv�nda!*/ 
}