

byte hallPin = 5;
boolean hall = 1; //It's inverted.

void timer1_setup (byte mode, int prescale, byte outmode_A, byte outmode_B, byte capture_mode)
{
  // enforce field widths for sanity
  mode &= 15 ;
  outmode_A &= 3 ;
  outmode_B &= 3 ;
  capture_mode &= 3 ;

  byte clock_mode = 0 ; // 0 means no clocking - the counter is frozen.
  switch (prescale)
  {
    case 1: clock_mode = 1 ; break ;
    case 8: clock_mode = 2 ; break ;
    case 64: clock_mode = 3 ; break ;
    case 256: clock_mode = 4 ; break ;
    case 1024: clock_mode = 5 ; break ;
    default:
      if (prescale < 0)
        clock_mode = 7 ; // external clock
  }
  TCCR1A = (outmode_A << 6) | (outmode_B << 4) | (mode & 3) ;
  TCCR1B = (capture_mode << 6) | ((mode & 0xC) << 1) | clock_mode ;
}

void setup()
{
  pinMode(13, OUTPUT);
  
  //Enable hall pullup
  pinMode(hallPin, OUTPUT);
  digitalWrite(hallPin, HIGH);
  
  //Normal mode, but with external clk!
  byte mode         = 0;  
  int prescale      = -1;
  byte outmode_A    = 0;
  byte outmode_B    = 0;
  byte capture_mode = 0;
  timer1_setup(mode, prescale, outmode_A, outmode_B, capture_mode);

  Serial.begin(9600);
}

void loop()
{
  Serial.println(TCNT1);
  delay(500);
}



