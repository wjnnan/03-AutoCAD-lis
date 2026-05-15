from pyautocad import Autocad, APoint

acad = Autocad(create_if_not_exists=True)
print("Link established between Python and AutoCAD!\nCurrent document: " + acad.doc.Name)

text_string = "Greetings from Python!"
insertion_point = APoint(50, 50)  # Define the position in the drawing
text_height = 10  # Text height
text_length_factor = 0.7  # Adjust this factor for approximate character width
text_width = len(text_string) * text_height * text_length_factor  # Approximate text width
buffer = 10  # Buffer around the text box

# Add the "Hello World!" text to model space
text_entity = acad.model.AddText(text_string, insertion_point, text_height)
print("Textbox added to AutoCAD at (50, 50)")

# Define the zoom window based on the text box dimensions
lower_left = APoint(insertion_point.x - buffer, insertion_point.y - buffer)
upper_right = APoint(insertion_point.x + text_width + buffer, insertion_point.y + text_height + buffer)

print(f"Insertion Point: ({insertion_point.x}, {insertion_point.y})")
print(f"Lower Left: ({lower_left.x}, {lower_left.y})")
print(f"Upper Right: ({upper_right.x}, {upper_right.y})")

# Use the AutoCAD command to zoom to the defined window
acad.doc.SendCommand(f"._zoom W {lower_left.x},{lower_left.y} {upper_right.x},{upper_right.y} ")

acad.doc.Regen(1)  # Refresh the view
print("View centered on the text box.")