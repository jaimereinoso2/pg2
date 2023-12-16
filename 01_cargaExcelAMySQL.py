# este programa toma el nombre de un archio excel, le quita ñ y tildes y 
# lo inserta en mysql como tabla.

import pandas as pd 
from unidecode import unidecode

# Nombre del archivo Excel de entrada y hoja
nombre = 'dfcorr1'
archivo_excel = 'datos/' + nombre + '.xlsx'
hoja_excel = 'Sheet1'

# Leer el archivo Excel en un DataFrame
df = pd.read_excel(archivo_excel)
print(df.shape)

# Función para reemplazar tildes y "ñ" en un texto
def reemplazar_tildes_y_ñ(texto):
    texto_sin_tildes = unidecode(texto)
    return texto_sin_tildes.replace('ñ', 'n')

# Iterar a través de todas las columnas del DataFrame
for columna in df.columns:
    if df[columna].dtype == 'object':  # Verificar si la columna contiene texto
        try:
            df[columna] = df[columna].apply(reemplazar_tildes_y_ñ)
        except:
            print('no se pudo procesar ' + columna)

# Guardar el DataFrame modificado en un nuevo archivo Excel


from sqlalchemy import create_engine

# Supongamos que tienes un DataFrame llamado df

# Configura la conexión a la base de datos MySQL
# Debes proporcionar el nombre de usuario, la contraseña, el host y la base de datos adecuados
usuario = 'proyectodegrado2'
contraseña = 'pdg2'
host = 'localhost'  # Por ejemplo, 'localhost'
base_de_datos = 'proyectodegrado2'

# Crea una cadena de conexión
cadena_conexion = f'mysql+mysqlconnector://{usuario}:{contraseña}@{host}/{base_de_datos}'

# Crea una instancia del motor SQLAlchemy
motor = create_engine(cadena_conexion)

# Guarda el DataFrame en una tabla MySQL
nombre_de_tabla = nombre  # Cambia esto al nombre de la tabla que desees
df.to_sql(nombre_de_tabla, motor, if_exists='replace', index=False)

print(f'DataFrame guardado en la tabla {nombre_de_tabla} de la base de datos MySQL.')
