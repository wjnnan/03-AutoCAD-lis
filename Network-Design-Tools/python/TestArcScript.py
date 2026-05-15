# Import modules
import arcpy
from arcgis import GIS
from arcgis.geometry import Point, Polyline, Polygon

# Log in to portal
portal = GIS()  # anonymously

# Create a Point
point_geometry = Point({"x": -118.8066, "y": 34.0006, "spatialReference": {"wkid":4326}})

point_attributes = {"name": "Point", "description": "I am a point"}

# Create a Polyline
polyline_geometry = Polyline({
    "paths": [[
        [-118.821527826096, 34.0139576938577],
        [-118.814893761649, 34.0080602407843],
        [-118.808878330345, 34.0016642996246],
    ]],
    "spatialReference": {"wkid":4326}
})

polyline_attributes = {"name": "Polyline", "description": "I am a Polyline"}

# Create a Polygon
polygon_geometry = Polygon(
    {
        "rings": [
            [
                [-118.818984489994, 34.0137559967283],
                [-118.806796597377, 34.0215816298725],
                [-118.791432890735, 34.0163883241613],
                [-118.79596686535, 34.008564864635],
                [-118.808558110679, 34.0035027131376],
            ]
        ],
        "spatialReference": {"wkid":4326}
    }
)

polygon_attributes = {"name": "Polygon", "description": "I am a Polygon"}

# Create a new map widget
map = portal.map()
map

# Add each of the graphics to the map
map.draw(
    shape=polyline_geometry,
)

map.draw(
    shape=point_geometry,
)

map.draw(
    shape=polygon_geometry,
)

# Center the map to view the polygons
map.center = [34.0122, -118.8055]
map.zoom = 14