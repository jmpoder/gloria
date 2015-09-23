#!/bin/bash

# Log de operaciones realizadas
LOG=""

function mostrar_banner {
	echo ""
	echo "    _____)                  "
	echo "   /         /)        ,    "
	echo "  /   ___   // _____     _  "
	echo " /     / ) (/_(_)/ (__(_(_(_"
	echo "(____ /  "
	echo ""
	echo "En base a lo que haz traido, analizare los archivos"
	echo ""
}

function verificar_parametros {
	echo "Verificando parametros"
	echo ""
	
    # Verificar si se han recibido los parametros
    if (( $# < 2 )); then
        echo "Parametros incorrectos"
        mostrar_uso
        exit
    fi

    # Verificar si se puede leer el archivo 1
    if [ ! -r $1 ]; then
        echo "No se puede leer $1"
        mostrar_uso
        exit
    fi

    # Verificar si se puede leer el archivo 2
    if [ ! -r $2 ]; then
        echo "No se puede leer $2"
        mostrar_uso
        exit
    fi

    # Verificar permisos de escritura sobre directorio actual
    if [ ! -w "./" ]; then
        echo "No se puede guardar archivo de log en directorio actual"
        mostrar_uso
        exit
    fi
}

function mostrar_uso {
    echo ""
    echo "Uso del script"
    echo ""
    echo "# gloria.sh arc1 arc2"
    echo ""
    echo "Gloria realiza un volcado hexadecimal de arc1 y arc2, luego"
    echo "realiza una comparacion de estos en busca de cambios, estos"
    echo "cambios se cuenta a nivel de bytes."
    echo ""
    echo "Asumiendo arc1 como archivo original, se comparan los cambios"
    echo "y se determina que tan parecido es arc2 a arc1, si se agrego"
    echo "o elimino contenido del mismo, en la carpeta de ejecucion de"
    echo "gloria se guarda un archivo con los hallazgos (gloria.log)."
    echo ""
    echo "Nota: para gantizar el correcto funcionamiento gloria debe"
    echo "tener permisos de lectura sobre los archivos y de escritura"
    echo "sobre el directorio de ejecucion."
    echo ""
}

function comparar_md5 {
    amd5=$(md5sum $1 | awk '{print $1}')
    bmd5=$(md5sum $2 | awk '{print $1}')
    
    echo "+------------------------------------------------------------+"
    echo "|                Compararion de Hash MD5                     |"
    echo "+------------------------------------------------------------+"
    echo "| $(basename $1): $amd5"
    echo "| $(basename $2): $bmd5"
    echo "+------------------------------------------------------------+"

    if [ "$amd5" = "$bmd5" ]; then
        echo "|            La huella de los archivos coinciden             |"
        echo "+------------------------------------------------------------+"
        exit 0
    else
        echo "| Los archivos tienen huellas diferentes, se realizara un    |"
        echo "| analisis diferencial para detectar porcentaje de similitud |"
        echo "+------------------------------------------------------------+"
    fi
    
    echo ""
}

function obtener_volcado_hex {
	
    echo "Volcando archivo $1"

    filename=$(basename $1)

    hexdump -v -e '1/1 "%01x " "\n"' $1 | grep -v "*" > "./$filename.hex"

    retval=$?

    if [ ! $retval -eq 0 ]; then
        echo "No se pudo realizar volcado de archivo $1"
        exit $retval
    fi

	echo ""
}

function obtener_diferencias {
    baseA=$(basename $1)
    sizeA=$(ls -l $1 | awk '{print $5}')
    hexA="$baseA.hex"
    baseB=$(basename $2)
    sizeB=$(ls -l $2 | awk '{print $5}')
    hexB="$baseB.hex"
    difffile="$baseA-$baseB.diff"

    diff -U 0 $hexA $hexB | grep -v ^@ | grep -v ^+++ | grep -v ^--- > $difffile

    dbytesA=$( grep ^- $difffile | wc -l )
    dbytesB=$( grep ^+ $difffile | wc -l )

    diffPorcentajeAB=$(echo "scale=4; ( $dbytesA / $sizeA )*100" | bc -l )
    diffPorcentajeBA=$(echo "scale=4; ( $dbytesA / $sizeB )*100" | bc -l )

	echo "+------------------------------------------------------------+"
	echo "|                Comparacion Diferencial                     |"
	echo "+------------------------------------------------------------+"
	echo "| Bytes $baseA: $sizeA"
	echo "| Bytes $baseB: $sizeB"
	echo "+------------------------------------------------------------+"
	echo "+------------------------------------------------------------+"
	echo "| Bytes Diferentes $baseA: $dbytesA"
	echo "| Bytes Diferentes $baseB: $dbytesB"
	echo "+------------------------------------------------------------+"
	echo "+------------------------------------------------------------+"
	echo "| Relacion diff bytes $baseA / total bytes $baseA "
	echo "+------------------------------------------------------------+"
	echo "| ( $dbytesA / $sizeA ) * 100 = $diffPorcentajeAB %"
	echo "+------------------------------------------------------------+"
	echo "+------------------------------------------------------------+"
	echo "| Relacion diff bytes $baseB / total bytes $baseB "
	echo "+------------------------------------------------------------+"
	echo "| ( $dbytesB / $sizeB ) * 100 = $diffPorcentajeBA %"
	echo "+------------------------------------------------------------+"

	echo ""
	echo "Nota: a menor porcentaje mayor similitud de archivos"
	echo ""
	
    echo "----------------"
    echo ""
    echo ""
    
    rm $difffile
    rm $hexA
    rm $hexB
}

mostrar_banner
verificar_parametros $@
comparar_md5 $1 $2
obtener_volcado_hex $1
obtener_volcado_hex $2
obtener_diferencias $1 $2
