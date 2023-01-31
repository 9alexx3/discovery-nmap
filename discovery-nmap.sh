#!/bin/bash

#SHELLCHECK
    #shellcheck disable=SC2034

# ESTABLECE EL COLOR POR DEFECTO.
reset="\e[0m"
#  ESPECIALES
Clarito="\e[1m"      Negrita="\e[2m"     Subrayado="\e[4m"       Intermitente="\e[5m"
Invertir="\e[7m" # Texto y fondo
Invisible="\e[8m"    Tachado="\e[9m"     Subrayado_Doble="\e[21m"
#  COLORES NORMALES
Negro="\e[30m" Rojo="\e[0;31m"   Verde="\e[32m" Amarillo="\e[33m"
Azul="\e[34m"  Purpura="\e[35m"  Cian="\e[36m"  Blanco="\e[37m"
#  CLARO
CNegro="\e[1;30m"   CRojo="\e[1;31m"   CVerde="\e[1;32m" CAmarillo="\e[1;33m"
CAzul="\e[1;34m"    CPurpura="\e[1;35m"  CCian="\e[1;36m"  CBlanco="\e[1;37m"
#  NEGRITA
NNegro="\e[2;30m"    NRojo="\e[2;31m"    NVerde="\e[2;32m"  NAmarillo="\e[2;33m"
NAzul="\e[2;34m"     NPurpura="\e[2;35m"  NCian="\e[2;36m"  NBlanco="\e[2;37m"

punto="${reset}${NAmarillo}.${reset}"
sn="${CCian}[${reset}${CVerde}S${reset}${Blanco}/${reset}${Rojo}n${reset}${CCian}]${reset}"
parentesis="${CRojo}9${reset}${CNegro})${reset}"

function errorLog(){
   local error="${Rojo}ERROR${reset}${CPurpura}.${reset}\a "
   local id=1
   case "${1}" in
      1) id="No tienes suficientes permisos para ejecutar la dependencia ${reset}${CPurpura}'${reset}${Blanco}nmap${reset}${CPurpura}'" ;;
      2) id="Te falta la dependencia obligatoria ${reset}${CVerde}nmap${reset}${CAmarillo}" ;;
      3) id="Sin la herramienta obligatoria no es posible ejecutar el script." ;;
      4) id="Hay una incidencia a la hora de instalar automáticamente la herramienta necestia ${reset}${CPurpura}'${reset}${Blanco}nmap${reset}${CPurpura}'${reset}${CAmarillo}, por lo que se tendrá que instalar manualmente" ;;
   esac

   echo -e "${error}${CAmarillo}${id}${punto}"
}

function check_neccesary_tools(){

   if ! hash "nmap" 2> /dev/null >/dev/null;then
      echo -e "${CPurpura}\n¿Quieres instalar la herramienta obligatoria? ${sn}"
      if check_yes_no;then
         install_dependencies
      else
         errorLog 3
         echo -e "\n${NAmarillo}Saliendo del script...${reset}\n\n"
         exit 1
      fi
   fi

}


function install_dependencies(){

   check_root "apt"
   apt update >/dev/null 2>/dev/null
   echo -e ""

   if sudo apt install "nmap" -y 2>/dev/null >/dev/null;then
      echo -e "  ${CNegro}[${reset} ${CVerde}+${reset} ${CNegro}]${reset}${Azul} Herramienta obligatoria ${reset}${Purpura}'${reset}${Blanco}nmap${reset}${Purpura}'${reset} ${reset}${Azul}instalada correctamente${punto}"
   else
      echo ""
      errorLog 4
   fi

}


function check_root(){
   ruta=$(which "${1}")
   if sudo -U "${USER}" -l "${ruta}" 2>/dev/null >/dev/null;then
      return 0
   else
      errorLog 1
      return 1
   fi
}


echo -e "\n${Azul}Realizando el descubrimiento de equipos en la red usando nmap y filtros del chat:${reset}"

echo -e "sudo nmap -sn ${1} | grep -E \"^Nmap scan report for|^MAC Address:\" | tr \"\\\n\" \" \" | sed \'s|Nmap|\\\nNmap|g\' | cut -d \" \" -f5,8-"

sudo nmap -sn "${1}" | grep -E "^Nmap scan report for|^MAC Address:" | tr "\n" " " |  sed 's|Nmap|\nNmap|g' | cut -d " " -f5,8- > "./host-nmap.txt"
cat "./host-nmap.txt"
