/*Styrningsarduino*/

#include <Servo.h>
#include <Wire.h>

byte data[2] = {'0','0'}; /* data[0]=vinkel, data[1]=hastighet */
Servo Speed;
Servo Angle;
int servoPin = 2;
int motorPin = 3;

void setup()
{
  Wire.begin(4);                // join i2c bus with address #4
  Wire.onReceive(receiveEvent); // register event
  //Serial.begin(9600);           // start serial for output
  
  Speed.attach(motorPin);
  Angle.attach(servoPin);
}

void loop()
{
	delay(1);
}

void receiveEvent(int howMany)
{
  unsigned int i = 0;
  while(Wire.available()) // loop through all but the last
  {
    data[i] = Wire.receive(); // receive byte as a character
    //Serial.print(data[i], DEC);         // print the character
    i++;
  }
  run();
}

void run()
{
	if (data[0] > 120)
		data[0] = 120;
	if (data[0] < 40)
		data[0] = 40;
	Speed.write(data[1]);
    
	if (data[0] > 100)
		data[0] = 100;
	if (data[0] < 80)
		data[0] = 80;
	Angle.write(data[0]);
}