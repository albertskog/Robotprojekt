#include <NewSoftSerial.h>
#include <TinyGPS.h>

/* Testprogram för GPS-modulen! Skickar latitud, longitud och ålder seriellt
 Longitud är längs ekvatorn
 Latitud är tvärs ekvatorn
 */

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


TinyGPS gps;
NewSoftSerial nss(2, 3);

long lat, lon, lat_0, lon_0, c_x, c_y;
unsigned long age;
int i = 0;

long xByte, yByte, ageByte;

void setup()
{
  Serial.begin(57600);
  nss.begin(57600);

  feedgps();
  getGpsFix();
  makeConstants();
  Serial.println("Setup complete");
}

void loop()
{
  if (feedgps())
  {
    gps.get_position(&lat, &lon, &age);
    //printGpsData();
    convertPosition();
    printPos();
  }

}

//Get x coordinates and calculate average to establish starting position
void getGpsFix()
{
  int x = 3
  while(i < x)
  {
    if (feedgps())
    {
      gps.get_position(&lat, &lon, &age);
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

//Calculate how many "longitudes are in one x"
//and how many "latitudes are in one y"
void makeConstants()
{
  c_x = (LON_2 - LON_1) / 250;
  c_y = (LAT_3 - LAT_4) / 250;
  Serial.println("Constants are:");
  Serial.println(c_x);
  Serial.println(c_y);
}

void convertPosition()
{
  noInterrupts();
  xByte = (lon - lon_0) / c_x;
  yByte = (lat - lat_0) / c_y;
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

bool feedgps()
{
  while (nss.available())
  {
    if (gps.encode(nss.read()))
      return true;
  }
  return false;
}


