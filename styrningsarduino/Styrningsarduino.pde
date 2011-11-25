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
#define speedP 0.2

int HMC6352Address = 0x42;
int slaveAddress;

Servo Speed;
Servo Angle;

int compassData;

int direction; //inskickad riktning från huvudarduino
int desiredSpeed; //inskickad men omräknad från huvudarduino

int actualSpeed;
float RPM;

int revsTotal = 0; //antal snurrade varv på kardanaxeln, används inte atm
int revs = 0; //antal varv sedan senast beräknat RPM-värde.
long timeStamp = 0; //tid vid senast beräknat RPM-värde.


void hallInterrupt()
{
  revs++;
}
void setup()
{
	
	
	//Inställningar för I2C
	Wire.begin(wireAdress);       // join i2c bus with address #4
	//Wire.onReceive(receiveEvent); // register event
	//Wire.onRequest(requestEvent); // register event
	slaveAddress = HMC6352Address >> 1;   // This results in 0x21 as the address to pass to TWI
	//Servoinställningar
	Speed.attach(motorPin);
	Angle.attach(servoPin);
	Speed.write(noSpeed);
	Angle.write(servoCenter);

	//Hallsensorinställningar
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
        delay(400);
}
void getSpeed()
{
	revsTotal = revsTotal + revs;
	//revsTotal = revsTotal + revs;
	long deltaT = (millis() - timeStamp);
	/* varv per millisekund på kardanaxeln, omräknat till hastighet*/
 	RPM = ((revs*60000)/deltaT);
	actualSpeed = (RPM/6.3);
	revs = 0;
	timeStamp = millis();
	
}
void getDataCompass()
{
	byte headingData[2];
	Wire.beginTransmission(slaveAddress);
	Wire.send("A");              // The "Get Data" command
	Wire.endTransmission();
	delay(10);                   // The HMC6352 needs at least a 70us (microsecond) delay
	  // after this command.  Using 10ms just makes it safe
	  // Read the 2 heading bytes, MSB first
	  // The resulting 16bit word is the compass heading in 10th's of a degree
	  // For example: a heading of 1345 would be 134.5 degrees
	Wire.requestFrom(slaveAddress, 2);        // Request the 2 byte heading (MSB comes first)
	int i = 0;
	while(Wire.available() && i < 2)
	{ 
		headingData[i] = Wire.receive();
	    i++;
	}
	compassData = (headingData[0]*256 + headingData[1])/10;  // Put the MSB and LSB together
}
void setSpeed()
{

	int newSpeed = desiredSpeed-speedP*(desiredSpeed - actualSpeed);

	if(newSpeed < maximumForward)
		newSpeed = maximumForward;
	if(newSpeed > maximumBackwards)
		newSpeed = maximumBackwards;


	Speed.write(newSpeed);
        Serial.print("newSpeed: "); Serial.println(newSpeed);  
}
void setDirection()
{
	int	newAngle = 90 + angleP*(direction-compassData); //Kan hända att det ska vara -
		
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
		data[i++] = Wire.receive(); // receive byte as a character
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
