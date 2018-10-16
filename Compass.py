#!/usr/bin/env python2
#
# Compass demo for TinkerTech Raspberry Pi class
#
#
# Written: 9/30/2018
#    Rev.: 1.00
#      By: Robert S. Rau & Rob F. Rau II
#  Source: Modified from example
#
# Updated: 
#    Rev.: 1.01
#      By: Robert S. Rau & Rob F. Rau II
# Changes: Folded magnetometer read into loop

#print "I started"
import sys, getopt
#sys.path.append('.')
from time import sleep
from math import sin, cos
import Adafruit_SSD1306        # for OLED
import subprocess  # needed?
import RTIMU                   # for magnetometer
from PIL import Image          # for OLED
from PIL import ImageDraw      # for OLED
from PIL import ImageFont      # for OLED

#print "I imported libraries"
OLEDHeight=64
OLEDWidth=128

ArrowLength=36
#theta=0
magnetic_deviation = -7.0     # in degrees, -7 for Ypsilanti. See http://www.compassdude.com/compass-declination.php

RST = 24

SETTINGS_FILE = "RTIMULib"

s = RTIMU.Settings(SETTINGS_FILE)
imu = RTIMU.RTIMU(s)

imu.IMUInit()

# Slerp power controls the fusion and can be between 0 and 1
# 0 means that only gyros are used, 1 means that only accels/compass are used
# In-between gives the fusion mix.
imu.setSlerpPower(0.4)
imu.setGyroEnable(True)
imu.setAccelEnable(True)
imu.setCompassEnable(True)
#print "I initialized the IMU"
poll_interval = imu.IMUGetPollInterval()
print poll_interval

class ArrowPoints:
    def __init__(self,ArrowEndX,ArrowEndY,TailEndX,TailEndY,ArrowLeftX,ArrowLeftY,ArrowRightX,ArrowRightY):
        self.CompArrowEndX = ArrowEndX
        self.CompArrowEndY = ArrowEndY
        self.CompTailEndX = TailEndX
        self.CompTailEndY = TailEndY
        self.CompArrowLeftX = ArrowLeftX
        self.CompArrowLeftY = ArrowLeftY
        self.CompArrowRightX = ArrowRightX
        self.CompArrowRightY = ArrowRightY

class OLEDSpaceCoord:
    def __init__(self,ArrowEndX,ArrowEndY,TailEndX,TailEndY,ArrowLeftX,ArrowLeftY,ArrowRightX,ArrowRightY):
        self.OLEDArrowEndX = ArrowEndX
        self.OLEDArrowEndY = ArrowEndY
        self.OLEDTailEndX = TailEndX
        self.OLEDTailEndY = TailEndY
        self.OLEDArrowLeftX = ArrowLeftX
        self.OLEDArrowLeftY = ArrowLeftY
        self.OLEDArrowRightX = ArrowRightX
        self.OLEDArrowRightY = ArrowRightY

    def assign(self, otherOLEDSpaceCoord):
	self.OLEDArrowEndX = otherOLEDSpaceCoord.OLEDArrowEndX
	self.OLEDArrowEndY = otherOLEDSpaceCoord.OLEDArrowEndY
        self.OLEDTailEndX = otherOLEDSpaceCoord.OLEDTailEndX
        self.OLEDTailEndY = otherOLEDSpaceCoord.OLEDTailEndY
        self.OLEDArrowLeftX = otherOLEDSpaceCoord.OLEDArrowLeftX
        self.OLEDArrowLeftY = otherOLEDSpaceCoord.OLEDArrowLeftY
        self.OLEDArrowRightX = otherOLEDSpaceCoord.OLEDArrowRightX
        self.OLEDArrowRightY = otherOLEDSpaceCoord.OLEDArrowRightY


def CenterCoord2OLEDCoord(arrowPoints):
    global OLEDWidth
    global OLEDHeight
    XOffset = OLEDWidth/2
    YOffset = OLEDHeight/2

    oledArrowEndX = arrowPoints.CompArrowEndX+XOffset
    oledArrowEndY = arrowPoints.CompArrowEndY+YOffset
    oledTailEndX = arrowPoints.CompTailEndX+XOffset
    oledTailEndY = arrowPoints.CompTailEndY+YOffset
    oledArrowLeftX = arrowPoints.CompArrowLeftX+XOffset
    oledArrowLeftY = arrowPoints.CompArrowLeftY+YOffset
    oledArrowRightX = arrowPoints.CompArrowRightX+XOffset
    oledArrowRightY = arrowPoints.CompArrowRightY+YOffset

    oledSpaceCoord = OLEDSpaceCoord(oledArrowEndX, oledArrowEndY, oledTailEndX, oledTailEndY, oledArrowLeftX, oledArrowLeftY, oledArrowRightX, oledArrowRightY)
    return oledSpaceCoord

def Theta2ArrowPoints(Theta):
    global ArrowLength

    RotatedArrowEndX = -24*sin(Theta)
    RotatedArrowEndY = 24*cos(Theta)
    RotatedTailEndX = 24*sin(Theta)
    RotatedTailEndY = (-24)*cos(Theta)
    RotatedArrowLeftX = -4*cos(Theta)-15*sin(Theta)
    RotatedArrowLeftY = -4*sin(Theta)+15*cos(Theta)
    RotatedArrowRightX = 4*cos(Theta)-15*sin(Theta)
    RotatedArrowRightY = 4*sin(Theta)+15*cos(Theta)

    RotatedCoord = ArrowPoints(RotatedArrowEndX, RotatedArrowEndY, RotatedTailEndX, RotatedTailEndY, RotatedArrowLeftX, RotatedArrowLeftY, RotatedArrowRightX, RotatedArrowRightY)
    return RotatedCoord

def eraseOldOledCoords(BlackDrawCoords):
# Compass needle features, 4 points to draw 3 lines, 2 lines for arrow head and 1 for arrow body
    draw.line((BlackDrawCoords.OLEDArrowEndX, BlackDrawCoords.OLEDArrowEndY, BlackDrawCoords.OLEDTailEndX, BlackDrawCoords.OLEDTailEndY), fill=0)
    draw.line((BlackDrawCoords.OLEDArrowEndX, BlackDrawCoords.OLEDArrowEndY, BlackDrawCoords.OLEDArrowLeftX, BlackDrawCoords.OLEDArrowLeftY), fill=0)
    draw.line((BlackDrawCoords.OLEDArrowEndX, BlackDrawCoords.OLEDArrowEndY, BlackDrawCoords.OLEDArrowRightX, BlackDrawCoords.OLEDArrowRightY), fill=0)

def drawOledCoords(newOledCoords):
# Compass needle features, 4 points to draw 3 lines, 2 lines for arrow head and 1 for arrow body
    draw.line((newOledCoords.OLEDArrowEndX, newOledCoords.OLEDArrowEndY, newOledCoords.OLEDTailEndX, newOledCoords.OLEDTailEndY), fill=255)
    draw.line((newOledCoords.OLEDArrowEndX, newOledCoords.OLEDArrowEndY, newOledCoords.OLEDArrowLeftX, newOledCoords.OLEDArrowLeftY), fill=255)
    draw.line((newOledCoords.OLEDArrowEndX, newOledCoords.OLEDArrowEndY, newOledCoords.OLEDArrowRightX, newOledCoords.OLEDArrowRightY), fill=255)


# 128x64 display with hardware I2C:
disp = Adafruit_SSD1306.SSD1306_128_64(rst=RST)

# Initialize library.
disp.begin()


##################
# OLED init
##################

# Clear display.
disp.clear()
disp.display()

# Create blank image for drawing.
# Make sure to create image with mode '1' for 1-bit color.
width = disp.width
height = disp.height
image = Image.new('1', (width, height))

# Get drawing object to draw on image.
draw = ImageDraw.Draw(image)

# Draw a black filled box to clear the image.
draw.rectangle((0,0,width,height), outline=0, fill=0)

# First define some constants to allow easy resizing of shapes.
padding = 2
bottom = height-padding

##################
# Compass init
##################

newOledCoords = CenterCoord2OLEDCoord(Theta2ArrowPoints(0))
oldOledCoords = CenterCoord2OLEDCoord(Theta2ArrowPoints(0))

# Start with old and new arrows pointing north
#DefaultArrowPoints = Theta2ArrowPoints(0)
oldOledCoords.assign(newOledCoords)

# Compass points
#   Load default font.
font = ImageFont.load_default()

#   Write Compass points.
draw.text((width/2-2, -3),    'N',  font=font, fill=255)
draw.text((width/2-2, bottom-7), 'S', font=font, fill=255)
draw.text((30, bottom/2-3), 'W', font=font, fill=255)
draw.text((91, bottom/2-3), 'E', font=font, fill=255)

yawoff = 0    #  Y offset in radians

TotalOffset = -yawoff + (magnetic_deviation*3.141592/180)
################
# Loop
################

while (True):
#    imu.IMUInit()
#    imu.setSlerpPower(0.1)
#    imu.setGyroEnable(True)
#    imu.setAccelEnable(True)
#    imu.setCompassEnable(True)
#    sleep (0.3)
    if imu.IMURead():
        data = imu.getIMUData()
        fusionPose = data["fusionPose"]
        theta = (fusionPose[2]) + TotalOffset
        print theta
        newArrowPoints = Theta2ArrowPoints(theta)
        newOledCoords = CenterCoord2OLEDCoord(newArrowPoints)

        eraseOldOledCoords(oldOledCoords)
        drawOledCoords(newOledCoords)

        oldOledCoords.assign(newOledCoords)

# Display image.
        disp.image(image)
        disp.display()

    else:
        print "No new reading available"
