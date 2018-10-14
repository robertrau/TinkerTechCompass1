# Compass demo for TinkerTech Raspberry Pi class
# Hacked by Bob

import time
#import sys
from math import sin, cos
import Adafruit_SSD1306
import subprocess
from PIL import Image
from PIL import ImageDraw
from PIL import ImageFont

OLEDHeight=64
OLEDWidth=128
ArrowLength=36
theta=0

# Raspberry Pi pin configuration:
# I commented next line since our I2C board doesn't have a reset pin - rsr 9/30/2018
RST = 24
# Note the following are only used with SPI:
#DC = 23
#SPI_PORT = 0
#SPI_DEVICE = 0


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


################
# Loop
################
theta=0
while (True):
    theta = 3.14159/180*float(subprocess.check_output(["python3", "magnatometer.py" ]))+3.14159265

    newArrowPoints = Theta2ArrowPoints(theta)

    newOledCoords = CenterCoord2OLEDCoord(newArrowPoints)

    eraseOldOledCoords(oldOledCoords)
    drawOledCoords(newOledCoords)

    newArrowPoints = Theta2ArrowPoints(theta)
    newOledCoords = CenterCoord2OLEDCoord(newArrowPoints)

    oldOledCoords.assign(newOledCoords)

    # Display image.
    disp.image(image)
    disp.display()


