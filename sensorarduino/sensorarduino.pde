/*
Sensor program
 This program gathers proximity data from six ultrasonic range finders
 and one UART GPS module and makes them available over I2C.
 */
#include <TinyGPS.h>
#include <NewSoftSerial.h>
#include <Wire.h>
#include <RunningMedian.h>

#define I2C_ADDRESS 1
#define GPS_BAUDRATE 57600
#define NUMBER_OF_PROXIMITY_SENSORS 3
#define PROXIMITY_CONSTANT 58    //Used to convert time into cm..

//Pins
byte proximitySensorTrigPin[NUMBER_OF_PROXIMITY_SENSORS] = {
  7, 9, 11};
byte proximitySensorEchoPin[NUMBER_OF_PROXIMITY_SENSORS] = {
  6, 8, 10};

NewSoftSerial nss(2, 3);
TinyGPS Gps;
RunningMedian ProximityData[NUMBER_OF_PROXIMITY_SENSORS];
long gpsData[3];

void setup()
{
  //Setup I2C
  Wire.begin(I2C_ADDRESS);
  Wire.onRequest(i2cEventHandler);

  //Setup UART for GPS communication
  Serial.begin(GPS_BAUDRATE);

  //Define inputs/outouts
  for(byte i = 0; i < NUMBER_OF_PROXIMITY_SENSORS; i++)
  {
    pinMode(proximitySensorTrigPin[i], OUTPUT);
    pinMode(proximitySensorEchoPin[i], INPUT);
  }

}

//send back the proximity and gps data upon request
//we always send a total of NUMBER_OF_PROXIMITY_SENSORS + 3 bytes (=6+3=9)
void i2cEventHandler()
{ 
  for(byte i = 0; i < NUMBER_OF_PROXIMITY_SENSORS; i++)
  {
    Wire.send(byte(ProximityData[i].getMedian()));
  }
  for(byte i = 0; i < 3; i++)
  {
    //Wire.send(gpsData[i]);
  }
}

//Send a LOW-HIGH-LOW pulse to selected pin
void pulse(byte pin)
{
  digitalWrite(pin, LOW);
  digitalWrite(pin, HIGH);
  delayMicroseconds(10);  //Recomended minimum pulse width from datasheet
  digitalWrite(pin, LOW);   
}

//Get rolling median proximity from a chosen sensor
byte getProximity(byte sensor)
{
  int proximity;

  //Waiting for the pulse from the sensor is time critical, disable interrupts!
  noInterrupts();
  pulse(proximitySensorTrigPin[sensor]);

  proximity = pulseIn(proximitySensorEchoPin[sensor], HIGH)/PROXIMITY_CONSTANT;
  interrupts();

  //We need to fit this into a byte..
  if((proximity < 255) & (proximity > 0))
  {
    return byte(proximity);
  }
  else if(proximity >= 255)
  {
    return byte(255);
  }
  else
  {
    return byte(255);
  }
}

//Update the proximityData array with new values.
//First loop new values into a temporary array, then
//add the values to the proximityData objects
void updateProximityData()
{
  byte newProximityData[NUMBER_OF_PROXIMITY_SENSORS];

  for(byte i = 0; i < NUMBER_OF_PROXIMITY_SENSORS; i++)
  {
    newProximityData[i]= getProximity(i);
  }

  //We dont want to mix new and old values, disable I2C interrupts for this
  noInterrupts();
  for(byte i = 0; i < NUMBER_OF_PROXIMITY_SENSORS; i++)
  {
    ProximityData[i].add(newProximityData[i]);
  }
  interrupts();

}

void updateGpsData()
{
  long latitude, longitude;
  unsigned long age;
  unsigned long chars;
  unsigned short sentences, failed_checksum;

  while(nss.available())
  {
    //Serial.println("available!");
    if (Gps.encode(nss.read()))
    {
      //Serial.println("ja!");
      Gps.get_position(&latitude, &longitude, &age);
      gpsData[0] = latitude;
      gpsData[1] = longitude;
      gpsData[2] = age;
      Serial.println(latitude);
    }
  }
}

void printProximityData()
{
  for(int i = 0; i<NUMBER_OF_PROXIMITY_SENSORS; i++)
  {
    Serial.print(i);
    Serial.print(':');
    Serial.println(ProximityData[i].getMedian());
  }
  Serial.println();
  delay(500);
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
  updateProximityData();
  updateGpsData();

  //printProximityData();
  //printGpsData();
}

