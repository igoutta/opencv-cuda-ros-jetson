# Importar cv2 y cv2.cuda
import cv2
import cv2.cuda as cuda

# Leer una imagen desde un archivo
image = cv2.imread("myimage.jpg")

# Almacenar la imagen en la memoria de la GPU
src = cv2.cuda_GpuMat()
src.upload(image)

# Aplicar la rotación usando la GPU
a = cv2.cuda.rotate(src=src, dsize=(414,500), angle=12, xShift=0, yShift=0, interpolation=cv2.INTER_NEAREST)

# Descargar la imagen de la GPU y visualizarla
result = a.download()
cv2.imshow("Result", result)
cv2.waitKey(0)