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
  3, 5, 6, 7, 8, 9};
byte proximitySensorEchoPin[NUMBER_OF_PROXIMITY_SENSORS] = {
  2, 10, 11, 12, 13, 9};

NewSoftSerial nss(2, 3);
TinyGPS Gps;
RunningMedian ProximityData[NUMBER_OF_PROXIMITY_SENSORS];
byte gpsData[3];

long lat, lon, lat_0, lon_0, c_x, c_y;
unsigned long age;
int i = 0;

long xByte, yByte, ageByte;

void setup()
{
  //fulhax strömförsörjning
  pinMode(4, OUTPUT);
  digitalWrite(4, HIGH);
  //debug only
  Serial.begin(9600);
  
  //Setup I2C
  Wire.begin(I2C_ADDRESS);
  Wire.onRequest(i2cEventHandler);

  //Setup UART for GPS communication
  nss.begin(GPS_BAUDRATE);

  //Define inputs/outouts
  for(byte i = 0; i < NUMBER_OF_PROXIMITY_SENSORS; i++)
  {
    pinMode(proximitySensorTrigPin[i], OUTPUT);
    pinMode(proximitySensorEchoPin[i], INPUT);
  }
  
  //Get a GPS starting position
  feedGps();
  //getGpsFix();
  Serial.println("Setup complete");
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
    Wire.send(gpsData[i]);
  }
  Serial.println("I2C!!");
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
  Serial.println("woopiedo");
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

//Get x coordinates and calculate average to establish starting position
void getGpsFix()
{
  int x = 10;
  while(i < x)
  {
    if (feedGps())
    {
      Gps.get_position(&lat, &lon, &age);
      printGpsData();
      //convertPosition();
      lat_0 += lat;
      lon_0 += lon;
      i++;
      delay(500);
    }
  }
  lat_0 /= x;
  lon_0 /= x;

  Serial.println("Fix established. Start position is:");
  Serial.println(lon_0);
  Serial.println(lat_0);
}


void convertPosition()
{
  noInterrupts();
  xByte = (lon - lon_0);
  yByte = (lat - lat_0);
  if(age << 255)
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

void printPos()
{
  Serial.print("X/Y: "); 
  Serial.print(xByte, DEC); 
  Serial.print(", "); 
  Serial.print(yByte, DEC); 
  Serial.print(" Fix age: "); 
  Serial.print(ageByte); 
  Serial.println("ms.");
}

bool feedGps()
{
  while (nss.available())
  {
    if (Gps.encode(nss.read()))
      return true;
  }
  return false;
}

void loop()
{
  updateProximityData();
  //printProximityData();
  if (feedGps())
  {
    Gps.get_position(&lat, &lon, &age);
    //printGpsData();
    convertPosition();
    //printPos();
  }
}

