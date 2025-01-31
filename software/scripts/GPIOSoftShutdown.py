#!/usr/bin/env python

'''
A script to detect the soft shutdown button, and then initiate a shutdown
Can also detect a low battery warning from the atmega
'''
#import wiringpi as wp
import RPi.GPIO as GPIO
import os
import time

SDN_AVR_CTRL_PIN = 11 # function is guessed.
PI_BUTTON_PIN = 22 # function is guessed.
AVR_REQUEST_PIN = 10 # function is guessed.

def init():
    GPIO.setmode(GPIO.BCM)
    
    GPIO.setup(PI_BUTTON_PIN,GPIO.IN,pull_up_down=GPIO.PUD_UP)
    GPIO.setup(AVR_REQUEST_PIN,GPIO.IN,pull_up_down=GPIO.PUD_UP)

    GPIO.setup(SDN_AVR_CTRL_PIN,GPIO.OUT)
    GPIO.output(SDN_AVR_CTRL_PIN,GPIO.HIGH)


def shutdown():
    # tell the Atmel to display shutdown message
    GPIO.output(SDN_AVR_CTRL_PIN,GPIO.LOW)
    time.sleep(0.5)

    # shutdown the Pi, it will reboot...
    os.system("sudo halt")

def checkBUTTON():
    if GPIO.input(PI_BUTTON_PIN) == GPIO.LOW:
        #wait for held down
        time.sleep(0.5)
        if GPIO.input(PI_BUTTON_PIN) == GPIO.LOW:
            print("SDN button pressed (GPIO22) -- shutting down")
            shutdown()

def checkATMEGA():
    if GPIO.input(AVR_REQUEST_PIN) == GPIO.LOW:
        # long timer to prevent programming from falsely trigerring a
        # shutdown
        time.sleep(15)
        if GPIO.input(AVR_REQUEST_PIN) == GPIO.LOW:
            print("Atmel request (GPIO10) -- shutting down")
            shutdown()

if __name__ == '__main__':
    init()
    print('Init done')
    while True:
        checkBUTTON()
        checkATMEGA()
        time.sleep(0.2)
