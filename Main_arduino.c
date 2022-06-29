#include <dht11.h>
dht11 DHT;
#define LED 13
#define AD A5
#define DHT11_PIN 2
const int wenduPin = A0;
void setup(){
    Serial.begin(9600);
    pinMode(wenduPin, INPUT);
    /*
    Serial.println("DHT TEST PROGRAM ");
    Serial.print("LIBRARY VERSION: ");
    Serial.println(DHT11LIB_VERSION);
    Serial.println();
    */
    //Serial.println("Type,status,Humidity (%),AD (lx),Temperature (C),MAXTemperature (C),avrTemperature (C)");
} 
void loop(){
    int chk;
    int Buffer=0;//Define a variable to record the CDS value
    float wendu = analogRead(wenduPin)*0.488;
    Buffer=analogRead(AD);
    Serial.print("DHT11,");
    chk = DHT.read(DHT11_PIN); 
      switch (chk){
        case DHTLIB_OK: 
        Serial.print("It   is   okay,"); 
        break;
        case DHTLIB_ERROR_CHECKSUM: 
        Serial.print("Checksum error,"); 
        break;
        case DHTLIB_ERROR_TIMEOUT: 
        Serial.print("Time out error,"); 
        break;
        default: 
        Serial.print(" Unknown error,\t"); 
        break;

   }
    float h = DHT.humidity;
    float t = DHT.temperature;
    Serial.print(h,1);
    Serial.print(",");
    Serial.print(wendu); 
    Serial.print(",");
    Serial.println(Buffer);
    delay(1000);
    
}