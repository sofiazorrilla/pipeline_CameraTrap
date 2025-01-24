# pipeline_CameraTrap

Pipeline to use IA tools to identify animals in camera trap images and videos

## fine tunning

1.  Base de datos de imagenes

### Imagenes

Una parte de los datos de entrenamiento son imagenes tomadas directamente con las cámaras trampa. Los formatos de las imágenes son `.JPG`, muchas tienen los metadatos de las imágenes (fecha de captura, hora, etc).

1. Generar tabla de metadatos para las imagenes usando el script `extract_img_metadata.R` para generar la siguiente tabla en un archivo llamado `annotations.csv`. Todas las fotos y el archivo de anotaciones deberían estar guardados en la misma carpeta llamada `data/imgs`.

`path` = ruta al archivo
`classification` = clase en numero que identifica a la especie representada en la imagen
`label` = etiqueta que corresponde a la clasificacion
`Photo_Time` = fecha y hora de captura de la imagen 
`Location` = folder original (originalmente se refiere a la localidad de la camara trampa)

|path        |classification|label|Photo_Time          |Location|
|------------|--------------|-----|--------------------|--------|
|I__00043.JPG|0             |AVES |2022-07-30T15:02:29Z|AVES    |
|I__00044.JPG|0             |AVES |2022-07-30T19:22:17Z|AVES    |
|I__00045.JPG|0             |AVES |2022-07-30T19:22:17Z|AVES    |

### Videos

1. Extraer frames de los videos (MP4, MOV, M4V) utilizando el script `extract_img_from_video.py`. Se extraen 10 fotos de cada video, especialmente del principio del video, que es cuando más frecuentemente se puede ver el animal. 

2. Utilizar MegaDetector (el detector de animales/personas/vehiculos) para filtrar las imagenes que tienen animales de las que no.

3. Seguir los pasos para la generacion de los metadatos de las imagenes. 



Recortar las imagenes para generar encuadres de los animales detectados en las fotos.