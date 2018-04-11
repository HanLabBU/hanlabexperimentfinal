// ---------------------------------------------------------------
/* 
LedIlluminationSensor

Mark Bucklin - 4/26/2010
 
 Usage:
 1. Follow general handshake protocol with matlab
 2. Assign ledPins and ledLabels
 3. Activate by sending an 'a', deactivate by writing 'd'
 4. Read serial output:
 Each frame separated by comma, wavelength labels between commas
 (e.g. 'r,r,g,g,r,r,g,g,r,r,g,g,...)
 */
// ---------------------------------------------------------------



// ---------------------------------------------------------------
// PROPERTIES
// ---------------------------------------------------------------
// General Properties
const int strsize = 32;
char arduinoID[strsize];
char clientID[strsize];
char matlabMsg[strsize];
int controlMsg;
int n = 0;

// Illumination Specific Properties
int nLeds = 0;
int ledPins[10];
char ledLabels[10];
boolean ledStates[10];
char sensorOutput[10];
int frameCount = 0;



// ---------------------------------------------------------------
// DEVICE SETUP FUNCTIONS
// ---------------------------------------------------------------
// Setup (first function called)
void setup(){
  Serial.begin(9600);
  matlabHandShake(); // print "A" until assigned an ID
  setProperties(); //assign LEDs
};

// Retrieve ID and clientID from Matlab
void matlabHandShake(){
  // Scream out to all other devices by sending repeated A
  while (Serial.available() <= 0){
    Serial.print('@');   // send a @
    delay(100);
  };
  Serial.println('\0'); // end screaming
  Serial.flush(); // clear whatever was sent to initiate contact
  assignIDs();
};

//  Retrieve ID and clientID from Matlab
void assignIDs(){
  Serial.println("clientID");
  readMatlabString(clientID,strsize);
  Serial.println("arduinoID");
  readMatlabString(arduinoID,strsize);
};

// Retrieve Illumination-Specific Properties from Matlab
void setProperties(){
  Serial.println("nLeds");
  nLeds = readMatlabNumber();
  Serial.println("ledPins");
  readMatlabVector(ledPins, nLeds);
  Serial.println("ledLabels");
  readMatlabString(ledLabels, nLeds);
  setPins();
};

// Set Led Pins and Test the Colors?
void setPins(){
  int pin;
  char label;
  for (n=0; n<=nLeds; n++){
    pin = ledPins[n];
    label = ledLabels[n];
    if (pin > 2){ // interrupt is on pin 2, serial on 0,1
    pinMode(pin,INPUT);
    digitalWrite(pin,LOW);
    ledStates[n] = digitalRead(pin); // set to low
    };
  };
};




// ---------------------------------------------------------------
// DEVICE RUNNING FUNCTIONS
// ---------------------------------------------------------------
// Loop Monitors For Activation Signal
void loop(){
  // Check for Serial Message -> Read
  if (Serial.available() > 0){
    readMatlabString(matlabMsg,strsize);
    controlMsg = int(matlabMsg[0]);// a (97) or d (100)
    switch (controlMsg) {
    case 'a': // a for activate
      attachInterrupt(0, frameStartFcn, RISING);//camera input to digital pin 3
      break;
    case 'd': // d for deactivate
      detachInterrupt(0);
      frameCount = 0;
      break;
    case 's': // s for set properties
      assignIDs();
      setProperties();
      break;
    };
  };
};

// Interrupt-Service-Routine (tripped at start of every frame)
void frameStartFcn()
{
  frameCount++;
  for (n=0; n<nLeds; n++){
    ledStates[n] = digitalRead(ledPins[n]);
    if (ledStates[n] == HIGH){
      //Serial.print(ledLabels[n]);
      sensorOutput[n] = ledLabels[n];
    }
    else{
      sensorOutput[n] = '*';
    };
  };
  //sensorOutput[nLeds] = ',';
  Serial.println(sensorOutput);
  //Serial.println(",");
  //Serial.println(frameCount,DEC);
};





// ---------------------------------------------------------------
// SUBROUTINES FOR READING FROM SERIAL PORT
// ---------------------------------------------------------------
// Function for reading a string from matlab
void readMatlabString(char str[], int nchars){
  n = 0;
  while (Serial.available() < 1){
    delay(1);
  };
  while (n < nchars){
    if (Serial.available() > 0){
      str[n] = Serial.read();
      delay(1);
    }
    else{
      str[n] = '\0';
      break;
    }
    n++;
  };
}

// Function for reading a number array from matlab
void readMatlabVector(int vec[], int vecsize){
  n = 0;
  char msg[vecsize];
  while (Serial.available() < 1){
    delay(1);
  };
  while (n <= vecsize){
    if (Serial.available() > 0){
      msg[n] = Serial.read();
      if ('msg[n]' != 13 && 'msg[n]' != 10){//not CR or LF
        vec[n] = int(msg[n]);
      }
      else{
        vec[n] = -1;
      };
      delay(1);
      n++;      
    }
    else{
      vec[n] = -1;
      break;
    }
  };
};

// Function for reading a number 
int readMatlabNumber(){
  while (Serial.available() < 1){
    delay(1);
  };
  int num = int(Serial.read());
  return num;
}









