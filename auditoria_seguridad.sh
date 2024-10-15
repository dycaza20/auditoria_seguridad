#!/bin/bash
# Auditoría de Seguridad en Linux
# Autor: Diego José Ycaza Gómez 
# Fecha: 14 de Octubre del 2024

# Primero se verifica si tenemos privilegios de root

if ["$EUID" -ne 0]; then
 echo "Permisos insuficientes. Porfavor ejecutar el script como root."
 exit
fi

# Creamos el directorio para los informes
OUTPUT_DIR="informe_auditoria_$(date +%Y%m%d_%Y%m%d_%H%M%S)" 
#Guardamos el archivo que nos da la fecha actual  dentro de una variable
mkdir "$OUTPUT_DIR"

# Vamos a crear una funcion para mostrar los mensajes con marca de tiempo
function mensaje {
	echo "[$(date +"%H:%M:%S")] $1"	
}

#Dato 1: Información del sistema 

mensaje "Obteniendo información del sistema..."
echo "Información del SO:" > "$OUTPUT_DIR/info_sistema.txt"
lsb_release -a >> "$OUTPUT_DIR/info_sistema.txt" 2>/dev/null

echo -e "\nInformación del Kernel:" >> "$OUTPUT_DIR/info_sistema.txt"

uname -a >> "$OUTPUT_DIR/info_sistema.txt" 
#NOTA: Se van a crear distintos archivos de acuerdo al dato que se extraiga


#Dato 2: Informacion de los usuarios y sus grupos pertenecientes 

mensaje "Listando usurios y grupos..."
echo "Usurios del sistema:" > "$OUTPUT_DIR/usuarios.txt" 
cut -d: -f1 /etc/passwd  >> "$OUTPUT_DIR/usuarios.txt"

echo "Grupos del sistema:" > "$OUTPUT_DIR/grupos.txt"
cut -d: -f1 /etc/group >> "$OUTPUT_DIR/grupos.txt"

#Dato 3: Información de los usuarios con privilegios

mensaje "Identificando usuarios con privilegios sudo..."
echo "Usuarios con privilegios sudo:" > "$OUTPUT_DIR/usuarios_sudo.txt"
getent group sudo | awk -F: '{print $4}' >> "$OUTPUT_DIR/usuarios_sudo.txt"


# Dato 4: Información de los procesos en ejecución 

mensaje "Listando procesos en ejecución..."
ps aux --sort=-%mem | head -n 20 > "$OUTPUT_DIR/procesos.txt"

mensaje "Listando servicios activos..."
service --status-all | grep '+' > "$OUTPUT_DIR/servicios.txt"

# Dato 5: Verificacion sobre las conexiones de red y puertos abiertos


mensaje "Obteniendo conexiones de red y puertos abiertos..."

netstat -tulnp > "$OUTPUT_DIR/puertos_abiertos.txt"


# Dato 6: Verificar permisos en archivos criticos

mensaje "Verificando permisos de archivos criticos..."
echo "Permisos de /etc/passwd:" > "$OUTPUT_DIR/permisos_archivos.txt"
ls -l /etc/passwd >> "$OUTPUT_DIR/permisos_archivos.txt"

echo -e "\nPermisos de /etc/shadow:" >> "$OUTPUT_DIR/permisos_archivos.txt"
ls -l /etc/shadow >> "$OUTPUT_DIR/permisos_archivos.txt"

echo -e "\nPermisos de /etc/sudoers:" >> "$OUTPUT_DIR/permisos_archivos.txt"
ls -l /etc/sudoers >> "$OUTPUT_DIR/permisos_archivos.txt"


#Dato 7: Obtener configuración del firewall

mensaje "Obteniendo configuración del firewall..."

if command -v ufw >/dev/null 2>&1;then
	ufw status verbose > "$OUTPUT_DIR/firewall.txt"
else 
	iptables -L -n -v > "$OUTPUT_DIR/firewall.txt"
fi


#Dato 8: Obtener actualizaciones pendientes

mensaje "Verificando actualizaciones pendientes..."
apt list --upgradable > "$OUTPUT_DIR/actualizaciones.txt" 2>/dev/null



#Dato 9: Buscar rootkits conocidos

apt install -y chkrootkit 

mensaje "Buscando rootkits conocidos..."
chkrootkit > "$OUTPUT_DIR/rootkits.txt"

mensaje "Generando informe consolidado..."
cat "$OUTPUT_DIR"/*.txt > "$OUTPUT_DIR/informe_consolidado.txt"

mensaje "Auditoria completada. Los informes se encuentran en el directorio $OUTPUT_DIR."

