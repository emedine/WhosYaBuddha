   int led = 13;
   byte data_1 = 0x00;
   byte data_2 = 0x00;
   byte data_3 = 0x00;
   byte data_4 = 0x00;
   byte data_5 = 0x00;
   int val = 0;

   void setup(){

   Serial.begin(19200);
   
   pinMode(led, OUTPUT);
   delay(500);
      
   // Setting Auto Read Mode - EM4102 Decoded Mode - No password
   // command: FF 01 09 87 01 03 02 00 10 20 30 40 37
   Serial.write(0xFF);
   Serial.write(0x01);
   Serial.write(0x09);
   Serial.write(0x87);
   Serial.write(0x01);
   Serial.write(0x03);
   Serial.write(0x02);
   Serial.write(0x00);
   Serial.write(0x10);
   Serial.write(0x20);
   Serial.write(0x30);
   Serial.write(0x40);
   Serial.write(0x37);
   
   delay(500);
   Serial.flush();
   Serial.println();
   Serial.println("RFID module started in Auto Read Mode");
   }

   void loop(){
   
   val = Serial.read();
   while (val != 0xff){
      Serial.println("Waiting card");
      val = Serial.read();
      delay(1000);
   }
   
   // Serial.read();    // we read ff
   Serial.read();    // we read 01
   Serial.read();    // we read 06
   Serial.read();    // we read 10
   data_1 = Serial.read();    // we read data 1
   data_2 = Serial.read();    // we read data 2
   data_3 = Serial.read();    // we read data 3
   data_4 = Serial.read();    // we read data 4
   data_5 = Serial.read();    // we read data 5
   Serial.read();    // we read checksum
   
   // Led blink
   for(int i = 0;i<4;i++){
      digitalWrite(led,HIGH);
      delay(500);
      digitalWrite(led,LOW);
      delay(500);
   }
   
   // Printing the code of the card
   Serial.println();
   Serial.print("Code:");
   writeByte(data_1);
   writeByte(data_2);
   writeByte(data_3);
   writeByte(data_4);
   writeByte(data_5);
   Serial.println();
   Serial.println();

   }

   //Write a byte (hex) in ASCII
   void writeByte(byte data){
   int aux_1 = 0;
   int aux_2 = 0;

      aux_1=data/16;
      aux_2=data%16;
      if (aux_1<10){
      Serial.print(aux_1 + 48);
      }
      else{
      Serial.print(aux_1+55);
      }
      if (aux_2<10){
      Serial.print(aux_2 + 48);
      }
      else{
      Serial.print(aux_2 + 55);
      }
   Serial.print(" ");
   }
