
unsigned long PreviousTime = 0;
int count = 0;

//analogue signals.
int batt = 0;
int val = 0;

//digital signals.
int btest = 12;
int chging = 11;
int yellow = 10;
int green = 9;
int red = 8;
int no_batt = 511;     // 0.5 * 1023
int low_voltage = 174; // 0.85/5 * 1023

//initalize basic variables
int x = 0;
int chg = 0;
int btest_flag = 0;
int tmset = 0;
int endg = 0;
int endr = 0;
int idelay = 0;   //for debouncing...
int timing_register = 0;
int timing_counter = 0;
int ADC0 = 0;
int VINIT = 0;

void setup()
{
  Serial.begin(9600);           // set up Serial library at 9600 bps
  pinMode(btest, OUTPUT);        // sets the digital pin as output
  pinMode(chging, OUTPUT);
  pinMode(yellow, OUTPUT);
  pinMode(green, OUTPUT);
  pinMode(red, OUTPUT);
  
  digitalWrite(btest, HIGH);
  digitalWrite(chging, HIGH);  
  digitalWrite(yellow, LOW);  
  digitalWrite(green, LOW);  
  digitalWrite(red, LOW);  
  
}

void reset_registers() {
  chg = 0;
  btest_flag = 0;
  tmset = 0;
  endg = 0;
  endr = 0;
  idelay = 0;
  timing_register = 0;
  timing_counter = 0;
  ADC0 = 0;
  VINIT = 0;
}  

void loop()
{
  
  while(timing_register < 500) {
    //x++;
    //if(x>3) { x = 0; }
  
    val = analogRead(batt);    // read the battery voltage
    if(val > no_batt) {  reset_registers();  }
    else {
      if(val <  low_voltage) {
        reset_registers();
        endr = 1;
      }
      if(!chg && !endg && !endr) {
        chg = 1;
        idelay = 1; 
      }
    }
  
    if(chg) { digitalWrite(yellow, HIGH);  }
    if(endg) { digitalWrite(green, HIGH);  }
    if(endr) { digitalWrite(red, HIGH);  }

    delay(3);
    
    digitalWrite(yellow, LOW);
    digitalWrite(green, LOW);
    digitalWrite(red, LOW);
  
    if(btest_flag) { 
      digitalWrite(chging, HIGH);
      digitalWrite(btest, LOW);
    } else if(chg) { 
      digitalWrite(chging, LOW); 
      digitalWrite(btest, HIGH);
    } else {
      digitalWrite(chging, HIGH); 
      digitalWrite(btest, HIGH);
    }
  
    timing_register++;  
  }
  if(timing_register == 500) {
    //Serial.print("Got here with: ");
    //Serial.println(millis());
    timing_register = 0;
  
    //start of X2 loop
    val = analogRead(batt);    // read the battery voltage
        
    if(chg) { digitalWrite(yellow, HIGH);  }
    if(endg) { digitalWrite(green, HIGH);  }
    if(endr) { digitalWrite(red, HIGH);  }
    Serial.print("Battery: ");
    Serial.print(val);
    Serial.print(" btest_flag: ");
    Serial.print(btest_flag);
    Serial.print(" tmset: ");
    Serial.print(tmset);
    Serial.print(" tc: ");
    Serial.print(timing_counter);
    Serial.print(" ADC0: ");
    Serial.print(ADC0);
    Serial.print(" VINIT: ");
    Serial.print(VINIT);
    Serial.print(" chg: ");
    Serial.println(chg);    
    digitalWrite(yellow, LOW);
    digitalWrite(green, LOW);
    digitalWrite(red, LOW);    
    
    if(val > no_batt) {  reset_registers();  }
    else if(!endr && !endg) {
      timing_counter++;
      if(idelay) {
        if(timing_counter > 8) { // greater than 16 seconds
          Serial.println("DONE debounce"); 
          idelay = 0;
          timing_counter = 0;
          ADC0 = val;
          VINIT = val;
        } else {
          Serial.println("doing initial debounce"); 
        }
      } else {
        if(timing_counter > 2700) { // 1h10min = 70*30 2 second intervals 2100 ---> changed
          reset_registers();
          endg = 1;
        } else {
          if(btest_flag) { 
            if(val > ADC0 + 1) {
              if(timing_counter > 17) { // 33 seconds
                btest_flag = 0;
                timing_counter = 0;
              } else {
                //reset_registers();
                //endr = 1;
              } 
            } else {
              if(timing_counter > 17) {
                btest_flag = 0;  
                timing_counter = 0; 
              }
            }
          } else {
            if(val > ADC0 + 1) {
              ADC0 = val;
              if(val > 360) { // 1.63V/5 * 1023
                if(tmset) {
                  reset_registers();
                  endg = 1; 
                } else {
                  if(VINIT > 276) { // 1.35/5 * 1023
                    reset_registers();
                    endg = 1;
                  } else {
                    reset_registers();
                    endr = 1;
                  }
                }
              } else {
                if(tmset) {
                  btest_flag = 1;
                  timing_counter = 0;                  
                } else {
                  timing_counter = 0;
                }  
              }
            } else {
              if(timing_counter > 255) { //8.5minutes 
                tmset = 1;
              }            
            }
          }
        }
      }
    }    
  }
}
 
