/*
Sensor program
 This program gathers proximity data from six ultrasonic range finders
 and one UART GPS module and makes them available over I2C.
 */
#include <TinyGPS.h>
#include <NewSoftSerial.h>
#include <Wire.h>
#include <RunningMedian.h>

//Variables
#define I2C_ADDRESS 2
#define GPS_BAUDRATE 57600

#define NUMBER_OF_PROXIMITY_SENSORS 5
#define PROXIMITY_TIMEOUT 15000
#define PROXIMITY_CONSTANT 58    //Used to convert time into cm..

#define BATTERY_PIN 0
#define BATTERY_OFFSET 27

//Pins
byte proximitySensorTrigPin[NUMBER_OF_PROXIMITY_SENSORS] = {
  3, 5, 7, 9, 11};
byte proximitySensorEchoPin[NUMBER_OF_PROXIMITY_SENSORS] = {
  2, 4, 6, 8, 10};

//GPS port object
NewSoftSerial GpsPort(0,1);

//GPS object
TinyGPS Gps;

//List of proximity data medians
RunningMedian ProximityData[NUMBER_OF_PROXIMITY_SENSORS];

//Array containing the latest sensor data
byte sensorData[NUMBER_OF_PROXIMITY_SENSORS+4+4+1+1];

//GPS varaibles
long lat, lon;
unsigned long age;
byte ageByte;


//long t=0;

void setup()
{
  //debug only
  //Serial.begin(115200);

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
//we always send a total of NUMBER_OF_PROXIMITY_SENSORS + 9 bytes (=1+4+4=9)
void i2cEventHandler()
{ 
  Wire.send(sensorData, NUMBER_OF_PROXIMITY_SENSORS+1+4+4);
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
  proximity = pulseIn(proximitySensorEchoPin[sensor], HIGH, PROXIMITY_TIMEOUT)/PROXIMITY_CONSTANT;
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
  for(byte i = 0; i < NUMBER_OF_PROXIMITY_SENSORS; i++)
  {
    ProximityData[i].add(getProximity(i));
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
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 1] = (byte) (lat >> 24);
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 2] = (byte) (lat >> 16);
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 3] = (byte) (lat >> 8);
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 4] = (byte) lat;
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 5] = (byte) (lon >> 24);
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 6] = (byte) (lon >> 16);
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 7] = (byte) (lon >> 8);
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 8] = (byte) lon;
  sensorData[NUMBER_OF_PROXIMITY_SENSORS + 9] = (byte) age;
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

void updateVoltage()
{
    sensorData[NUMBER_OF_PROXIMITY_SENSORS] = analogRead(BATTERY_PIN) - BATTERY_OFFSET;
}

void loop()
{
  if (feedGps())
  {
    Gps.get_position(&lat, &lon, &age);
    convertPosition();
  }
  updateProximityData();
  updateVoltage();

 /* if (millis() - t > 1000)
  {
    printProximityData();
    printGpsData();
    t=millis();
  }*/

}


