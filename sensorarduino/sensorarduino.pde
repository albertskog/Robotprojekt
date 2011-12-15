/*
Sensor program
 This program gathers proximity data from six ultrasonic range finders
 and one UART GPS module and makes them available over I2C.
 */
#include <TinyGPS.h>
#include <NewSoftSerial.h>
#include <Wire.h>
#include <RunningMedian.h>

//define corners
#define LON_1 16.16270216
#define LAT_1 58.58865287

#define LON_2 16.16300559
#define LAT_2 58.58867050

#define LON_3 16.16296569
#define LAT_3 58.58907323

#define LON_4 16.16266411
#define LAT_4 58.58906116

#define LON_5 16.16267061
#define LAT_5 58.58892476

//define A & B
#define LON_A 16.16276325
#define LAT_A 58.58903116

#define LON_B 16.16294636
#define LAT_B 58.58869834

//Variables
#define I2C_ADDRESS 2
#define GPS_BAUDRATE 57600
#define NUMBER_OF_PROXIMITY_SENSORS 6
#define PROXIMITY_CONSTANT 58    //Used to convert time into cm..


//Pins
byte proximitySensorTrigPin[NUMBER_OF_PROXIMITY_SENSORS] = {
  13, 5, 13, 9, 11, 13};
byte proximitySensorEchoPin[NUMBER_OF_PROXIMITY_SENSORS] = {
  12, 4, 12, 8, 10, 12};

NewSoftSerial GpsPort(2,3);
TinyGPS Gps;
RunningMedian ProximityData[NUMBER_OF_PROXIMITY_SENSORS];
byte sensorData[NUMBER_OF_PROXIMITY_SENSORS+4+4+1];

long lat, lon, lat_0, lon_0;
unsigned long age;
int i = 0;

byte xByte, yByte, ageByte;

byte p[6] = {
  1, 2, 3, 4, 5, 6};

long t=0;

void setup()
{
  //debug only
  Serial.begin(115200);

  //Setup I2C
  Wire.begin(I2C_ADDRESS);
  Wire.onRequest(i2cEventHandler);

  //Setup UART for GPS communication
  GpsPort.begin(GPS_BAUDRATE);

  //Define inputs/outouts
  for(byte i = 0; i < NUMBER_OF_PROXIMITY_SENSORS; i++)
  {
    pinMode(proximitySensorTrigPin[i], OUTPUT);
    pinMode(proximitySensorEchoPin[i], INPUT);
  }

  //Serial.println("Setup complete");
}

//send back the proximity and gps data upon request
//we always send a total of NUMBER_OF_PROXIMITY_SENSORS + 3 bytes (=6+3=9)
void i2cEventHandler()
{ 
  Wire.send(sensorData, NUMBER_OF_PROXIMITY_SENSORS+4+4+1);
  //Serial.println("I2C request");
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
  //noInterrupts();
  pulse(proximitySensorTrigPin[sensor]);
  proximity = pulseIn(proximitySensorEchoPin[sensor], HIGH)/PROXIMITY_CONSTANT;
  //Serial.println(proximity);
  //interrupts();

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
    sensorData[i] = ProximityData[i].getMedian();
  }
  interrupts();

}

void printProximityData()
{
  for(int i = 0; i<NUMBER_OF_PROXIMITY_SENSORS; i++)
  {
    Serial.print(i);
    Serial.print(": ");
    Serial.println(ProximityData[i].getMedian(), DEC);
  }
  Serial.println();
  //delay(500);
}


void convertPosition()
{
  noInterrupts();
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 0] = (byte) (lat >> 24);
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 1] = (byte) (lat >> 16);
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 2] = (byte) (lat >> 8);
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 3] = (byte) lat;
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 4] = (byte) (lon >> 24);
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 5] = (byte) (lon >> 16);
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 6] = (byte) (lon >> 8);
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 7] = (byte) lon;
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 8] = (byte) age;
  if(age < 255)
  {
    ageByte = age;
  }
  else
  {
    ageByte = 255;
  }
  interrupts();
}

void printGpsData()
{
  Serial.print("Lat/Long(10^-5 deg): "); 
  Serial.print(lat); 
  Serial.print(", "); 
  Serial.print(lon); 
  Serial.print(" Fix age: "); 
  Serial.print(age); 
  Serial.println("ms.");
}

bool feedGps()
{
  while (GpsPort.available())
  {
    if (Gps.encode(GpsPort.read()))
      return true;
  }
  return false;
}

void loop()
{
  updateProximityData();
  if (feedGps())
  {
    Gps.get_position(&lat, &lon, &age);
    convertPosition();
  }

  if (millis() - t > 1000)
  {
    printProximityData();
    printGpsData();
    t=millis();
  }

}


