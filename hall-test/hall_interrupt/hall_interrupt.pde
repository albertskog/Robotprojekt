//Troligen bästa sättet att göra på, använder bara
//arduinokommandon och slipper gå ner i timers och register..

byte hallPin = 3;
boolean hall = 1; //It's inverted.
int revs = 0;

void hallInterrupt()
{
  revs++;
}

void setup()
{
  //Enable hall pullup
  pinMode(hallPin, OUTPUT);
  digitalWrite(hallPin, HIGH);
  
  attachInterrupt(1, hallInterrupt, RISING);
  
  Serial.begin(9600);
}


void loop()
{
  Serial.println(revs);
  delay(500);
}



