/*F�rsta utkast till sensorarduino*/

#include <Wire.h>
#include <AverageList.h> //f�r ber�kning av medelv�rden

byte ultrasonicData[6]; //array inneh�llande avst�nd avl�st av respektive avst�ndssensor
byte gpsData[3]; //array inneh�llande de senast avl�sa gps-v�rdena [0]=,[1]=,[2]=

void setup()
{	
	Wire.begin()
}

void loop()
{
	
}
void getDataUltrasonic()
{
	/* Ber�kna medelv�rde f�r ultraljudet & uppdatera variabeln med avst�ndssensordata */
}
void getDataGPS()
{
	/* Uppdaterar variabeln med gps-v�rden, r�kna om koordinater till koordinatsystemet */
}
void requestEvent() /*det som h�nder d� Arduinon anropas p� I2C*/
{
	/* K�r getDataGPS och getDataUltrasonic, r�kna om, sedan skicka tillbaka till huvudarduino. */
}