/*  The program revieves speed and direction from the main program 
	and drives towards given direction at given speed. 
	Returns speed and distance to main program 	*/
#include <Servo.h>
#include <Wire.h>

#define servoPin 4
#define motorPin 5
#define hallPin 3
#define wireAdress 1
#define servoMax 125
#define servoMin 60
#define maximumForward 40
#define maximumBackwards 137
#define servoCenter 90 // Forward for servo
#define noSpeed 88 // Neutral for ESC

Servo Angle;
Servo Speed;

int HMC6352Address = 0x42;
int slaveAddress;
int state = 0;
int compassData;
int direction; // Sent value from main program
int desiredSpeed; // Sent value (%) from main program

void setup()
{
	// Setup: TWI
	Wire.begin(wireAdress);
	Wire.onReceive(receiveEvent); 
	slaveAddress = HMC6352Address >> 1; // This results in 0x21
	// Setup: Servo and ESC
	Angle.attach(servoPin);
	Angle.write(servoCenter);
	Speed.attach(motorPin);
	Speed.write(noSpeed);
	
	startUp();
}
void loop()
{
	getDataCompass();
	if(state==0)
	{
		Angle.write(90);
	}
          if(state==1)
   	{
    	setDirection();
	}
}
/*	Set initial speed and direction	*/
void startUp()
{
	getDataCompass();
	direction = compassData;
	desiredSpeed = 88;
	setSpeed();
}
/*	Requests data from the compass over TWI	*/
void getDataCompass()
{
	byte headingData[2];
	Wire.beginTransmission(slaveAddress);
	Wire.send("A"); // The "Get Data" command
	Wire.endTransmission();
	delay(10); // The HMC6352 needs at least a 70us delay
	Wire.requestFrom(slaveAddress, 2);
	int i = 0;
	while(Wire.available() && i < 2)
	{ 
		headingData[i] = Wire.receive();
	        i++;
	}
	compassData = (headingData[0]*256 + headingData[1])/10; 
}
/*	Updates the direction using the compassdata	*/
void setDirection()
{
	if (direction < 7 || direction > 353)
	{
        if(compassData <=7 || compassData >= 353)
		{
			Angle.write(90); // Forward
        }
		if(compassData > 7 && compassData < 180)
		{
			Angle.write(110); // Right
		}
		if(compassData < 353 && compassData >= 180)
		{
			Angle.write(73); // Left
		}		
	}
	else
	{
		if(compassData > direction + 7 && compassData < direction + 180)
		{
			Angle.write(110); // Left
		}
		else if(compassData > direction + 7 && compassData > direction + 180)
		{
			Angle.write(73); // Right
		}
		else if(compassData < direction - 7 && compassData > direction - 180)
		{
			Angle.write(73); // Left
        }
		else if(compassData < direction - 7 && compassData < direction - 180)
		{
			Angle.write(110); // Right
		}
		else if(compassData <= (direction+7) || compassData >= direction-7)
		{
			Angle.write(90); // Forward
		}
	}
}
/*	Updates the speed using the value from the main program	*/
void setSpeed()
{
	int newSpeed = desiredSpeed;

	if(newSpeed < maximumForward)
		newSpeed = maximumForward;
	if(newSpeed > maximumBackwards)
		newSpeed = maximumBackwards; 
	Speed.write(newSpeed);
}
/*	Recieves data from the main program	*/
void receiveEvent(int HowMany)
{
	byte data[3];
	unsigned int i = 0;
	while(Wire.available())
	{
		data[i++] = Wire.receive();
	}
	direction = ((((int)data[0]) << 8) | data[1]);
	/* Map desired speed to corresponding ESC value */
	if(data[2] < 100) // Forward
	{
		desiredSpeed = map(data[2], 0, 100, noSpeed, maximumForward);
		state = 1;
	}
	if(data[2] > 100)
	{
    	// Backward and brake
		int absData = abs(data[2]);
        desiredSpeed = map(absData-100, 0, 100, noSpeed, maximumBackwards);
		state = 0;
    }
	setSpeed();
}