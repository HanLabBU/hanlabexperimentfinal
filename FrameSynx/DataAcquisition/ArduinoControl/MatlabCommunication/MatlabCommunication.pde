char *id;

void setup(){
  Serial.begin(9600);
  id = matlabHandShake(); // print "A" until assigned an id
  Serial.println(id); // confirm ID by printing back
};

void loop(){
  
};

char* matlabHandShake(){
  char matlabMsg[33];
  int n = 0;
  while (Serial.available() <= 0){
    Serial.println('A');   // send a capital A
    delay(100);
  };
  while (n < 15){
    if (Serial.available() > 0){
      matlabMsg[n] = Serial.read();
      delay(1);
    }
    else{
      matlabMsg[n] = '\0';
    }
    n++;
  };
  return matlabMsg;
};
