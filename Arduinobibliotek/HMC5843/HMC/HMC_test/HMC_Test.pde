/* New/modified HMC lib functions:
  |
  | init(bool setmode), initialize, set or don't set mode
  | getValues(int x,int y,int z), as (scaled) values
  | getValues(float fx,float fy,float fz), as (scaled) float values
  | calibrate(char gain), calculates the scales for output using gain setting
  | setMode(char mode), set mode
  | setDOR(char dor), set Data Output Rate
  | setGain(char gain), set gain
  |
  | for details on settings: http://www.sparkfun.com/datasheets/Sensors/Magneto/HMC5843.pdf
  |
  | Lib modified/extended by E.J.Muller (2010)
*/

#include <HMC.h>

void setup()
{ Serial.begin(115200);
  delay(5); // The HMC5843 needs 5ms before it will communicate
  HMC.init(false); // Dont set mode yet, we'll do that later on.
  // Calibrate HMC using self test, not recommended to change the gain after calibration.
  HMC.calibrate(1); // Use gain 1=default, valid 0-7, 7 not recommended.
  // Single mode conversion was used in calibration, now set continuous mode
  HMC.setMode(0);
}

void loop()
{ int ix,iy,iz;
  float fx,fy,fz;
  delay(500);
  // Get values, as ints and floats.
  HMC.getValues(&ix,&iy,&iz); // Returned values are scaled not calculated to rotation,
  HMC.getValues(&fx,&fy,&fz); // some trigonometry is needed for that (http://www.ssec.honeywell.com/magnetic/datasheets/lowcost.pdf)
  // as int
  Serial.print("- Ints x:");
  Serial.print(ix);
  Serial.print(" y:");
  Serial.print(iy);
  Serial.print(" z:");
  Serial.println(iz);
  // as float
  Serial.print("Floats x:");
  Serial.print(fx);
  Serial.print(" y:");
  Serial.print(fy);
  Serial.print(" z:");
  Serial.println(fz);
  // a simple heading, assuming it's close to horizontal
  Serial.print("Heading: ");
  Serial.println((atan2(fy,fx)+M_PI)*180/M_PI);
}

