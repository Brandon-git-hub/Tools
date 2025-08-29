from PIL import Image

img = Image.open("Assets/ic.png")
img.save("C:/Users/brandon_wu/Pictures/Icon/ic.ico", format='ICO', sizes=[(16,16), (32,32), (48,48), (64,64)])
