import serial
import requests
import time
import socket

def baidu(addr):
    url = "http://api.map.baidu.com/geocoding/v3/?" # Baidu map API interface
    para = {
        "address": addr, # Incoming address parameters
        "output": "json",
        "ak": "please input your ak" # Baidu map open platform application ak
    }
    req = requests.get(url,para)
    req = req.json()
    #print(req)
    #print('-' * 30)
    m = req["result"]["location"]
    g = f"{m['lng']},{m['lat']}"
    #print(g)
    return g
GPS=baidu(addr="your city") #please input your city

ser = serial.Serial(
    port='COM12',                   #port number
    baudrate=9600                  # Baud rate
    parity=serial.PARITY_ODD,      # parity bit
    stopbits=serial.STOPBITS_TWO,  # stop bit
    bytesize=serial.SEVENBITS      # data bits
)
data = ''
i = 0
MAXtemp=0
Argtemp=0.0
sum=0
Tag=0
while True:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80)) # Get host IP

    data = ser.readline()
    if i>=5:
        data2 = data
        data2 = data.decode()
        data2=data2[27:32] # Get Current Temperature
        print(data2)
        M=float(data2)
        sum=sum+M
        Argtemp=sum/i
        if MAXtemp<M: # Get Current MAX Temperature
            MAXtemp=M
        if M > 32:
            Tag = 1

        else:
            Tag = 0

    else:
        f = open('202206031.txt', 'a')  # path to save data
        f.writelines('City,Longitude,Latitude,IP address,Month/ Time/ Year,status,Tpye,Humidity (%),Temperature (C),AD (xl), MAXTemperature (C),avrTemperature (C), Lable\n') # print eigenvalues
    i = i + 1
    MAXtemp1=str(MAXtemp)
    Argtemp1=str(Argtemp)
    if Tag==1:
        Tag1="Alarm"
    else:
        Tag1="Normal"
    #print(MAXtemp)
    #print(Argtemp)
    t = time.time()
    ct = time.ctime(t)

    print(ct, ':', data,MAXtemp,Argtemp,Tag)
    #print(data)
    f = open('202206031.txt', 'a')# path to save data
    f.writelines('Taian') # print city
    f.writelines(',')
    f.writelines(GPS)  # print latitude and longitude
    f.writelines(',')
    f.writelines(s.getsockname()[0]) # print host IP
    f.writelines(',')
    f.writelines(ct) # print host current time
    f.writelines(',')
    f.writelines(data[0:36].decode('utf-8')) # Humidity, temperature, light collected by the print sensor
    f.writelines(',')
    f.writelines(MAXtemp1) # print the MAX Temperature
    f.writelines(',')
    f.writelines(Argtemp1) # print the arg Temperature
    f.writelines(',')
    f.writelines(Tag1) # print the tag
    f.writelines('\n')
    f.close()
