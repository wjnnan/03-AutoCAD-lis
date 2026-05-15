from pyautocad import Autocad, APoint
import os
import cv2
import numpy as np

# Constants
image_path = r"C:\Users\amcte\Downloads\example_geolocation.png"
autocad_origin = (2023675.152, 439412.454)
scale = 0.8

# Initialize AutoCAD
acad = Autocad(create_if_not_exists=True)
doc = acad.doc

acad.get_selection("Test")

# Load the image
if os.path.exists(image_path):
    if os.path.getsize(image_path) != 0:
        if os.access(image_path, os.R_OK):
            image = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
        else:
            print("File is not readable")
    else:
        print("File is empty")
else:
    print("File not found at " + image_path)

# Apply edge detection
edges = cv2.Canny(image, 100, 100)
# Find contours which could represent sidewalks
contours, _ = cv2.findContours(edges, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
# Simplify contours to reduce the number of points
simplified_contours = [cv2.approxPolyDP(cnt, 3, True) for cnt in contours]

# Function to convert image coordinates to AutoCAD coordinates
def image_to_autocad_coords(x, y, image_width, image_height, autocad_origin, scale):
    autocad_x = autocad_origin[0] + x * scale
    autocad_y = autocad_origin[1] + (image_height - y) * scale
    return APoint(autocad_x, autocad_y)

# Draw the detected shapes in AutoCAD
for contour in simplified_contours:
    for i in range(len(contour) - 1):
        start_point = image_to_autocad_coords(contour[i][0][0], contour[i][0][1], image.shape[1], image.shape[0], autocad_origin, scale)
        end_point = image_to_autocad_coords(contour[i+1][0][0], contour[i+1][0][1], image.shape[1], image.shape[0], autocad_origin, scale)
        acad.model.AddLine(start_point, end_point)