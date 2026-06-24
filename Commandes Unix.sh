### Exemples commandes :

find . -type f -exec du -sg {} \; |grep -v ^0, |sort -nr |head -15

### User Atlas

cdt ==> repertoire transfer
cdi ==> repertoire imp
cdi-0 ==> imp -1 
cdtn ==> repertoire tng
cdf ==> repertoire fic

### User root

sesu -

### Robot (User root)

	#	Atlas	#

dsmc q ar -se=TSM-ARZ105 -virtualnodename=parva4006680 -password=parva4006680 "/ficsav/parva4001843/apres/*atpr01*150609*"	
	
dsmc q ar -se=TSM-ARZ105 -virtualnodename=parva4006680 -password=parva4006680 "/ficsav/parva4001843/apres/*ENV*150609*"

dsmc q ar -se=TSM-ARZ105 -virtualnodename=parva4006680 -password=parva4006680 "/ficsav/parva4001843/apres/*FIC*150609*"

	#	Infocentre #

dsmc q ar -se=TSM-ARZ105 "/apps/oracle/backup/IAM1ANP0/db_IAM1ANP0_hot_20150614*"

dsmc ret -se=TSM-ARZ105 -pi "/apps/oracle/backup/IAM1ANP0/db_IAM1ANP0_hot_20150614*" /ficsav/EQUIPE_MEO/backup/glen/ 

dsmc ret -se=TSM-ARZ105 -pi "/apps/oracle/backup/IAM1ANP0/db_IAM1ANP0_hot_20150614_FULL_s5647_p*" /ficsav/EQUIPE_MEO/backup/glen/

dsmc q ar -se=TSM-ARZ105 "/apps/antill/ficsav/rep_infocanti_20062015.tgz"

dsmc q ar -se=TSM-ARZ105 "/apps/antill/ficsav/rep_infocdranti_04062015.tgz"

### Liste, Grandissement/Reduction FS LV VG

df -gI .

lsfs /apps/oracledata/IAM1DZI0/indx0001

lslv lvIAM1DZIi0001

lsvg vg_data2

lsvg -l vg_data | grep jfs2 | awk '{ print $NF }' | xargs df -gI

lsvg -l vg_data |grep jfs2 |awk '$NF ~ "^/" {print $NF}' | xargs df -gI |awk '$1 ~ "^/" {printf "%-30s %+7s %+7s %+7s %+4s %-50s \n" , $1, $2, $3, $4, $5, $6 }' |sort -krn4

chfs -a size=-1G /apps/oracledata/IAM1DZI0/indx0001

chfs -a size=+1G /apps/oracledata/IAM1DZI0/indx0001

chlv -x 20480 lvIAM1DZId0001

### Création FS, LV

mklv -y lv_atpsa1 -t jfs2 -x 4096 extvgda 38G

crfs -v jfs2 -d lv_atpsa1 -m /apps/oradbf/atpsa1 -A yes -p rw -t no

mount /apps/oradbf/atpsa1

### Suppression FS, LV

fuser -c /apps/oradbf/atpsa2

umount /apps/oradbf/atpsa2

rmfs -r /apps/oradbf/atpsa2 (supprime le LV associé)

### Tar Détar

gtar xvzf /ficsav/EQUIPE_MEO/glen/apres/FIC1.428Go.20150702.044601.tar.Z --exclude=*.tar* --exclude=*.Z* --exclude=*SAV* --exclude=*sav* --exclude=*.tgz*

gtar -xzvf IMP.20150613.042022.tar.Z *MRSP*

### Restauration Atlas 
	# Se connecter à l'environnement Atlas

kixok

kixstop

cd /apps/meoatlas2/outils
ls -lrt *clonage*

./clonage.sh

Entrer la base Cible: atpr14
Entrer Le chemin complet de l'archive de la base: /ficsav/EQUIPE_MEO/glen/PARDEM001679529/apres/atpr01.245Go.20150609.024850.tgz

Voulez-vous mettre a jour le fichier de control ? (o/n):
n

 ***TOUS LES PRE-REQUIS SONT OK***


Validez-vous la copie de [atpr01.245Go.20150609.024850.tgz] ==> [uf14 - atpr14] (o/n):
o

