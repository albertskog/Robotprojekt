/*
MILLIS IS BROKEN!!!!
*/


byte hallPin = 5;
boolean hall = 1; //It's inverted.

void setup()
{
  pinMode(13, OUTPUT);
  
  //Enable hall pullup
  pinMode(hallPin, OUTPUT);
  digitalWrite(hallPin, HIGH);

  TCCR0A = 0b00000000; //Normal mode
  TCCR0B = 0b00000111; //Clock on rising edge on digital pin 4
  TCNT0 = 0
  Serial.begin(9600);
}


void loop()
{
  if(TCNT0 && 1)
  {
    digitalWrite(13, HIGH);
  }
  else
  {
    digitalWrite(13, LOW);
  }
}



