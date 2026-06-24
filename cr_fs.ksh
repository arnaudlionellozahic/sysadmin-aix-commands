#!/bin/ksh
# Script d'aide a la creation de FS
#
# P. riou
# 
#Modif du 13/11/06 correction du vgs en LINUX30 qui n existe pas, pas de prise en compte des lignes blanche dans le fichier param
#Modif du 30/01/07 lsvg -o a la place de lsvg pour avoir la liste des vg presents (evite un plantage dans le calcul de 'espace libre sur le vg)
#Modif du 30/01/07 fs par defaut = jfs2 sur les nouveaux vg en AIX 5.3
#Modif du 12/02/07 correction d'un bug sous Linux pour la selection du vg_apps
#Modif du 30/04/07 petit bug sur la recuperation de la taille libre sur un VG AIX (Merci Lylian)
#Modif du 02/05/07 petit bug sur le test de presence du vg_apps en LINUX4 (Merci Gabriel)
#Modif du 21/01/08 prise en compte du nombre de LV a creer par rapport au MAX_LV sur HP-UX 
#Modif du 21/02/08 prise en compte de AIX 6.1
#Modif du 02/06/08 Ajout d install silencieuse sur vg passe en param
#Modif du 19/06/08 Correction d'un bug si le vg passe en parametre ne dispose pas d'assez de place (Merci Pascal)
#Modif du 11/08/08 Verification qu'il y a assez de place sur chaque disque du VGdans le cas d'un mirroir sur des disques non symmetriques (Merci Oliv)
#Modif du 22/10/08 Rectification de la creation des FS sous LINUX pour eviter de limiter le nombre d'inodes mke2fs -i 1024 (desole Sylvain)
#Modif du 20/11/08 Correction dans la verif des disques en cas de vg non mirrore( Merci Marc)
#Modif du 14/01/09 Correction pour que le FS par defaut sur AIX 6.1 sous du JFS2 ( Merci Guillaume)
#Modif du 13/03/09 Prise en compte de 11iv3

clear
echo "****************************"
echo "* Script de creation de FS *"
echo "****************************"

# Verification du VG passe en argument
function vg_controle
{
	# Scan du nom passe en parametre pour voir s'il est dans la liste des VG
	l=1
	# liste de tous les VG retenus
	while [ ${l} -lt ${j} ]
	do
		if [ ${VG_USE[${l}]} = "OUI" ]
		then
			# le VG est utilisable
			# Verification s'il match le parametre passe au script
			TROUVE=$(echo ${VG_NOM[${l}]} | grep -c	$1)
			if [ ${TROUVE} -ne 0 ]
			then
				CHOIX=${l}
				return
			fi
		else
			# le VG ne dispose pas de place suffisante
			# Verification s'il match le parametre passe au script
			TROUVE=$(echo ${VG_NOM[${l}]} | grep -c	$1)
			if [ ${TROUVE} -ne 0 ]
			then
				return 1
			fi			
		fi
		(( l = ${l} + 1 ))
	done
	CHOIX=${l}
}

# En cas de mirroir on verifie qu'il y a assez de place sur chaque disque 
# pour faire le mirroir (utile si les PV ne sont pas symetriques)
function cntrl_unitaire_vg
{
PS4='$LINENO : '
#set -x	
	#Param1 = nomVG
	#Param2 = Espace requis

	# recuperation du nom des disques et de l espace libre
	case ${OS} in
		AIX)
			# Recuperation de la taille des PP
			PP_TAILLE=$(lsvg $1 | awk '/PP SIZE:/ { print $6 }')
			LE_PV_TOT=0;LE_PV_BAD=0
			# Recuperation d'un tableau Nom_PV:taille_Libre
			LES_PV=$(lsvg -p $1 | awk -v unit=${PP_TAILLE} 'NR > 2 { print $1":"$4*unit }')
		;;
		HP-UX)
			LES_PV=$(vgdisplay -v $1 | awk 'BEGIN { top=0;nb_dsk=0 }
/PE Size/ { coef=$4 }
/PV Name/ { top=1 }
NF == 0 { top=0 }
{ if ( top == 1 && $2 == "Name" ) { nb_dsk=nb_dsk+1;nom_dsk[nb_dsk]=$3} }
{ if ( top == 1 && $1 == "Free" ) { lib_dsk[nb_dsk]=$3} }
END { for (i = 1; i<= nb_dsk; i=i+1 ) { print nom_dsk[i]":"lib_dsk[i]*coef }}')

		;;
		*)
			echo "Choix d'OS improbable"
		;;
	esac
	
	# Traitement des PV
	LE_PV_BAD=0
	for LE_PV in ${LES_PV}
	do
		((LE_PV_TOT=${LE_PV_TOT}+1))
		if (( $2 > $(echo ${LE_PV} | cut -f2 -d':') ))
		then
			echo "Pas assez de place sur $( echo ${LE_PV} | cut -f1 -d':') de $1"	
			((LE_PV_BAD=${LE_PV_BAD}+1))
		fi
	done
#set +x 

	# Verification qu'on a au moins 2 PV eligibles
	if (( ${LE_PV_TOT} > 1 ))
	then
		# plus d'un disk dans le vg verif si on en a 2 pour le mirror
		if (( $(( ${LE_PV_TOT} - ${LE_PV_BAD})) < 2 ))
		then
#				echo "Pas assez de place sur chaque PV"
			return 1
		else
			return 0
		fi
	fi			
}

# Test de l'utilisateur
if (( $(id -u) != 0 ))
then
	echo "You Have 2 be root !"
	exit 1
fi

# Test de la version de l'OS
OS=$(uname)
case ${OS} in
	AIX) VERSION=$(oslevel|cut -f1-2 -d'.')
		if [[ ${VERSION} != 5.1 && ${VERSION} != 5.2 && ${VERSION} != 5.3 && ${VERSION} != 6.1 ]]
		then
			echo "Cette version (${VERSION}) n'est pas supporte"
			exit 1
		fi
	;;
	HP-UX) VERSION=$(uname -r)
		if [[ ${VERSION} != B.11.00 && ${VERSION} != B.11.11 && ${VERSION} != B.11.23 && ${VERSION} != B.11.31 ]]
		then
			echo "Cette version (${VERSION}) n'est pas supporte"
			exit 1
		fi
	;;
	Linux) VERSION=$(uname -r |cut -f1-2 -d'.')
		if [[ ${VERSION} != 2.4 && ${VERSION} != 2.6 ]]
		then
			echo "Cette version (${VERSION}) n'est pas supporte"
			exit 1
		fi
	;;
	*) echo "Cet OS (${OS}) n'est pas supporte"
		exit 1
	;;
esac

# Recuperation du nom du VG si celui ci est passi en premier parametre
if [ $# -eq 1 ]
then
	CH_NOM_VG=$1
	echo 
	echo "Installation sur VG choisi =========> ${CH_NOM_VG}"
else
	CH_NOM_VG="....."
fi

# Test de la presence du fichier parametre
if [[ ! -f cr_fs.parm ]]
then
	echo 
	echo "Le fichier parametre (cr_fs.parm) est absent" >&2
	exit 1
fi

# Chargement des FS a creer
echo
echo "Preparation des FS suivants :"
echo
i=1;TOT=0
grep -v -E "#|^ *$" cr_fs.parm >/tmp/cr_fs.tmp
while read line
do
	FS[${i}]=$(echo ${line} | cut -f1 -d":")
	MT[${i}]=$(echo ${line} | cut -f2 -d":")
	TA[${i}]=$(echo ${line} | cut -f3 -d":")

	(( TOT=${TOT}+${TA[${i}]} ))
	echo "${MT[${i}]}\t\t${TA[${i}]} Mo"
	(( i = i + 1))
done  < /tmp/cr_fs.tmp
rm /tmp/cr_fs.tmp

NB_LV_A_CREER=$(( ${i} - 1 ))
echo "TOTAL ... \t\t${TOT} Mo"

# Verification de la place requise sur un VG

case ${OS} in
	AIX)
		LISTE_VG_COMPLETE=$(lsvg -o)
		# Verification des VG utilises par HACMP
		if [[ -x /usr/es/sbin/cluster/utilities/cllsres ]]
		then
			LISTE_VG_HACMP=$(/usr/es/sbin/cluster/utilities/cllsres | grep "VOLUME_GROUP" | cut -f2 -d"=" | tr -s '"' ' ')
			LIST_VG_LOCAUX=""
			for VG in ${LISTE_VG_COMPLETE}
			do
				if ! echo ${LISTE_VG_HACMP} | grep -q ${VG}
				then
					LISTE_VG_LOCAUX=${LISTE_VG_LOCAUX}" "${VG}
				fi
			done
		else
			LISTE_VG_LOCAUX=${LISTE_VG_COMPLETE}
		fi
		# Verification si les VG locaux sont mirrores ou pas
		# et evaluation de l'espace restant sur le VG (/2 si mirrore)
		echo 
		echo "Liste des VG locaux :"
		echo
		echo "No   NOM\tTAILLE"
		typeset -2R j=1
		for VG in ${LISTE_VG_LOCAUX}
		do
			VG_NOM[${j}]=${VG}
			VG_MIR[${j}]=$(lsvg -l ${VG} | awk 'BEGIN {MIR="NON"} NR > 2 { if (($3*2) == $4) {MIR="OUI"} }	END {print MIR }')

			if [[ ${VG_MIR[${j}]} = NON ]]
			then
				# Recuperation de la l'espace Libre en Mo
				VG_LIB[${j}]=$(lsvg ${VG} | awk '/FREE PPs:/ {split($7,a,"(");print a[2]}')
			else
				VG_LIB[${j}]=$(lsvg ${VG} | awk '/FREE PPs:/ {split($7,a,"(");print a[2]/2}')
			fi	
			if (( ${VG_LIB[${j}]} < ${TOT} ))
			then
				echo "   - ${VG_NOM[${j}]}\t${VG_LIB[${j}]} *** ESPACE INSUFFISANT ***"
				VG_USE[${j}]="NON"
			elif [[ ${VG_MIR[${j}]} = "OUI" ]]
			then
				cntrl_unitaire_vg ${VG_NOM[${j}]}  ${TOT}
				if (( $? == 0 ))
				then
					echo "${j} - ${VG_NOM[${j}]}\t${VG_LIB[${j}]}"
					VG_USE[${j}]="OUI"
				else
					echo "   - ${VG_NOM[${j}]}\t${VG_LIB[${j}]} **** ESPACE INSUFFISANT ****"
					VG_USE[${j}]="NON"
				fi
			else
				echo "${j} - ${VG_NOM[${j}]}\t${VG_LIB[${j}]}"
				VG_USE[${j}]="OUI"
			fi
			(( j = ${j} + 1 ))
		done	
		echo 
	;;
	HP-UX)
		LISTE_VG_COMPLETE=$(vgdisplay | grep -i 'VG NAME' | awk '{ print $3}')
		# Verification des VG utilises par MCSG
		LISTE_VG_LOCAUX=""
		for VG  in ${LISTE_VG_COMPLETE}
		do
			if (( $(vgdisplay ${VG} | grep -i 'VG STATUS' | grep -c exclusive) == 0 ))
			then
				LISTE_VG_LOCAUX="${VG} ${LISTE_VG_LOCAUX}"
			fi
		done	
		# Verification si les VG locaux sont mirrores ou pas
		# et evaluation de l'espace restant sur le VG (/2 si mirrore)
		echo 
		echo "Liste des VG locaux :"
		echo
		echo "No   NOM\tTAILLE"
		typeset -2R j=1
		for VG in ${LISTE_VG_LOCAUX}
		do
			VG_NOM[${j}]=${VG}
			VG_MIR[${j}]=$(vgdisplay -v ${VG} | awk ' BEGIN {MIR="NON"}
			/Current LE/ { CUR=$3 }
			/Allocated PE/ { if ( $3 == (2*CUR) ) {MIR="OUI"}}
			END { print MIR }')

			# Recuperation de la l'espace Libre en Mo
			VG_LIB[${j}]=$(vgdisplay ${VG} |awk -v MIR=${VG_MIR[${j}]} ' /PE Size/ { TAILLE=$4 }
/Free PE/ { if ( MIR == "OUI") { LIBRE=($3*TAILLE)/2 } else { LIBRE=($3*TAILLE)}
 print LIBRE }'	)
			if (( ${VG_LIB[${j}]} < ${TOT} ))
			then
				echo "   - ${VG_NOM[${j}]}\t${VG_LIB[${j}]} *** ESPACE INSUFFISANT ***"
				VG_USE[${j}]="NON"
			else
				# Controle du nombre de LV dans le VG
				MAX_LV=$(vgdisplay ${VG_NOM[${j}]} | awk '/Max LV/ { print $3 }')
				CUR_LV=$(vgdisplay ${VG_NOM[${j}]} | awk '/Cur LV/ { print $3 }')
				if (( $((${CUR_LV} + ${NB_LV_A_CREER})) > ${MAX_LV} ))
				then
					echo "- ${VG_NOM[${j}]}\t${VG_LIB[${j}]} *** Trop de LV sur ce VG (${CUR_LV}/${MAX_LV}) ***"
				else
					# Verif place sur chaque PV
					if [[ ${VG_MIR[${j}]} = "OUI" ]]
					then
						cntrl_unitaire_vg ${VG_NOM[${j}]}  ${TOT}
						if (( $? == 0 ))
						then
							echo "${j} - ${VG_NOM[${j}]}\t${VG_LIB[${j}]}"
							VG_USE[${j}]="OUI"
						else
							echo "   - ${VG_NOM[${j}]}\t${VG_LIB[${j}]} *** ESPACE INSUFFISANT ***"
							VG_USE[${j}]="NON"
						fi
					else
						echo "${j} - ${VG_NOM[${j}]}\t${VG_LIB[${j}]}"
						VG_USE[${j}]="OUI"
					fi
				fi
			fi
			(( j = ${j} + 1 ))
		done	
				
	;;
	Linux)
		LISTE_VG_COMPLETE=$(vgdisplay | grep -i 'VG NAME' | awk '{ print $3}')
		# Verification des VG non utilises par MCSG
		LISTE_VG_LOCAUX=""
		for VG  in ${LISTE_VG_COMPLETE}
		do
			if (( $(grep -c ${VG} /etc/fstab) > 0 ))
			then
				LISTE_VG_LOCAUX="${VG} ${LISTE_VG_LOCAUX}"
			fi
				
		done

		# Verification de la presence de vg_apps dans la liste des VG Locaux
		if (( $(echo ${LISTE_VG_LOCAUX} |grep -c vg_apps) == 0 ))
		then
			if (( $(vgdisplay vg_apps 2>/dev/null | grep -c 'VG Name' ) == 1 ))
			then
				LISTE_VG_LOCAUX="${LISTE_VG_LOCAUX} vg_apps"
			fi
		fi
			

		# Pas de mirroring soft sous Linux les LV sont donc tous
		# note comme non mirrores
		echo 
		echo "Liste des VG locaux :"
		echo
		echo "No   NOM\tTAILLE"
		typeset -R2 j=1
		for VG in ${LISTE_VG_LOCAUX}
		do
			VG_NOM[${j}]=${VG}

			# Recuperation de la l'espace Libre en Mo
			if [[ ${VERSION} != "2.4" ]]
			then
			# Sous Linux40 on utilise vgs
			VG_LIB[${j}]=$(vgs -o vg_free ${VG_NOM[${j}]} |tail -1 | awk '{ taille=length($1)
			unite=substr($1,taille)
			valeur=substr($1,1,(taille - 1) )
			if (( unite == "M" )) { print int(valeur) }
			if (( unite == "G" )) { print int(valeur*1024) }
			if (( unite == "T" )) { print int(valeur*1048576) }
			}')
			else
			# Sous LINUX30 on utilise vgdisplay (vgs n existe pas)
			VG_LIB[${j}]=$(vgdisplay ${VG_NOM[${j}]} | awk '/Free  PE / {			if (( $8 == "MB" )) { print int($7) }
			if (( $8 == "GB" )) { print int($7*1024) }
			if (( $8 == "TB" )) { print int($7*1048576) }
			}')
			fi

			if (( ${VG_LIB[${j}]} < ${TOT} ))
			then
				echo "   - ${VG_NOM[${j}]}\t${VG_LIB[${j}]} *** ESPACE INSUFFISANT ***"
				VG_USE[${j}]="NON"
			else
				echo "${j} - ${VG_NOM[${j}]}\t${VG_LIB[${j}]}"
				VG_USE[${j}]="OUI"
			fi
			(( j = ${j} + 1 ))
		done	
				
	;;
esac

echo " 0 - Quitter le script"

# Choix du VG et creation LV/FS ou sortie
typeset -i CHOIX=0
echo

#Choix du VG si ce dernier n'a pas ete passe en argument
if [[ ${CH_NOM_VG} = "....." ]]
then
	echo "Donner le numero du VG a utiliser : \c"
	read CHOIX
else
	echo "VG passe en argument : ${CH_NOM_VG}"
	vg_controle ${CH_NOM_VG}
	if [ $? -ne 0 ]
	then
		echo "Error: le VG indique en argument ne dispose pas de place suffisante"
		return 10
	fi
fi

if [[ ${VG_USE[${CHOIX}]} = "OUI" ]]
then
case ${OS} in
	AIX)
		echo "Creation des LV sur ${VG_NOM[${CHOIX}]}"
		# Type de FS a creer
		if (( $(lsvg -l ${VG_NOM[${CHOIX}]} | grep -c jfs2log) > 0 ))
		then
			# S'il y a du jfs2log dans le VG on part sur du jfs2
			FS_TYPE=jfs2
		else
			# S'il n'y a pas de jsf2log c'est qu'il y a du jfs ou rien
			if (( $(lsvg -l ${VG_NOM[${CHOIX}]} | grep -c jfslog) > 0 ))
			then
				#Il y a du jfslog
				FS_TYPE=jfs
			else
				#Il y a rien
				if [[ ${VERSION} = 5.3 || ${VERSION} = 6.1 ]]
				then
					# si on est en 5.3 jfs2
					FS_TYPE=jfs2
				else
					# sinon jfs
					FS_TYPE=jfs
				fi
			fi
		fi
		k=1
		while (( ${k} < ${i} ))
		do
			mklv -y ${FS[${k}]} -t ${FS_TYPE} ${VG_NOM[${CHOIX}]} ${TA[${k}]}M
			(( k = k + 1 ))
		done	

		if [[ ${VG_MIR[${CHOIX}]} = "OUI" ]]
		then
			echo "Mirroring des LV"
			k=1
			while (( ${k} < ${i} ))
			do
				echo " --> ${FS[${k}]}"
				/usr/sbin/mklvcopy ${FS[${k}]} 2
				(( k = k + 1 ))
			done	
		fi

		# creation des FS sur les LV
		k=1
		while (( ${k} < ${i} ))
		do
			/usr/sbin/crfs -v ${FS_TYPE} -d ${FS[${k}]} -m ${MT[${k}]} -A yes
			mount ${MT[${k}]}
			(( k = k + 1 ))
		done	
	;;
	HP-UX)
                echo "Creation des LV sur ${VG_NOM[${CHOIX}]}"
                k=1
                while (( ${k} < ${i} ))
                do
                lvcreate -L ${TA[${k}]} -n ${FS[${k}]} ${VG_NOM[${CHOIX}]}
                        (( k = k + 1 ))
                done

                if [[ ${VG_MIR[${CHOIX}]} = "OUI" ]]
                then
                        echo "Mirroring des LV"
                        k=1
                        while (( ${k} < ${i} ))
                        do
                                lvextend -m 1 ${VG_NOM[${CHOIX}]}/${FS[${k}]}
                                (( k = k + 1 ))
                        done
                fi

                echo "Creation des FS "
                k=1
                while (( ${k} < ${i} ))
                do
                        echo " --> ${FS[${k}]}"
                        newfs -F vxfs ${VG_NOM[${CHOIX}]}/r${FS[${k}]}
                        mkdir -p ${MT[${k}]}

			echo "${VG_NOM[${CHOIX}]}/${FS[${k}]} ${MT[${k}]} vxfs delaylog 0 2" >>/etc/fstab
			mount ${MT[${k}]}
                        (( k = k + 1 ))
                done
	;;
	Linux)
                echo "Creation des LV sur ${VG_NOM[${CHOIX}]}"
                k=1
                while (( ${k} < ${i} ))
                do
                lvcreate -L ${TA[${k}]} -n ${FS[${k}]} ${VG_NOM[${CHOIX}]}
                        (( k = k + 1 ))
                done

                echo "Creation des FS "
                k=1
                while (( ${k} < ${i} ))
                do
                        echo " --> ${FS[${k}]}"
			mke2fs -O has_journal -j /dev/${VG_NOM[${CHOIX}]}/${FS[${k}]}
                        mkdir -p ${MT[${k}]}

			echo "/dev/${VG_NOM[${CHOIX}]}/${FS[${k}]} ${MT[${k}]} ext3 defaults 1 2" >>/etc/fstab
			mount ${MT[${k}]}
                        (( k = k + 1 ))
                done
	;;
	esac
else

	if (( ${CHOIX} != 0 ))
	then
		echo "Ce VG ne peut etre selectionne " >&2
	else
		echo "Abandon utilisateur " >&2
	fi
	exit 1
fi
