/*Styrningsarduino*/

#include <Servo.h>
#include <Wire.h>

byte data[2] = {90,88}; /* data[0]=vinkel, data[1]=hastighet */
Servo Speed;
Servo Angle;
int servoPin = 2;
int motorPin = 3;

void setup()
{
  
	Wire.begin(4);                // join i2c bus with address #4
	Wire.onReceive(receiveEvent); // register event
	
	Speed.attach(motorPin);
	Angle.attach(servoPin);

	run();						// Write initial values 
}

void loop()
{
	delay(1);
	run();
}

void receiveEvent(int howMany)
{
	unsigned int i = 0;
	while(Wire.available()) // loop through all but the last
	{
		data[i] = Wire.receive(); // receive byte as a character
		i++;
	}
}

void run()
{
	if (data[0] > 120)
		data[0] = 120;
	if (data[0] < 40)
		data[0] = 40;
	
	Speed.write(data[1]);
	if (data[0] > 110)
		data[0] = 110;
	if (data[0] < 60)
		data[0] = 60;
	Angle.write(data[0]);
}
void getRPM()
{
	/* Räknar ut aktuell hastighet utifrån hall-sensordata */
}
void getDataCompass()
{
	/* Hämta kompassdata */
}
void setSpeed()
{
	/*  Välj hastighet utifrån rpm*/
}
void setDirection()
{
	/* Sätt servovinkel efter önskad riktning */
}
void receiveEvent()
{
	/* Ta emot hastighet och kompass-vinkel */
}
void requestEvent()
{
	/* Skicka faktiskt hastighet */
}