/*Styrningsarduino, den nuvarande koden krï¿½ver att hallPin ï¿½r pï¿½ pin3 pï¿½ arduinon dvs, inte om det nuvarande PCB-kortet (rev1)*/

#include <Servo.h>
#include <Wire.h>

#define servoPin 4
#define motorPin 5
#define hallPin 3

#define wireAdress 1
#define servoMax 110
#define servoMin 60
#define maximumForward 40
#define maximumBackwards 137
#define servoCenter 90


#define noSpeed 88 //värde då fartreglaget är i neutral
#define rpmToSpeed 1 //värde för omräkning från rpm till grader till fartreglage! Ska testas fram

#define angleP 2 //värde för P-reglering. dvs differens mellan kompassvärde och styrvinkel
#define speedP 0.1

Servo Speed;
Servo Angle;

int compassData;

int direction; //inskickad riktning från huvudarduino
int desiredSpeed; //inskickad men omräknad från huvudarduino

int actualSpeed;
float RPM;

int revsTotal = 0; //antal snurrade varv på kardanaxeln, används inte atm
int revs = 0; //antal varv sedan senast beräknat RPM-värde.
int timeStamp = 0; //tid vid senast beräknat RPM-värde.


void hallInterrupt()
{
  revs++;
}
void setup()
{
	//Instï¿½llningar fï¿½r I2C
	Wire.begin(wireAdress);       // join i2c bus with address #4
	Wire.onReceive(receiveEvent); // register event
	Wire.onRequest(requestEvent); // register event
	
	//Servoinstï¿½llningar
	Speed.attach(motorPin);
	Angle.attach(servoPin);
	Speed.write(noSpeed);
	Angle.write(servoCenter);

	//Hallsensorinstï¿½llningar
	pinMode(hallPin, OUTPUT);
	digitalWrite(hallPin, HIGH);
	attachInterrupt(1, hallInterrupt, RISING);
	
	
	
	//DEBUGKOD
	Serial.begin(9600);
	desiredSpeed = 80;
	direction = 90;
}

void loop()
{
	getSpeed();
	getDataCompass();
	setDirection();
	setSpeed();
	sendData();
}
void getSpeed()
{
	revsTotal = revsTotal + revs;
	//revsTotal = revsTotal + revs;
	long deltaT = (millis() - timeStamp);
	/* varv per millisekund på kardanaxeln, omräknat till hastighet*/
 	RPM = ((revs*60000)/deltaT);
	//map(value, fromLow, fromHigh, toLow, toHigh)
	actualSpeed = (RPM/6.3);



	revs = 0;
	timeStamp = millis();
	
}
void getDataCompass()
{


	Wire.requestFrom(0x1E, 7);    // request 7 bytes
	int i = 0;

	byte data[7]; //array to temporarily store parameters from compass

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

	int newSpeed = desiredSpeed+speedP*(desiredSpeed - actualSpeed);

	if(newSpeed < maximumForward)
		newSpeed = maximumForward;
	if(newSpeed > maximumBackwards)
		newSpeed = maximumBackwards;


	Speed.write(newSpeed);
}
void setDirection()
{

	int newAngle = 90+angleP*(direction-compassData); /*Kan hï¿½nda att det ska vara 90-compassP*... */

	if(newAngle < servoMin)
		newAngle = servoMin;
	if(newAngle > servoMax)
		newAngle = servoMax;

	Angle.write(newAngle);
	Serial.print("Styrvinkel: "); Serial.println(newAngle);
}
void requestEvent()
{
	Wire.send(actualSpeed/* multiplicerat med konstant för att få i önskvärd storhet */);
	Wire.send(revsTotal/* multiplicerat med konstant för att få i önskvärd storhet */);
}
void receiveEvent(int HowMany)
{
	byte data[2];
	unsigned int i = 0;
	while(Wire.available()) // loop through all but the last
	{
		data[i] = Wire.receive(); // receive byte as a character
		i++;
	}
	//omräkning till procent
	if(data[1] >= 0) //Frammåt!
	desiredSpeed = map(data[1], 0, 100, noSpeed, maximumForward);
	if(data[1] < 0)
	desiredSpeed = map(data[1], 0, -100, noSpeed, maximumBackwards);

	direction = data[0];
	desiredSpeed = data[1]; 
	/* omräkning till procent */
	if(data[1] >= 0) //Frammåt!
	desiredSpeed = map(data[1], 0, 100, noSpeed, maximumForward);
	if(data[1] < 0)
	desiredSpeed = map(data[1], 0, -100, noSpeed, maximumBackwards);

}
void sendData()
{
	//Funktion för att få debugdata
	Serial.println("Data:");
	Serial.print("Hastighet (grader):"); Serial.println(actualSpeed);
	Serial.print("Önskad hastighet (grader):"); Serial.println(desiredSpeed);
	Serial.print("Inskickad riktning: "); Serial.println(direction);
	Serial.print("Kompassriktning: "); Serial.println(compassData);
}
