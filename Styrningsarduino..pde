/*Styrningsarduino*/

#include <Wire.h>
#include <Servo.h>

int I2CAdress = 4;
unsigned int data[2] = {0,0}; /* data[0]=hastighet, data[1]=vinkel */

Servo speed;
Servo angle;

void setup()
{
	Wire.begin(I2CAdress);				// join i2c bus with address #4
	Wire.onReceive(receiveEvent);		// register event
	
	speed.attach(3);
	angle.attach(4);
	
	Serial.begin(9600);					// start serial for output
}

void loop()
{
	
}

void receiveEvent()
{
	unsigned int i = 0;
	while(1 < Wire.available())			// loop through all but the last
	{
		data[i] = Wire.receive();		// receive byte as a character
		i++
	}
	run();
}

void run()
{
	speed.write(data[0]);
	angle.write(data[1]);
}