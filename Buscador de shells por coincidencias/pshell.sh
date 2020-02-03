#!/bin/bash

#Variable interna
#domex dominio extraido domainextraction function
#numeropuntos valor de puntos existente en el dominio
rm -f respuesta1.txt
rm -f respuesta2.txt
rm -f respuesta3.txt
rm -f r1.txt
rm -f r2.txt
rm -f r3.txt
rm -f coincidenciadom.txt
rm -f coincidenciaip.txt
rm -f coincidencia1.txt
rm -f coincidencia2.txt
rm -f coincidencia3txt
rm -f shell1.txt
rm -f shell2.txt
rm -f shell3.txt
cd ./
source whodomip.sh

	function domainextraction ()
		{
				predomex=$(echo $d | cut -d '/' -f3 | cut -d '.' -f1 )
					if [[ $predomex = "www" ]]
					then
						d=$(echo $d | cut -d '/' -f3 | cut -d '.' -f2-)
					fi


				numeropuntos=$(echo $d | cut -d '/' -f3 | grep -Eo '[.]{1}'|wc -l)
				if [[ $numeropuntos -eq 1 ]] 
				then
					domex=$(echo $d | cut -d '/' -f3 ) 
				else
					subdomex=$(echo $d | cut -d '/' -f3 | cut -d '.' -f$((numeropuntos)))
					if [[ "$subdomex" == "com" || "$subdomex" == "co" || "$subdomex" == "gov" || "$subdomex" == "org"  ]] 
					then
					domex=$(echo $d | cut -d '/' -f3 | cut -d '.' -f$((numeropuntos-1))- )
					else
					domex=$(echo $d | cut -d '/' -f3 | cut -d '.' -f$((numeropuntos))- ) 
					fi
				fi				
				echo $domex


		}

		function restdomainextraction ()
		{
					domex=$(echo $d | cut -d '/' -f3)
					echo $domex


		}
	function files ()
		{
			numeroslash=$(echo $1 | grep -Eo '[/]{1}'|wc -l)

			if [[ $numeroslash > 3 ]];then
				{
					Dir1=$(echo $1 | cut -d '/' -f$((numeroslash)))			

					if [[ $numeroslash > 4 ]];then
						{
							Dir2=$(echo $1 | cut -d '/' -f$((numeroslash-1))-$((numeroslash)))
						}
                                        else 
						{
							Dir2=""
						}
					fi
				
					if [[ $numeroslash > 5 ]];then
						{
							Dir3=$(echo $1 | cut -d '/' -f$((numeroslash-2))-$((numeroslash)))
						}
					else 
						{
							Dir3=""
						}
					fi
				}
			fi
			Dir4=$(echo $1 | cut -d '/' -f4-)

		echo "/"$Dir1"/"",""/"$Dir2"/"",""/"$Dir3"/"","$Dir4""
		}


	domi=$(echo $Domain)
	directories=$(echo $( files $(echo $dom )))
	dir1=$(echo $directories | cut -d "," -f3)		
	dir2=$(echo $directories | cut -d "," -f2)
	dir3=$(echo $directories | cut -d "," -f1)
	dir4=$(echo $directories | cut -d "," -f4)


	
echo -e "$title POSIBLE(S) SHELL(S) POR COINCIDENCIA DE DOMINIO EN:$back"
#PATRON DOMINIO
grep  $Domain FINALDATASHELLS.txt | cut -d "," -f2 > coincidenciadom.txt
if [[ $(cat coincidenciadom.txt) != "" ]];then
	 
	cat coincidenciadom.txt
fi
echo -e "$title POSIBLE(S) SHELL(S) POR COINCIDENCIA DE IP EN:$back"
#PATRON IP
if [[ $IPIP != "" ]]
then
	grep  $IPIP FINALDATASHELLS.txt | cut -d "," -f2 > coincidenciaip.txt
	if [[ $(cat coincidenciaip.txt) != "" ]];then
		 
		cat coincidenciaip.txt
	fi
fi



echo -e "$title POSIBLE(S) SHELL(S) POR COINCIDENCIA DE PATRONES EN URL :$back"
#PATRON DIRECTORIOS
	
	# COINCIDENCIA NIVEL 1
		
		if [[ $dir3 != "//" ]]
		then
			n1=$(grep -c $dir3 FINALDATATICKETS.txt)
			if [[ $n1 > 0 ]]
			then
				grep  $dir3 FINALDATATICKETS.txt >> c1.txt
				
				echo "Existen $n1 casos con una coincidencia de 1 carpeta en la ultima posición con esta URL"
				#Proceso NIVEL1
				echo "Desea visualizarlas? y/n"
				read  v1
				  case $v1 in
					  y|Y) 
					    
					 		 cat c1.txt | sort | uniq > coincidencia1.txt
							cat coincidencia1.txt

 
					  ;;
					  n|N)
							cat c1.txt | sort | uniq > coincidencia1.txt
						echo " "	 
					  ;;
					  *)
						 echo "Seleccion no reconocida, no se visualizará"
					  ;;
				  esac

				echo "Espere, encontrando coincidencias..."			
			
				nts1=0
				for d in $(cat coincidencia1.txt)
				do	 	
	 			d1=$(echo $(domainextraction $(echo $d)))
				dominiourl=$(echo $(restdomainextraction $(echo $d)))			
				#Proceso NIVEL1 
					grep $d1 FINALDATASHELLS.txt | cut -d "," -f2  >> shell1.txt

						for s in $(cat shell1.txt)
							do
								f1=$(echo $( files $(echo $s ))| cut -d "," -f4)	
						
							 echo "http://"$dominiourl"/"$f1 >> respuesta1.txt
						done
				done
					echo "Existen shells con  coincidencia NIVEL1"
					#Proceso NIVEL1
					if [[ $nst1 != 0 ]]
					then
						echo "Desea visualizarlas? y/n"
						read  v1
						  case $v1 in
							  y|Y) 
								echo "Shell con coincidencia NIVEL1 en:"
								cat respuesta1.txt | sort | uniq > r1.txt
								cat r1.txt 
							  ;;
							  n|N)
								echo " "	 
							  ;;
							  *)
								 echo "Seleccion no reconocida, no se visualizará"
							  ;;
						  esac
					fi
			fi
		fi
	#COINCIDENCIA NIVEL 2		
		if [[ $dir2 != "//" ]]
		then 		
			n2=$(grep -c $dir2 FINALDATATICKETS.txt)
			if [[ $n2 > 0 ]]
			then
				
					grep  $dir2 FINALDATATICKETS.txt >> c2.txt
				echo "Existen $n2 casos con una coincidencia de 2 carpetas en la ultima posición con esta URL"
				#Proceso NIVEL1
				echo "Desea visualizarlas? y/n"
				read  v2
				  case $v2 in
					  y|Y) 
					    
					  		cat c2.txt | sort | uniq > coincidencia2.txt
							cat coincidencia2.txt 
					  ;;
					  n|N)
							cat c2.txt | sort | uniq > coincidencia2.txt
						echo " "	 
					  ;;
					  *)
						 echo "Seleccion no reconocida, no se visualizará"
					  ;;
				  esac

				echo "Espere, encontrando coincidencias..."			
			

				for d in $(cat coincidencia2.txt)
				do	 	
	 			d2=$(echo $(domainextraction $(echo $d)))
				dominiourl=$(echo $(restdomainextraction $(echo $d)))			
				#Proceso NIVEL1
					  
					grep $d2 FINALDATASHELLS.txt | cut -d "," -f2  >> shell2.txt

						for s in $(cat shell2.txt)
							do
								f2=$(echo $( files $(echo $s ))| cut -d "," -f4)	
						
							 echo "http://"$dominiourl"/"$f2 >> respuesta2.txt
						done
				done
					echo "Existen  shells con  coincidencia NIVEL2"
					#Proceso NIVEL2
					echo "Desea visualizarlas? y/n"
					read  v2
					  case $v2 in
						  y|Y) 
							echo "Shell con coincidencia NIVEL2 en:"
							cat respuesta2.txt | sort | uniq > r2.txt
							cat r2.txt 						  
							;;
						  n|N)
							cat respuesta2.txt | sort | uniq > r2.txt
							echo " "	 
						  ;;
						  *)
							 echo "Seleccion no reconocida, no se visualizará"
						  ;;
					  esac
			fi	
		fi
	#COINCIDENCIA NIVEL 3


		if [[ $dir1 != "//" ]]
		then 	
			n3=$(grep -c $dir1 FINALDATATICKETS.txt)
			if [[ $n3 > 0 ]]
			then
				grep  $dir1 FINALDATATICKETS.txt >> c3.txt
				echo "Existen $n3 casos con una coincidencia de 3 carpetas en la ultima posición con esta URL"
				#Proceso NIVEL3
				echo "Desea visualizarlas? y/n"
				read  v3
				  case $v3 in
					  y|Y) 
					  cat c3.txt | sort | uniq > coincidencia3.txt
							cat coincidencia3.txt 
					  ;;
					  n|N)
						cat c3.txt | sort | uniq > coincidencia3.txt
						echo " "	 
					  ;;
					  *)
						 echo "Seleccion no reconocida, no se visualizará"
					  ;;
				  esac
				echo " "
				echo "Espere, encontrando coincidencias..."			
			    echo " "

				for d in $(cat coincidencia3.txt)
				do	 	
	 			d3=$(echo $(domainextraction $(echo $d)))
				dominiourl=$(echo $(restdomainextraction $(echo $d)))				
				#Proceso NIVEL3
					  
					grep $d3 FINALDATASHELLS.txt | cut -d "," -f2  >> shell3.txt

						for s in $(cat shell3.txt)
							do
								f3=$(echo $( files $(echo $s ))| cut -d "," -f4)	
						
							 echo "http://"$dominiourl"/"$f3 >> respuesta3.txt
						done
				done
					echo "Existen shells con  coincidencia NIVEL3"
					echo " "
					#Proceso NIVEL3
					echo "Desea visualizarlas? y/n"
					read  v3
					  case $v3 in
						  y|Y)
							echo " " 
							echo "Shell con coincidencia NIVEL3 en:"
							cat respuesta3.txt | sort | uniq > r3.txt
							cat r3.txt 
						  ;;
						  n|N)
							cat respuesta3.txt | sort | uniq > r3.txt
							echo " "	 
						  ;;
						  *)
							 echo "Seleccion no reconocida, no se visualizará"
						  ;;
					  esac
			fi
		fi	
	
rm -f respuesta1.txt
rm -f respuesta2.txt
rm -f respuesta3.txt
rm -f coincidenciadom.txt
rm -f coincidenciaip.txt
rm -f coincidencia1.txt
rm -f coincidencia2.txt
rm -f coincidencia3.txt
rm -f c1.txt
rm -f c2.txt
rm -f c3.txt
rm -f r1.txt
rm -f r2.txt
rm -f r3.txt
rm -f shell1.txt
rm -f shell2.txt
rm -f shell3.txt
read -n1 -r -p "Press any key to continue..." key
			
