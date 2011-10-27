byte hallPin = 4;
boolean hall;

void setup()
{
  //Enable hall pullup
  pinMode(hallPin, OUTPUT);
  digitalWrite(hallPin, HIGH);

  Serial.begin(9600);
}

void loop()
{
  hall = digitalRead(hallPin);
  if(!hall)
  {
    Serial.println('1');
    delay(500);
  }
}

