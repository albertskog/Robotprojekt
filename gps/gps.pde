/*
Sensor program
 This program gathers proximity data from six ultrasonic range finders
 and one UART GPS module and makes them available over I2C.
 */
#include <TinyGPS.h>
#include <NewSoftSerial.h>

#define GPS_BAUDRATE 57600


NewSoftSerial nss(2, 3);
TinyGPS Gps;
long gpsData[3];


long latitude, longitude;
unsigned long age;
unsigned long chars;
unsigned short sentences, failed_checksum;

void setup()
{
  //Setup UART for GPS communication
  Serial.begin(GPS_BAUDRATE);

  Serial.println("Setup complete");
}


void updateGpsData()
{
  while(nss.available())
  {
    Serial.println("available!");
    int c = nss.read();
    if (Gps.encode(c))
    {
      Serial.println("ja!");
      Gps.get_position(&latitude, &longitude, &age);
      gpsData[0] = latitude;
      gpsData[1] = longitude;
      gpsData[2] = age;
      Serial.println(latitude);
    }
    Gps.stats(&chars, &sentences, &failed_checksum);
    Serial.println(failed_checksum);
  }
}


void printGpsData()
{
  for(int i = 0; i<2; i++)
  {
    Serial.println(gpsData[i]);
  }
}

void loop()
{

  updateGpsData();

  //printGpsData();
}

