#!/usr/bin/ksh
# Script d'aide a la creation de users
# 
# 
clear
echo "******************************"
echo "* Script de creation de user *"
echo "******************************"

FIC_PARAM=./cr_user.parm

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
		if [[ ${VERSION} != B.11.00 && ${VERSION} != B.11.11 && ${VERSION} != B.11.23 ]]
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

# Test de la presence du fichier parametre
if [[ ! -f ${FIC_PARAM} ]]
then
	echo 
	echo "Le fichier parametre ${FIC_PARAM} est absent" >&2
	exit 1
fi

# Chargement des users a creer
echo
echo "Preparation des users suivants :"
echo
i=1
grep -v -E "#|^ *$" ${FIC_PARAM} >/tmp/cr_user.tmp
while read line
do

	LOG[${i}]=$(echo ${line} | cut -f1 -d":")
	UID[${i}]=$(echo ${line} | cut -f2 -d":")
	GID[${i}]=$(echo ${line} | cut -f3 -d":")
	COM[${i}]=$(echo ${line} | cut -f4 -d":")
	DIR[${i}]=$(echo ${line} | cut -f5 -d":")
	if [[ -z ${DIR[${i}]} ]]
	then
		DIR[${i}]="/home/${LOG[${i}]}"
	fi
	SHE[${i}]=$(echo ${line} | cut -f6 -d":")
	(( i = i + 1))

done  < /tmp/cr_user.tmp
rm /tmp/cr_user.tmp

j=1
while (( ${j} < ${i} ))
do
	echo "${LOG[${j}]} : \c"
	
	# Check de l'unicite du logname
	if (( $(grep -c "^${LOG[${j}]}:" /etc/passwd) != 0 ))
	then
		echo "Utilisateur deja present dans le fichier passwd"
		(( j = j + 1 ))
		continue
	fi
	# Check de l'unicite de l'UID
	if (( $(cut -f3 -d":" /etc/passwd | grep -c "^${UID[${j}]}$" ) != 0 ))
	then
		echo "L'UID (${UID[${j}]}) est deja preset dans le fichier passwd"
		(( j = j + 1 ))
		continue
	fi
	
	# Lancement de la commande useradd
	useradd -c "${COM[${j}]}" -d "${DIR[${j}]}" -g "${GID[${j}]}" -u "${UID[${j}]}" -s "${SHE[${j}]}" ${LOG[${j}]}

	if (( $? == 0 ))
	then
		echo " OK !"
	else
		echo " Failed !"
		(( j = j + 1 ))
		continue
	fi

	# Creation de la homedir si besoin
	if [[ ! -d ${DIR[${j}]} ]]
	then
		mkdir -p ${DIR[${j}]}
		chown ${UID[${j}]}:${GID[${j}]} ${DIR[${j}]} 
		chmod 755 ${DIR[${j}]} 
	fi	

	# Clear les flags du user sur AIX
	if [[ -x /usr/bin/pwdadm ]]
	then
		/usr/bin/pwdadm -c ${LOG[${j}]}
	fi

	(( j = j + 1 ))
done
