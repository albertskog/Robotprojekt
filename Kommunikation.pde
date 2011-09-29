/* Program för att visa kommunikationen */

#include <Wire.h>
#include <Servo.h>

unsigned int lastReceived = 0;
unsigned int lastSent = 0;

char inByte[17] = {"N0#D0;0#E0;0#S0#"}; 
char utByte[36] = {"N0#Pa;b;c#Cd#Ue;f;g;h;i;j#Ak#Dl#L0#"};
char fel[9] = {"E0#T0;0#"};

void setup()
{
	Serial.begin(9600);	
}
void loop()
{
	unsigned int i=0;
	while(1 <= Serial.available()) // loopar igenom hela input, även enterslaget	
		{
			if(i==0);
			{
				inByte[1]=lastRecieved;
			}
		    inByte[i] = Serial.read(); // receive byte as a character
		    Serial.println(inByte);    // print the character
			i++;
			if(inByte[0]!='N' && inByte[3]!='D' && inByte[8]!='E' && inByte[13]!='S')
				error('inByte');
		}
		demoFunktion();           
}
void error(char message)
{
	Serial.println("Felkod: ");
	Serial.print(message);
}
void demoFunktion()
{
	//Skicka tillbaka erhållen data samt ett dummy-paket för att illustrera att det funkar?
	utByte[2] = lastSent;
	//Upptadera med sensordata
	Serial.println(utByte);
	lastSent++;
}