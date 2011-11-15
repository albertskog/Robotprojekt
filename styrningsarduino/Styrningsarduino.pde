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
<<<<<<< HEAD
<<<<<<< HEAD

#define noSpeed 88 //värde då fartreglaget är i neutral
#define rpmToSpeed 1 //värde för omräkning från rpm till grader till fartreglage! Ska testas fram

#define angleP 2 //värde för P-reglering. dvs differens mellan kompassvärde och styrvinkel
#define speedP 0.1
=======
#define noSpeed 88 //vï¿½rde dï¿½ fartreglaget ï¿½r i neutral

#define angleP 1 //vï¿½rde fï¿½r P-reglering. dvs differens mellan kompassvï¿½rde och styrvinkel
#define speedP 1 //vï¿½rde fï¿½r P-reglering. dvs hur mycket differansen mellan verklig hastighet och tï¿½nkt spelar inpï¿½ inskickat vï¿½rde till motorstyrningen
=======
#define noSpeed 88 //värde då fartreglaget är i neutral
#define rpmToSpeed 1 //värde för omräkning från rpm till grader till fartreglage! Ska testas fram

#define angleP 5 //värde för P-reglering. dvs differens mellan kompassvärde och styrvinkel

>>>>>>> parent of f241aa9... fixat?
>>>>>>> 860dd51e62593c5aaa6411c9529ac794e697dbb1

Servo Speed;
Servo Angle;

int compassData;
<<<<<<< HEAD
int direction; //inskickad riktning från huvudarduino
int desiredSpeed; //inskickad men omräknad från huvudarduino
<<<<<<< HEAD
=======
int direction; //inskickad riktning frï¿½n huvudarduino
int desiredSpeed; //inskickad hastighet frï¿½n huvudarduino 0 = max bakï¿½t 127 = stillastï¿½ende 255 = max frammï¿½t
=======
>>>>>>> parent of f241aa9... fixat?
>>>>>>> 860dd51e62593c5aaa6411c9529ac794e697dbb1
int actualSpeed;
float RPM;

<<<<<<< HEAD
int revsTotal = 0; //antal snurrade varv på kardanaxeln, används inte atm
int revs = 0; //antal varv sedan senast beräknat RPM-värde.
int timeStamp = 0; //tid vid senast beräknat RPM-värde.
<<<<<<< HEAD
=======
int revsTotal = 0; //antal snurrade varv pï¿½ kardanaxeln, anvï¿½nds inte atm
int revs = 0; //antal varv sedan senast berï¿½knat RPM-vï¿½rde.
int timeStamp= 0; //tid vid senast berï¿½knat RPM-vï¿½rde.
=======
>>>>>>> parent of f241aa9... fixat?
>>>>>>> 860dd51e62593c5aaa6411c9529ac794e697dbb1

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
<<<<<<< HEAD
<<<<<<< HEAD
=======
	//Compute(); Fï¿½r PID-regleringen
>>>>>>> 860dd51e62593c5aaa6411c9529ac794e697dbb1
=======
	//Compute(); Fï¿½r PID-regleringen
>>>>>>> parent of f241aa9... fixat?
	sendData();
}
void getSpeed()
{
<<<<<<< HEAD
	revsTotal = revsTotal + revs;
<<<<<<< HEAD
	long deltaT = (millis() - timeStamp);
	/* varv per millisekund på kardanaxeln, omräknat till hastighet*/
 	RPM = ((revs*60000)/deltaT);
=======
	int deltaT = millis() - timeStamp;
	/* varv per millisekund pï¿½ kardanaxeln, omrï¿½knat till hastighet*/
 	actualSpeed = 60000*(revs/deltaT);
=======
<<<<<<< HEAD

	//revsTotal = revsTotal + revs;
	long deltaT = (millis() - timeStamp);
	/* varv per millisekund på kardanaxeln, omräknat till hastighet*/
 	RPM = ((revs*60000)/deltaT);
	//map(value, fromLow, fromHigh, toLow, toHigh)
	actualSpeed = (RPM/6.3);

>>>>>>> parent of f241aa9... fixat?
>>>>>>> 860dd51e62593c5aaa6411c9529ac794e697dbb1

	revs = 0;
	timeStamp = millis();
	
}
void getDataCompass()
{
<<<<<<< HEAD
<<<<<<< HEAD
	int i = 0;
=======
	/* Hï¿½mta kompassdata, smï¿½tt modifierad frï¿½n sensorplattformen */
	Wire.requestFrom(0x1E, 7);    // request 7 bytes
	unsigned int i = 0;
>>>>>>> 860dd51e62593c5aaa6411c9529ac794e697dbb1
	byte data[7]; //array to temporarily store parameters from compass
=======
	/* Hï¿½mta kompassdata, smï¿½tt modifierad frï¿½n sensorplattformen */
>>>>>>> parent of f241aa9... fixat?
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
	/*  Vï¿½lj hastighet utifrï¿½n nuvarande hastighet, rï¿½kna om till grader, PID-reglering */
<<<<<<< HEAD
<<<<<<< HEAD
	int newSpeed = desiredSpeed+speedP*(desiredSpeed - actualSpeed);
=======
	//int newSpeed = desiredSpeed+speedP*(desiredSpeed - actualSpeed);
	int newSpeed = desiredSpeed; //OBS endast test!!!
	if(newSpeed < maximumForward)
		newSpeed = maximumForward;
	if(newSpeed > maximumBackwards)
		newSpeed = maximumBackwards;

>>>>>>> 860dd51e62593c5aaa6411c9529ac794e697dbb1
=======
	//int newSpeed = desiredSpeed+speedP*(desiredSpeed - actualSpeed);
	int newSpeed = desiredSpeed; //OBS endast test!!!
>>>>>>> parent of f241aa9... fixat?
	Speed.write(newSpeed);
}
void setDirection()
{
<<<<<<< HEAD
<<<<<<< HEAD
	int newAngle = 90+angleP*(direction-compassData); /*Kan hï¿½nda att det ska vara 90-compassP*... */
=======

	int newAngle = direction+angleP*(direction-compassData); /*Kan hï¿½nda att det ska vara 90-compassP*... */
>>>>>>> 860dd51e62593c5aaa6411c9529ac794e697dbb1
	
>>>>>>> parent of f241aa9... fixat?
	//Så vi inte svänger utanför max/min för servot
=======
	int newAngle = direction+angleP*(direction-compassData); /*Kan hï¿½nda att det ska vara 90-compassP*... */
	
>>>>>>> 860dd51e62593c5aaa6411c9529ac794e697dbb1
	if(newAngle < servoMin)
		newAngle = servoMin;
	if(newAngle > servoMax)
		newAngle = servoMax;

	Angle.write(newAngle);
	Serial.print("Styrvinkel: "); Serial.println(newAngle);
}
void requestEvent()
{
<<<<<<< HEAD
<<<<<<< HEAD
	Wire.send(actualSpeed/* multiplicerat med konstant för att få i önskvärd storhet */);
	Wire.send(revsTotal/* multiplicerat med konstant för att få i önskvärd storhet */);
=======
	Wire.send(actualSpeed);
	Wire.send(revsTotal/* multiplicerat med konstant fï¿½r att fï¿½ i ï¿½nskvï¿½rd storhet */);
=======

	Wire.send(actualSpeed/* multiplicerat med konstant för att få i önskvärd storhet */);
	Wire.send(revsTotal/* multiplicerat med konstant för att få i önskvärd storhet */);
	
>>>>>>> parent of f241aa9... fixat?
>>>>>>> 860dd51e62593c5aaa6411c9529ac794e697dbb1
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
<<<<<<< HEAD
	direction = data[0];
<<<<<<< HEAD
	desiredSpeed = data[1]; 
	//omräkning till procent
	if(data[1] >= 0) //Frammåt!
	desiredSpeed = map(data[1], 0, 100, noSpeed, maximumForward);
	if(data[1] < 0)
	desiredSpeed = map(data[1], 0, -100, noSpeed, maximumBackwards);
=======
	desiredSpeed = data[1]; /*OBS! mï¿½ste rï¿½knas om till RPM, eller vad vi nu ska anvï¿½nda!*/ 
	/* -100 till 100, 0 ï¿½r stillastï¿½ende, anvï¿½nd map-kommandot*/
=======
<<<<<<< HEAD

	//direction = data[0];
	//desiredSpeed = data[1]; 
	/* omräkning till procent */
	//if(data[1] >= 0) //Frammåt!
	//desiredSpeed = map(data[1], 0, 100, noSpeed, maximumForward);
	//if(data[1] < 0)
	//desiredSpeed = map(data[1], 0, -100, noSpeed, maximumBackwards);

>>>>>>> parent of f241aa9... fixat?
>>>>>>> 860dd51e62593c5aaa6411c9529ac794e697dbb1
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
