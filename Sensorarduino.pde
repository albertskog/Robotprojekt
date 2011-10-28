/*Första utkast till sensorarduino*/

#include <Wire.h>
#include <AverageList.h> //för beräkning av medelvärden

byte ultrasonicData[6]; //array innehållande avstånd avläst av respektive avståndssensor
byte gpsData[3]; //array innehållande de senast avläsa gps-värdena [0]=,[1]=,[2]=

void setup()
{	
	Wire.begin()
}

void loop()
{
	
}
void getDataUltrasonic()
{
	/* Beräkna medelvärde för ultraljudet & uppdatera variabeln med avståndssensordata */
}
void getDataGPS()
{
	/* Uppdaterar variabeln med gps-värden, räkna om koordinater till koordinatsystemet */
}
void requestEvent() /*det som händer då Arduinon anropas på I2C*/
{
	/* Kör getDataGPS och getDataUltrasonic, räkna om, sedan skicka tillbaka till huvudarduino. */
}