
#!/bin/bash

title="\033[37;44m"
back=" \033[0m"
blink="\033[1;32;40m"

#Funcion para mostrar la respuesta

function response {
     
     echo " "
     echo -e "$title Domain Whois Record                          $back"
     echo " "
     if [[ -n $(whois -H $1 --verbose | grep -i "No whois server is known") ]] #Dominio no encontrado en la base de datos del whois
     then  
      #check los registros de la iana
          if [[ -n $(whois -h whois.iana.org .$(echo $1 | rev | awk -F '.' '{print $1}' |rev ) | grep -i "whois:" | awk -F ' ' '{print $2}' ) ]]
          then
            #caso iana
             tld=$(whois -h whois.iana.org .$(echo $1 | rev | awk -F '.' '{print $1}' |rev ) | grep -i "whois:" | awk -F ' ' '{print $2}')
             whois -H $1 -h $tld --verbose > temp2.txt 
                     if [[ -n $(cat temp2.txt | grep -i "whois server") ]] # Si el reistro whois tiene informacion del registrant
                       then
                           if [[ -n $(cat temp2.txt | grep -i "whois server" | awk -F ' ' '{print $4}') ]] #si el registro no esta vacio
                            then
                              cat temp2.txt
                              whois -H $1 -h $tld -h $(cat temp2.txt | grep -i "WHOIS server" | awk -F ' ' '{ print $4}' )
                           else 
                              cat temp2.txt  
                           fi
                     else
                       cat temp2.txt
                     fi
            #caso iana
                 elif [[ -z $(whois -H $1 -h whois.nic.$(echo $1 | rev | awk -F '.' '{print $1}' | rev ) | grep -i "Domain not found" ) ]]; then
            #caso nic
                 whois -H $1 -h whois.nic.$(echo $1 | rev | awk -F '.' '{print $1}' | rev ) > temp3.txt

                     if [[ -n $(cat temp3.txt | grep -i "whois server") ]] # Si el reistro whois tiene informacion del registrant
                       then
                           if [[ -n $(cat temp3.txt | grep -i "whois server" | awk -F ' ' '{print $4}') ]] #si el registro no esta vacio
                            then
                              cat temp3.txt
                              whois -H $1 -h whois.nic.$(echo $1 | rev | awk -F '.' '{print $1}' | rev ) -h $(cat temp3.txt | grep -i "WHOIS server" | awk -F ' ' '{ print $4}')
                           else 
                              cat temp3.txt  
                           fi
                     else
                       cat temp3.txt
                     fi   
            #caso nic
            

          else
     #caso whois-servers.net
        whois -h $(echo $1 | rev | awk '.' '{print $1}' | rev).whois-servers.net $1 --verbose > temp4.txt

                    if [[ -n $(cat temp4.txt | grep -i "whois server") ]] # Si el reistro whois tiene informacion del registrant
                       then
                           if [[ -n $(cat temp4.txt | grep -i "whois server" | awk -F ' ' '{print $4}') ]] #si el registro no esta vacio
                            then
                              cat temp4.txt
                                                            whois -H $1 -h whois.nic.$(echo $1 | rev | awk -F '.' '{print $1}' | rev ) -h $(cat temp4.txt | grep -i "WHOIS server" | awk -F ' ' '{ print $4}')
                           else 
                              cat temp4.txt  
                           fi
                     else
                       cat temp4.txt
                     fi 

     #caso whois-servers.net
          fi      



     #fin de los registros de la iana

    else #El comando whois si tiene el tld en la base de datos -----check
      whois -H $1 --verbose > temp1.txt 
        if [[ -n $(cat temp1.txt | grep -i "whois server") ]] # Si el reistro whois tiene informacion del registrant
        then
           if [[ -n $(cat temp1.txt | grep -i "whois server" | awk -F ' ' '{print $4}') ]] #si el registro esta vacio
           then
             #echo " "
             cat temp1.txt
             #echo -e "$title Queried $(cat temp1.txt | grep -i "WHOIS server" | awk -F ' ' '{ print $4}') with $1 $back"
             #echo " "
             whois -H $1 -h $(cat temp1.txt | grep -i "WHOIS server" | awk -F ' ' '{ print $4}' )
           else 
             cat temp1.txt  
           fi
        else
        cat temp1.txt
        fi
            
    fi

  



}


function IP {

#IP Extraction

if [[ -n $(dig +short $1 | grep -Eo '[0-9\.]{7,15}') ]]
then
    if [[ 2 -le $(dig +short $1 | wc -l) ]] #si hay mas de una IP
     then
       if [[ -n  $(dig +short $1 | grep -iE '[a-z]') ]] # Si alguna IP es una Cname
        then
          echo -e "$title Ip resolved:                       $back"
			echo $(dig +short $1 | grep -viE '[a-z]')
             IPIP=$(echo $(dig +short $1 | grep -viE '[a-z]'))
        
        else #mas de una Ip
         echo -e "$title IPs resolved:        $back"
        
       fi

    else # solo una Ip desde el principio
       echo -e "$title IP Address:                                  $back"
		echo $(dig +short $1)
       IPIP=$(echo $(dig +short $1)) #dominio
    fi
else
 IPIP= echo "Could no resolve the IP"
 ip=" "
fi

} #End ip extraction function


read -p "Please enter your URL: " dom



#Doamin Extraction and classification process

if [[ 1 -eq $(echo $dom |cut -f3 -d '/'| grep -Eo '[.]{1}' | wc -l) ]]  #el espacio del dominio corresponde al dominio
then
  IP $(echo $dom | cut -f3 -d '/') # check there is no more problems here  
Domain=$(echo $dom | cut -f3 -d '/') 
else
   if [[ $(echo $dom | cut -f3 -d '/' | grep -Eo '[.]{1}' | wc -l) -ge 3 ]] #el espacio del dominio tiene cuatro o mas campos
   then
    tdominio=$(echo $dom | cut -f3 -d '/' | rev | awk -F '.' '{print $1 "." $2 "." $3 "." $4}' | rev)
       if [[ (-n $(dig +short $tdominio)) &&  ( -n $(dig +short $tdominio | grep -i "connection timed out" )) ]] # los cuatro campos tienen una Ip sociada
       then
         IP $(echo $tdominio)
         

              if [[ 2 -le $(echo $tdominio | cut -f1 -d '.' | grep -Eo '[w]' | wc -l) ]] #it has the words www
              then
                #IP $(echo $tdominio)
                Domain=$(echo $tdominio | awk -F '.' '{print $2 "." $3 "." $4}') 
              else  #it doesn't has the words www
    tdominio=$(echo $dom | cut -f3 -d '/' | rev | awk -F '.' '{print $1 "." $2 "." $3}' | rev)

                  if [[ -z $(dig +short $tdominio +noall +answer) ]] #it doesn't have a IP
                  then

                    if  [[ -n $( response $tdominio | grep -i "no match\|no entries found\|No whois server is known\|nameserver not found\|not found" ) ]] #it doesn't have a domain record
                    then
                      #IP  $(echo $tdominio | awk -F '.' '{print $2 "." $3}')
                      Domain=$(echo $tdominio | awk -F '.' '{print $2 "." $3}') 
                    else   #it has a domain record
                      #IP $(echo $tdominio)
                      Domain=$(echo $tdominio) 
                    fi

                  else # si tiene IP

                    if [[ -n $( response $tdominio | grep -i "no match\|no entries found\|No whois server is known\|nameserver not found\|not found"  ) ]]  #si no tiene whois
                    then
                      #IP $(echo $tdominio)
                      Domain=$(echo $tdominio | awk -F '.' '{print $2 "." $3}') 
                    else   #si tiene whois
                      #IP $(echo $tdominio)
                      Domain=$(echo $tdominio) 
                    fi

                 fi

             fi



       else  #Los cuatro campos No tienen una Ip asociada


     tdominio=$(echo $dom | cut -f3 -d '/' | rev | awk -F '.' '{print $1 "." $2 "." $3}' | rev)

           if [[ 2 -le $(echo $tdominio | cut -f1 -d '.' | grep -Eo '[w]' | wc -l) ]] #it has the words www
           then
             IP $(echo $tdominio)
             Domain=$(echo $tdominio | awk -F '.' '{print $2 "." $3}') 
           else  #it doesn't has the words www

             if [[ -z $(dig +short $tdominio +noall +answer) ]] #it doesn't have a IP
             then

               if  [[ -n $( response $tdominio | grep -i "no match\|no entries found\|No whois server is known\|nameserver not found\|not found" ) ]] #it doesn't have a domain record
               then
                 IP  $(echo $tdominio | awk -F '.' '{print $2 "." $3}')
                 Domain=$(echo $tdominio | awk -F '.' '{print $2 "." $3}') 
               else   #it has a domain record
                 IP $(echo $tdominio)
                 Domain=$(echo $tdominio) 
               fi

             else # si tiene IP

                if [[ -n $( response $tdominio | grep -i "no match \|no entries found\|No whois server is known\|nameserver not found\|not found"  ) ]]  #si no tiene whois
                then
                 IP $(echo $tdominio)
                 Domain=$(echo $tdominio | awk -F '.' '{print $2 "." $3}') 
                else   #si tiene whois
                 IP $(echo $tdominio)
                 Domain=$(echo $tdominio) 
                 fi

             fi

          fi




      fi


   else  #tres espacios
 tdominio=$(echo $dom | cut -f3 -d '/' | rev | awk -F '.' '{print $1 "." $2 "." $3}' | rev)

     if [[ 2 -le $(echo $tdominio | cut -f1 -d '.' | grep -Eo '[w]' | wc -l) ]] #it has the words www
     then
       IP $(echo $tdominio)
       Domain=$(echo $tdominio | awk -F '.' '{print $2 "." $3}') 
     else  #it doesn't has the words www

        if [[ -z $(dig +short $tdominio +noall +answer) ]] #it doesn't have a IP
        then

           if  [[ -n $( response $tdominio | grep -i "no match \|no entries found\|No whois server is known\|nameserver not found\|not found" ) ]] #it doesn't have a domain record
           then
            IP  $(echo $tdominio | awk -F '.' '{print $2 "." $3}')
            Domain=$(echo $tdominio | awk -F '.' '{print $2 "." $3}') 
           else   #it has a domain record
            IP $(echo $tdominio)
            Domain=$(echo $tdominio) 
           fi

        else # si tiene IP

           if [[ -n $( response $tdominio | grep -i "no match \|no entries found\|No whois server is known\|nameserver not found\|not found" ) ]]  #si no tiene whois
           then
            IP $(echo $tdominio)
            Domain=$(echo $tdominio | awk -F '.' '{print $2 "." $3}') 
           else   #si tiene whois
            IP $(echo $tdominio)
            Domain=$(echo $tdominio) 
           fi

       fi

     fi


  fi



fi

echo -e "$title Domain name:$back $Domain"


rm -f temp3.txt
rm -f temp1.txt




