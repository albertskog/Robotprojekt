// Sensor plattorm
// Written by: Albert Skog 11-10-06

//Variables
String inPackage;
String dataPackage;
byte packageNumber;
int i=0;

void setup()
{
  Serial.begin(115200); //Ändra till BT!!
}

void parseInPackage()
{
  //Did we get the beginning of a package?
  if(inPackage[0] == '$')
  {
    //Extract pkg nr
    if(inPackage[1] == 'N')
    {
      while(inPackage[i] != '#')
      {
        inNr = 
      }
    }
    
    
  }//inPackage[1] == "$"
}

void buildDataPackage()
{
  dataPackage = "";
  //Begin data package
  dataPackage += '$';
  //Put a number on it
  dataPackage += 'N';
  dataPackage += String(packageNumber++, DEC);
  dataPackage += '#';
  //Add GPS data
  dataPackage += 'G';
  dataPackage += "0.000;0.000;0.000";
  dataPackage += '#';
  dataPackage += inPackage;
  //End of package! Print a Newline!
  dataPackage += char(10);
}

void loop()
{
  //Check for new instructions
  inPackage = "";
  while(Serial.available())
  {
    inPackage += char(Serial.read());
  }
  parseInPackage();
  
  
  //Build sensor data package
  buildDataPackage();
  
  //Send the package
  Serial.print(dataPackage);
  
  delay(500);
}
