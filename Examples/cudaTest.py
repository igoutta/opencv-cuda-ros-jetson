# Sanity test: verifica que OpenCV fue compilado con CUDA y rota una imagen en la GPU
# Uso: python3 cudaTest.py [imagen.jpg]
import sys
import cv2

# Verificar que OpenCV tiene soporte CUDA y que hay una GPU disponible
print("OpenCV version: {}".format(cv2.__version__))
if cv2.cuda.getCudaEnabledDeviceCount() == 0:
    sys.exit("OpenCV was built without CUDA, or no CUDA device was found")

# Leer una imagen desde un archivo (por defecto myimage.jpg)
path = sys.argv[1] if len(sys.argv) > 1 else "myimage.jpg"
image = cv2.imread(path)
if image is None:
    sys.exit("Could not read image: {}".format(path))

# Almacenar la imagen en la memoria de la GPU
src = cv2.cuda_GpuMat()
src.upload(image)

# Aplicar la rotación usando la GPU
a = cv2.cuda.rotate(src=src, dsize=(414, 500), angle=12, xShift=0, yShift=0, interpolation=cv2.INTER_NEAREST)

# Descargar la imagen de la GPU y visualizarla
result = a.download()
cv2.imshow("Result", result)
cv2.waitKey(0)
