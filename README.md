Hello, I've put the work of my AIX's years in this repo


# Diagnostic Configuration LPAR
    lparstat -i <= vue hyperviseur
    bindprocessor -q <= vue OS, donc hyperthreading, SMT sous AIX
The available processors are: 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15

# Lister les erreurs réseau
    errpt | grep LINK | head | while read a b c d e f g; do echo "$b $e"; done

# Lister les WWN
    for i in 0 1 2 3; do lscfg -vl fcs$i | grep -i net; done | awk -F'.' '{print $NF}'
    lsdev -dev fcs1 -vpd | awk -F'.' ' $1 ~ /Network Address/ {gsub(".", "& ") ; split($NF, a, " ") ; print( a[1] a[2] ":" a[3] a[4] ":" a[5] a[6] ":" a[7] a[8] ":" a[9] a[10] ":" a[11] a[12] ":" a[13] a[14] ":" a[15] a[16])}'

# Monitoring
    svmon -P -O sortentity=inuse |head
    iostat -aDl
    vmstat -v

# LVM
```
#lsvg -o | lsvg -l -i
rtbckvg:
LV NAME             TYPE       LPs     PPs     PVs  LV STATE      MOUNT POINT
rtbcklv             jfs2       6118    6118    2    open/syncd    /backup/QT1
bwbckvg:
LV NAME             TYPE       LPs     PPs     PVs  LV STATE      MOUNT POINT
bwbcklv             jfs2       5081    5081    2    open/syncd    /backup/QWH
brbckvg:
LV NAME             TYPE       LPs     PPs     PVs  LV STATE      MOUNT POINT
brbcklv             jfs2       2047    2047    1    open/syncd    /backup/QT2
rootvg:
LV NAME             TYPE       LPs     PPs     PVs  LV STATE      MOUNT POINT
hd5                 boot       1       1       1    closed/syncd  N/A
hd6                 paging     40      40      1    open/syncd    N/A
hd8                 jfs2log    1       1       1    open/syncd    N/A
hd4                 jfs2       16      16      1    open/syncd    /
hd2                 jfs2       16      16      1    open/syncd    /usr
hd9var              jfs2       16      16      1    open/syncd    /var
hd3                 jfs2       16      16      1    open/syncd    /tmp
hd1                 jfs2       1       1       1    open/syncd    /home
hd10opt             jfs2       8       8       1    open/syncd    /opt
lg_dumplv           sysdump    10      10      1    open/syncd    N/A
hd11admin           jfs2       1       1       1    open/syncd    /admin
livedump            jfs2       1       1       1    open/syncd    /var/adm/ras/livedump
```

# Création d'un serveur NIM sans NIM existant :
prise d'un image.data et un bosinst.data dans / (pris depuis un extrait de mksysb => recstore xvf)
liste des phyiscal partitions
    lslv -m
LPS = 1 Logivcal Partition,
COPIES=3 : 3 physical partitions (PP=2)

Besoin dan sun serveur NIM
* un LPP (TL9SP4, etc puis un spot associé) => packages
* un spot => un mini OS de boot
```
[root@admna2nim51 ~]# lsnim -t lpp_source
lpp_aix61_tl9sp4 resources lpp_source
lpp_aix61_tl8sp2 resources lpp_source
lpp_aix61_tl8sp1 resources lpp_source
lpp_zabbix resources lpp_source

[root@admna2nim51 ~]# lsnim -l lpp_aix61_tl9sp4
lpp_aix61_tl9sp4:
class = resources
type = lpp_source
arch = power
Rstate = ready for use
prev_state = unavailable for use
location = /export/lpp_source/lpp_aix61_tl9sp4
simages = yes    <= le spot pourra être bootable
alloc_count = 0
server = master

[root@admna2nim51 ~]# lsnim -l spot_aix61_tl9sp4
spot_aix61_tl9sp4:
class = resources
type = spot
plat_defined = chrp
arch = power
bos_license = yes
Rstate = ready for use
prev_state = verification is being performed
location = /export/spot/spot_aix61_tl9sp4/usr
version = 6
release = 1
mod = 9
oslevel_r = 6100-09
alloc_count = 0
server = master  <= haute dispo du NIM, globalement toujours MASTER maintenant
if_supported = chrp.64 ent
Rstate_result = success
```
Vue des bundles :
```
[root@admna2nim51 ~]# lsnim -l puppet
puppet:
class = resources
type = installp_bundle
Rstate = ready for use
prev_state = unavailable for use
location = /export/bundles/puppet.bnd
alloc_count = 0
server = master
[root@admna2nim51 ~]# cat /export/bundles/puppet.bnd
R:libgcc
R:db
R:pup-zlib
R:pup-openssl
R:pup-ruby
R:pup-facter
R:pup-puppet
R:ruby
R:rubygem-stomp
R:facter
R:mcollective-common
R:mcollective
R:mcollective-plugins-facter_facts
R:rubygem-inifile
R:kermit-mqsend
R:rubygem-stomp
R:rubygem-tzinfo
R:rubygem-uuidtools
R:rubygem-daemons
R:rubygem-rufus-scheduler
```
Vue des ifix (généralement, mise à jour de lpp_source recopié avec un ifix)

Ressource de type network, image_data, ...
```
[root@admna2nim51 ~]# lsnim -l image_data
image_data:
class = resources
type = image_data
Rstate = ready for use
prev_state = unavailable for use
location = /export/lpp_source/image.data
alloc_count = 0
server = master
```
On trouve un fichier .toc  par lpp_source
```
inutoc .    <= "createrepo RPM"
```
Le .toc à reconstruire en cas d'ajout d'un ifix ou bundle dans le lpp_source
```
lsnim -l admna2nim51 (depuis le 30)
lsnim -a info
```

# Console depuis la HMC
    vtmenu
pour en sortir ~.
echo $PATH, ls pour voir les commandes

# Lister les lpar depuis la HMC
    lssyscfg -m <chassis> -r lpar --filter lpar_names=<hostname> -F state

# Mises à jour AIX
cat /etc/niminfo : connaître le serveur NIM
```
+-----------------------------------------------------------------------------+
Bootlist Processing
+-----------------------------------------------------------------------------+
Verifying operation parameters ...
Setting bootlist to logical volume bos_hd5 on hdisk5.
ATTENTION: firmware recovery string for standby BLV (bos_hd5):
boot /vdevice/vfc-client@30000002/disk@50060e8015333978:4
ATTENTION: firmware recovery string for standby BLV (bos_hd5):
boot /vdevice/vfc-client@30000002/disk@50060e801533390b:4
ATTENTION: firmware recovery string for standby BLV (bos_hd5):
boot /vdevice/vfc-client@30000004/disk@50060e801533391b:4
ATTENTION: firmware recovery string for standby BLV (bos_hd5):
boot /vdevice/vfc-client@30000004/disk@50060e8015333968:4
ATTENTION: firmware recovery string for standby BLV (bos_hd5):
boot /vdevice/vfc-client@30000004/disk@50060e8015333922:4

Log file is /etc/multibos/logs/op.alog
Return Status = SUCCESS
You have mail in /usr/spool/mail/root

[root@dexcz2odb02 ~]# lsvg -l rootvg
rootvg:
LV NAME             TYPE       LPs     PPs     PVs  LV STATE      MOUNT POINT
hd5                 boot       1       1       1    closed/syncd  N/A
hd6                 paging     64      64      1    open/syncd    N/A
hd8                 jfs2log    1       1       1    open/syncd    N/A
hd4                 jfs2       8       8       1    open/syncd    /
hd2                 jfs2       40      40      1    open/syncd    /usr
hd9var              jfs2       40      40      1    open/syncd    /var
hd3                 jfs2       24      24      1    open/syncd    /tmp
hd1                 jfs2       16      16      1    open/syncd    /home
hd10opt             jfs2       70      70      1    open/syncd    /opt
hd11admin           jfs2       1       1       1    open/syncd    /admin
lg_dumplv           sysdump    16      16      1    open/syncd    N/A
livedump            jfs2       2       2       1    open/syncd    /var/adm/ras/livedump
orabinlv            jfs2       240     240     1    open/syncd    /u01/app
bos_hd5             boot       1       1       1    closed/syncd  N/A
bos_hd4             jfs2       8       8       1    closed/syncd  /bos_inst
bos_hd2             jfs2       40      40      1    closed/syncd  /bos_inst/usr
bos_hd9var          jfs2       40      40      1    closed/syncd  /bos_inst/var
bos_hd10opt         jfs2       70      70      1    closed/syncd  /bos_inst/opt

# oslevel -s
6100-09-04-1441
```
Attention aux efx : emgr -P
```
[root@cafia2odt02 ~]# bootlist -m normal -ov
'ibm,max-boot-devices' = 0x5
NVRAM variable: (boot-device=/vdevice/vfc-client@30000004/disk@50060e8015341309,6000000000000:4 /vdevice/vfc-client@30000004/disk@50060e801534130d,6000000000000:4 /vdevice/vfc-client@30000005/disk@50060e8015341309,6000000000000:4 /vdevice/vfc-client@30000005/disk@50060e801534130d,6000000000000:4 /vdevice/vfc-client@30000006/disk@50060e8015341319,6000000000000:4)
Path name: (/vdevice/vfc-client@30000004/disk@50060e8015341309,6000000000000:4)
match_specific_info: ut=disk/fcp/htcuspvmpio
hdisk7 blv=bos_hd5 pathid=0
Path name: (/vdevice/vfc-client@30000004/disk@50060e801534130d,6000000000000:4)
match_specific_info: ut=disk/fcp/htcuspvmpio
hdisk7 blv=bos_hd5 pathid=1
Path name: (/vdevice/vfc-client@30000005/disk@50060e8015341309,6000000000000:4)
match_specific_info: ut=disk/fcp/htcuspvmpio
hdisk7 blv=bos_hd5 pathid=2
Path name: (/vdevice/vfc-client@30000005/disk@50060e801534130d,6000000000000:4)
match_specific_info: ut=disk/fcp/htcuspvmpio
hdisk7 blv=bos_hd5 pathid=3
Path name: (/vdevice/vfc-client@30000006/disk@50060e8015341319,6000000000000:4)
match_specific_info: ut=disk/fcp/htcuspvmpio
hdisk7 blv=bos_hd5 pathid=4

[root@cafia2odt02 ~]# multibos -Xs
Initializing multibos methods ...
Initializing log /etc/multibos/logs/op.alog ...
Gathering system information ...
+-----------------------------------------------------------------------------+
Setup Operation
+-----------------------------------------------------------------------------+
Verifying operation parameters ...
Creating image.data file ...
+-----------------------------------------------------------------------------+
Logical Volumes
+-----------------------------------------------------------------------------+
Creating standby BOS logical volume hd5
Creating standby BOS logical volume hd4
Creating standby BOS logical volume hd2
Creating standby BOS logical volume hd9var
Creating standby BOS logical volume hd10opt
0516-404 allocp: This system cannot fulfill the allocation request.
        There are not enough free partitions or not enough physical volumes
        to keep strictness and satisfy allocation requests.  The command
        should be retried with different allocation characteristics.
0516-822 mklv: Unable to create logical volume.
bosinst_mkobject: failed command: /usr/sbin/mklv  -o n -L /opt -u 32 -r y -b y -d p -v n -s y -w a -a c  -e m -c 1 -x 512 -t jfs2 -y hd10opt  rootvg 144 hdisk7
multibos: 0565-003 Error creating logical volumes.
multibos: 0565-035 Error setting up standby BOS.

+-----------------------------------------------------------------------------+
Boot Partition Processing
+-----------------------------------------------------------------------------+
Active boot logical volume is bos_hd5.
Standby boot logical volume is hd5.

+-----------------------------------------------------------------------------+
Logical Volumes
+-----------------------------------------------------------------------------+
Removing all standby BOS logical volumes ...
Removing standby BOS logical volume hd5
Removing standby BOS logical volume hd4
Removing standby BOS logical volume hd2
Removing standby BOS logical volume hd9var

+-----------------------------------------------------------------------------+
Bootlist Processing
+-----------------------------------------------------------------------------+
Verifying operation parameters ...
Setting bootlist to logical volume bos_hd5 on hdisk7.
ATTENTION: firmware recovery string for active BLV (bos_hd5):
boot /vdevice/vfc-client@30000004/disk@50060e8015341309,6000000000000:4
ATTENTION: firmware recovery string for standby BLV (bos_hd5):
boot /vdevice/vfc-client@30000004/disk@50060e801534130d,6000000000000:4
ATTENTION: firmware recovery string for standby BLV (bos_hd5):
boot /vdevice/vfc-client@30000005/disk@50060e8015341309,6000000000000:4
ATTENTION: firmware recovery string for standby BLV (bos_hd5):
boot /vdevice/vfc-client@30000005/disk@50060e801534130d,6000000000000:4
ATTENTION: firmware recovery string for standby BLV (bos_hd5):
boot /vdevice/vfc-client@30000006/disk@50060e8015341319,6000000000000:4
Log file is /etc/multibos/logs/op.alog
Return Status: FAILURE

[root@cafia2odt02 logs]# chfs -a size=-10G /opt
Filesystem size changed to 16777216
+-----------------------------------------------------------------------------+
Boot Partition Processing
+-----------------------------------------------------------------------------+
Active boot logical volume is bos_hd5.
Standby boot logical volume is hd5.
Creating standby BOS boot image on boot logical volume hd5
bosboot: Boot image is 53276 512 byte blocks.
+-----------------------------------------------------------------------------+
Mount Processing
+-----------------------------------------------------------------------------+
Unmounting all standby BOS file systems ...
Unmounting /bos_inst/opt
Unmounting /bos_inst/var
Unmounting /bos_inst/usr
Unmounting /bos_inst

+-----------------------------------------------------------------------------+
Bootlist Processing
+-----------------------------------------------------------------------------+
Verifying operation parameters ...
Setting bootlist to logical volume hd5 on hdisk7.
ATTENTION: firmware recovery string for standby BLV (hd5):
boot /vdevice/vfc-client@30000004/disk@50060e8015341309,6000000000000:2
ATTENTION: firmware recovery string for standby BLV (hd5):
boot /vdevice/vfc-client@30000004/disk@50060e801534130d,6000000000000:2
ATTENTION: firmware recovery string for standby BLV (hd5):
boot /vdevice/vfc-client@30000005/disk@50060e8015341309,6000000000000:2
ATTENTION: firmware recovery string for standby BLV (hd5):
boot /vdevice/vfc-client@30000005/disk@50060e801534130d,6000000000000:2
ATTENTION: firmware recovery string for standby BLV (hd5):
boot /vdevice/vfc-client@30000006/disk@50060e8015341319,6000000000000:2

Log file is /etc/multibos/logs/op.alog
Return Status = SUCCESS
You have mail in /usr/spool/mail/root

[root@cafia2odt02 logs]# oslevel -s
6100-08-02-1316

[root@cafia2odt02 logs]# lsvg -l rootvg
rootvg:
LV NAME             TYPE       LPs     PPs     PVs  LV STATE      MOUNT POINT
hd5                 boot       1       1       1    closed/syncd  N/A
hd6                 paging     64      64      1    open/syncd    N/A
hd8                 jfs2log    1       1       1    open/syncd    N/A
hd4                 jfs2       8       8       1    closed/syncd  /bos_inst
hd2                 jfs2       40      40      1    closed/syncd  /bos_inst/usr
hd9var              jfs2       16      16      1    closed/syncd  /bos_inst/var
hd3                 jfs2       24      24      1    open/syncd    /tmp
hd1                 jfs2       4       4       1    open/syncd    /home
hd10opt             jfs2       64      64      1    closed/syncd  /bos_inst/opt
hd11admin           jfs2       1       1       1    open/syncd    /admin
lg_dumplv           sysdump    16      16      1    open/syncd    N/A
livedump            jfs2       2       2       1    open/syncd    /var/adm/ras/livedump
orabinlv            jfs2       240     240     1    open/syncd    /u01/app
bos_hd5             boot       1       1       1    closed/syncd  N/A
bos_hd4             jfs2       8       8       1    open/syncd    /
bos_hd2             jfs2       40      40      1    open/syncd    /usr
bos_hd9var          jfs2       16      16      1    open/syncd    /var
bos_hd10opt         jfs2       64      64      1    open/syncd    /opt

[root@cafia2odt02 ~]# oslevel -s
6100-08-02-1316

[root@cafia2odt02 ~]# oslevel -s
6100-09-04-1441

[root@cafia2odt02 ~]# multibos -R
Initializing multibos methods ...
Initializing log /etc/multibos/logs/op.alog ...
Gathering system information ...

+-----------------------------------------------------------------------------+
Remove Operation
+-----------------------------------------------------------------------------+
Verifying operation parameters ...

+-----------------------------------------------------------------------------+
Boot Partition Processing
+-----------------------------------------------------------------------------+
Active boot logical volume is hd5.
Standby boot logical volume is bos_hd5.

+-----------------------------------------------------------------------------+
Mount Processing
+-----------------------------------------------------------------------------+
Unmounting all standby BOS file systems ...

+-----------------------------------------------------------------------------+
File Systems
+-----------------------------------------------------------------------------+
Removing all standby BOS file systems ...
Removing standby BOS file system /bos_inst/opt
Removing standby BOS file system /bos_inst/var
Removing standby BOS file system /bos_inst/usr
Removing standby BOS file system /bos_inst
+-----------------------------------------------------------------------------+
Logical Volumes
+-----------------------------------------------------------------------------+
Removing all standby BOS logical volumes ...
Removing standby BOS logical volume bos_hd5

+-----------------------------------------------------------------------------+
Bootlist Processing
+-----------------------------------------------------------------------------+
Verifying operation parameters ...
Setting bootlist to logical volume hd5 on hdisk7.
ATTENTION: firmware recovery string for active BLV (hd5):
boot /vdevice/vfc-client@30000004/disk@50060e8015341309,6000000000000:2
ATTENTION: firmware recovery string for standby BLV (hd5):
boot /vdevice/vfc-client@30000004/disk@50060e801534130d,6000000000000:2
ATTENTION: firmware recovery string for standby BLV (hd5):
boot /vdevice/vfc-client@30000005/disk@50060e8015341309,6000000000000:2
ATTENTION: firmware recovery string for standby BLV (hd5):
boot /vdevice/vfc-client@30000005/disk@50060e801534130d,6000000000000:2
ATTENTION: firmware recovery string for standby BLV (hd5):
boot /vdevice/vfc-client@30000006/disk@50060e8015341319,6000000000000:2

Log file is /etc/multibos/logs/op.alog
Return Status = SUCCESS
```
# Mise à jour HMC
Source : http://www-01.ibm.com/support/docview.wss?uid=nas8N1019821
```
monhmc -r mem
Every 4,0s: MONHmc mem                                 Thu Jun 11 09:19:58 2015
Mem:   4096048k total,  3348488k used,   747560k free,   338672k buffers
```
Save profile avant inter

Une fois la mise à jour DVD terminée, installation du service pack
Refaire une save depuis la HMC (WebUI)

Mise à jour SP2
```
NIM :  172.31.4.50  (.4 = rx de la HMC)
```
FTP en root
Mise à jour Fix 509
Puis Fix (voir IBM fixcentral) => Power Systems Management Console
Passer par un profil dynamique plutôt que statique

# Migration de path de VIO
```
lspv | awk ' $1 ~ /^hdisk/ { hd=$1 ; vg=$3 ; cmd=("ioscli lsdev -dev " $1 " -vpd | grep Z1 ") ; cmd | getline Lun ; sub(/..*\.{8}/, "" , Lun) ; printf "%-8s : %-8s ==> %s \n",hd , vg , Lun }'

HVAVIA01
hdisk0 : rootvg ==> CCIPA33C
hdisk1 : rootvg ==> CCIPA33C
hdisk31 : None ==> 2528 1A ....
hdisk74 : None ==> 2600 1A ....

HVAVIB01
hdisk29 : rootvg ==> 2528 2A ....
hdisk64 : None ==> 2600 2A ....

lsdev -type adapter | awk ' $1 ~ /^fcs/ { fc=$1 ; cmd=("ioscli lsdev -dev " $1 " -vpd | grep Network") ; cmd | getline wwpn ; sub(/..*\.{13}/, "" , wwpn) ;printf"%-4s ==> %s\n" , fc , wwpn }'

HVAVIA01
fcs2 ==> 10000000C9AFF694
fcs3 ==> 10000000C9AFF695

HVAVIB01
fcs2 ==> 10000000C9AFF462 <= à mettre dans un hostgroup dedié
fcs3 ==> 10000000C9AFF463

HVAVIA01
$ lsvg -pv rootvg
rootvg:
PV_NAME PV STATE TOTAL PPs FREE PPs FREE DISTRIBUTION
hdisk0 active 558 431 111..68..29..111..112
hdisk1 active 558 431 111..68..29..111..112
$ lsdev -dev hdisk0 -vpd
hdisk0 U78A0.001.DNWHYB9-P2-D3 SAS Disk Drive (300000 MB)

Manufacturer................IBM
Machine Type and Model......HUC103030CSS600
FRU Number..................44V6833
ROS Level and ID............41333343
Serial Number...............PDXHY8VE
EC Level....................L36403
Part Number.................44V6831
Device Specific.(Z0)........000006329F003002
Device Specific.(Z1)........CCIPA33C
Device Specific.(Z2)........0068
Device Specific.(Z3)........10128
Device Specific.(Z4)........
Device Specific.(Z5)........22
Device Specific.(Z6)........L36403
Hardware Location Code......U78A0.001.DNWHYB9-P2-D3

PLATFORM SPECIFIC

Name: disk
Node: disk
Device Type: block

$ lsdev -dev hdisk31 -vpd
hdisk31 U78A0.001.DNWHYB9-P1-C1-T2-W50060E8015341310-L15000000000000 MPIO Other FC SCSI Disk Drive

Manufacturer................HITACHI
Machine Type and Model......OPEN-V
Part Number.................
ROS Level and ID............36303038
Serial Number...............50 13413
EC Level....................
FRU Number..................
Device Specific.(Z0)........00000332CF000002
Device Specific.(Z1)........2528 1A ....
Device Specific.(Z2).........
Device Specific.(Z3).........
Device Specific.(Z4)............
Device Specific.(Z5)........
Device Specific.(Z6)........

PLATFORM SPECIFIC

Name: disk
Node: disk
Device Type: block

$ lsdev -dev hdisk31 -attr
attribute value description user_settable

PCM PCM/friend/fcpother Path Control Module False
PR_key_value none Persistant Reserve Key Value True+
algorithm round_robin Algorithm True+
clr_q no Device CLEARS its Queue on error True
dist_err_pcnt 0 Distributed Error Percentage True
dist_tw_width 50 Distributed Error Sample Time True
hcheck_cmd test_unit_rdy Health Check Command True+
hcheck_interval 60 Health Check Interval True+
hcheck_mode nonactive Health Check Mode True+
location Location Label True+
lun_id 0x15000000000000 Logical Unit Number ID False
lun_reset_spt yes LUN Reset Supported True
max_coalesce 0x40000 Maximum Coalesce Size True
max_retry_delay 60 Maximum Quiesce Time True
max_transfer 0x80000 Maximum TRANSFER Size True
node_name 0x50060e8015341310 FC Node Name False
pvid 00f63a5b9a12cc1f0000000000000000 Physical volume identifier False
q_err yes Use QERR bit True
q_type simple Queuing TYPE True
queue_depth 32 Queue DEPTH True
reassign_to 120 REASSIGN time out value True
reserve_policy no_reserve Reserve Policy True+
rw_timeout 30 READ/WRITE time out value True
scsi_id 0x161400 SCSI ID False
start_timeout 60 START unit time out value True
timeout_policy fail_path Timeout Policy True+
unique_id 240C50 13413252806OPEN-V07HITACHIfcp Unique device identifier False
ww_name 0x50060e8015341310 FC World Wide Name False

# lsdev -Cc disk
hdisk0 Available 00-08-00 SAS Disk Drive
hdisk1 Available 00-08-00 SAS Disk Drive

cfgdev = cfgadm de VIO

hvavia02
hdisk0 : rootvg ==> CCIPA33C
hdisk1 : rootvg ==> CCIPA33C
hdisk2 : None ==> 2600 1A ....
hdisk3 : None ==> 2528 1A ....

fcs0 ==> 10000000C9BA87C8
fcs1 ==> 10000000C9BA87C9

hvavib02
hdisk0 : rootvg ==> 2600 1A ....
hdisk21 : None ==> 2528 1A ....

fcs0 ==> 10000000C9BA8672
fcs1 ==> 10000000C9BA8673

$ lsvg -pv rootvg
rootvg:
PV_NAME PV STATE TOTAL PPs FREE PPs FREE DISTRIBUTION
hdisk0 active 558 487 111..108..45..111..112
hdisk1 active 558 489 111..105..50..111..112

odmget -q "name like hdisk*" CuAt
```
et la variante
```
odmget -q name=hdisk0 CuAt
```
voire
```
odmget CuAt
```

Creation du hostgroup dedie
hvavib01
```
$ lsdev -dev hdisk64 -vpd
hdisk64 U78A0.001.DNWHYB9-P1-C2-T1-W50060E8015341310-L0 MPIO Other FC SCSI Disk Drive

Manufacturer................HITACHI
Machine Type and Model......OPEN-V
Part Number.................
ROS Level and ID............36303038
Serial Number...............50 13413
EC Level....................
FRU Number..................
Device Specific.(Z0)........00000332CF000002
Device Specific.(Z1)........2600 2A ....
Device Specific.(Z2).........
Device Specific.(Z3).........
Device Specific.(Z4)...........b
Device Specific.(Z5)........
Device Specific.(Z6)........

PLATFORM SPECIFIC

Name: disk
Node: disk
Device Type: block

$ rmdev -dev hdisk64
hdisk64 deleted

$ lsdev -dev fcs2 -vpd
fcs2 U78A0.001.DNWHYB9-P1-C2-T1 8Gb PCI Express Dual Port FC Adapter (df1000f114108a03)

Part Number.................10N9824
Serial Number...............1B104046C9
Manufacturer................001B
EC Level....................D77040
Customer Card ID Number.....577D
FRU Number..................10N9824
Device Specific.(ZM)........3
Network Address.............10000000C9AFF462
ROS Level and ID............027820B7
Device Specific.(Z0)........31004549
Device Specific.(Z1)........00000000
Device Specific.(Z2)........00000000
Device Specific.(Z3)........09030909
Device Specific.(Z4)........FF781150
Device Specific.(Z5)........027820B7
Device Specific.(Z6)........077320B7
Device Specific.(Z7)........0B7C20B7
Device Specific.(Z8)........20000000C9AFF462
Device Specific.(Z9)........US2.02X7
Device Specific.(ZA)........U2D2.02X7
Device Specific.(ZB)........U3K2.02X7
Device Specific.(ZC)........00000000
Hardware Location Code......U78A0.001.DNWHYB9-P1-C2-T1

PLATFORM SPECIFIC

Name: fibre-channel
Model: 10N9824
Node: fibre-channel@0
Device Type: fcp
Physical Location: U78A0.001.DNWHYB9-P1-C2-T1
```
=> remove HBA from HCS/Hosts/Cluster/...

Creation hostgroup
Administration / Host / New Host / HVAPW101 (conv de nommage)
Puis allocation du disque depuis DPPOOL/ ....

smitty to remove path
```
# cfgmgr
# lspath
Enabled hdisk0 fscsi3
Enabled hdisk0 fscsi3
Enabled hdisk0 fscsi3
Enabled hdisk0 fscsi3
Enabled hdisk29 fscsi3
Enabled hdisk29 fscsi3
Enabled hdisk29 fscsi3
Enabled hdisk29 fscsi3
# rmdev -d -l fcs2 -R

# lscfg -v -l fcs2
fcs2 U78A0.001.DNWHYB9-P1-C2-T1 8Gb PCI Express Dual Port FC Adapter (df1000f114108a03)

Part Number.................10N9824
Serial Number...............1B104046C9
Manufacturer................001B
EC Level....................D77040
Customer Card ID Number.....577D
FRU Number..................10N9824
Device Specific.(ZM)........3
Network Address.............10000000C9AFF462
ROS Level and ID............027820B7
Device Specific.(Z0)........31004549
Device Specific.(Z1)........00000000
Device Specific.(Z2)........00000000
Device Specific.(Z3)........09030909
Device Specific.(Z4)........FF781150
Device Specific.(Z5)........027820B7
Device Specific.(Z6)........077320B7
Device Specific.(Z7)........0B7C20B7
Device Specific.(Z8)........20000000C9AFF462
Device Specific.(Z9)........US2.02X7
Device Specific.(ZA)........U2D2.02X7
Device Specific.(ZB)........U3K2.02X7
Device Specific.(ZC)........00000000
Hardware Location Code......U78A0.001.DNWHYB9-P1-C2-T1
```
refais le masking sur fabric 2
supprimer le 2e disk du hostgroup, remis dans HVAPW101
Refait le masking sur fabric1

suppression des path
puis disk
```
# rmdev -dl hdisk0
hdisk0 deleted
```
puis unallocate du cluster du 25:28

# Message LPM : erreur RMC sur LPAR
```
HSCLA246 The management console cannot communicate with partition cafid2odb08.  Either the network connection is not available or the partition does not have a level of software that is capable of supporting this operation.  Verify the correct network and setup of the partition, and try the operation again.

Root cause :
RMC Connexion HS
```
Solution : Relance RMC sur la Lpar
```
#> stopsrc -g rsct_rm; stopsrc -g rsct; sleep 2; startsrc -g rsct
```
Message LPM : erreur RMC Sur le VIOS
HSCLA246 The management console cannot communicate with partition hlavib15.  Either the network connection is not available or the partition does not have a level of software that is capable of supporting this operation.  Verify the correct network and setup of the partition, and try the operation again. 

Root cause : 
RMC conexion HS

Solution :
```
$> oem_setup_env
#> rmcctrl -z               arrêt des services
#> rmcctrl -A              relance des services
#> rmcctrl -p               authorisation de connexion des clients
```

**Technote : T1020611**

*Question*
How do I correct the "No RMC Connection" error I get when I try to DLPAR, perform an LPM operation or many other similar operations involving virtual machines in a Power Systems Environment.
Cause
Remote Management and Control (RMC) is a suite of applications built into AIX and available for some Enterprise Linux offerings that required a fixed IP configuration and secure communications using both TCP and UDP protocols between all hosts in the RMC peer domain. This communication can breakdown due to reconfigurations, reinstallations of backups, network issues or even code defects. There is no one-size-fists all solution to any RMC problem, but there are some simple checks that can be performed to verify configuration as well as attempt to repair the trusted configuration between a peer such as an LPAR and its management console such as an HMC.
Answer
There are some basic commands that can be run to check status of RMC configurations and there are some dependancies on RSCT versions as to which commands you use. RSCT 3.2.x.x levels are the newest and available in the latest releases of AIX and VIOS. More common installations will have RSCT at 3.1.x.x levels. The basic queries you can run to check RMC health are listed below.

1. To check RMC status on a LPAR as root (AIX or VIOS)

a. Applies to all AIX and VIOS levels
```
lslpp -l rsct.core.rmc ---> This fileset needs to be 3.1.0.x level or higher 
/usr/sbin/rsct/bin/ctsvhbac ---> Are all IP and host IDs trusted? 
lsrsrc IBM.MCP ---> Is the HMC listed as a resource? 
```
b. Only applies if AIX 6.1 TL5 or lower is used
```
lslpp -l csm.client ---> This fileset needs to be installed 
lsrsrc IBM.ManagementServer ---> Is HMC listed as a resource? 
```
2. To check RMC status on Management Console (HMC or FSM as admin user)
```
lspartition -dlpar ---> Is LPAR's DCaps value non-zero ? 
```
3. If you answer no to any of the above then corrective action is required. 

a. Missing file sets or fixes need to be installed. 

b. If RSCT file set rsct.core.rmc is at 3.1.5.0 or 3.2.0.0 then APARs apply.

c. Fix It Commands (run as root on LPAR and Management Console)

(1) You can try one of the following commands first as a super admin user on the HMC
```
lspartition -dlparreset (use if HMC v7)
diagrmc --autocorrect -v (Use if HMC v8)
```
a
(2) On the LPAR try running these commands first as well
```
/usr/sbin/rsct/bin/rmcctrl -z
/usr/sbin/rsct/bin/rmcctrl -A
/usr/sbin/rsct/bin/rmcctrl -p
```
(3) Wait a few minutes then check status again using the lsrsrc command listed above on the LPAR to see if the resources for the HMC are loaded and if you need to try something else proceed with the next options with caution. 

(4)The commands to run as root - note CAUTION
```
/usr/sbin/rsct/install/bin/recfgct
/usr/sbin/rsct/bin/rmcctrl -p
```
(a) CAUTION: Running the recfgct command on a node in a RSCT peer domain or in a Cluster Aware AIX (CAA) environment should NOT be done before taking other precautions first. This note is not designed to cover all CAA or other RSCT cluster considerations so if you have an application that is RSCT aware such as PowerHA, VIOS Storage Pools and several others do not proceed until you have contacted support.. If you need to determine if your system is a member of a CAA cluster then please refer to the Reliable Scalable Cluster Technology document titled, "Troubleshooting the resource monitoring and control (RMC) subsystem."

http://www-01.ibm.com/support/knowledgecenter/SGVKBA_3.1.5/com.ibm.rsct315.trouble/bl507_diagrmc.htm

(b) Pay particular attempt to the section titled Diagnostic procedures to help learn if you node is a member of any domain other than the Management Console's management domain.

(5) If the above does not help you will need to request pesh passwords from IBM Support for your Management Console so you can run the recfgct and rmcctrl commands listed above. 

(7) After running the above commands it will take several minutes before RMC connection is restored. The best way to monitor is by running the lspartition -dlpar command on the Management Console every few minutes and watch for the target LPAR to show up with a non-zero DCaps value. 

4. Things to consider before using the above fix commands or if the reconfigure commands don't help.

a. Network issues are often overlooked or disregarded. There are some network configuration issues that might need to be addressed if the commands that reconfigure RSCT don't restore DLPAR function. Determining if there is a network problem will require additional debug steps not covered in this tech note. However, there are some common network issues that can prevent RMC communications from passing between the Management Console and the LPARs and they include the following.

(1) Firewalls blocking bidirectional RMC related traffic for UDP and TCP on port 657. A crude field test for TCP connectivity is to telnet from the LPAR to port 657 on the HMC to see if you can connect (telnet <HMC IP> 657). If the connection attempt times out you know you have an issue where port 657 is blocked. The HMC does have a firewall configuration tool that is GUI based. Its accessed using the Change Network Settings task. For firewall issues beyond the HMC you will need to work with your network team to open up firewall access for the RMC channel.

(2) Mix of jumbo frames and standard Ethernet frames between the Management Console and LPARs.

(3) Multiple interfaces with IP addresses on the LPARs that can route traffic to the Management Console. 

b. The above steps only cover the more common and simplistic issues involved in RMC communication errors. If you are unable to reestablish RMC connection by running the commands suggested then a more detailed look at the problem is required. Data gathering tools such as pedbg on the Management Console and ctsnap on the LPARs are the next tools that should be used to look at the problem more closely.

5. If the basic things listed above have been checked or performed and still not getting RMC to work then its appropriate to collect additional data.

a. RMC Connection Errors Data Collection on LPAR

(1) Please check the clock setting on LPAR and management console to make sure they are in sync (use date command). Synchronizing clocks will make data analysis much easier. 

(2) From LPAR collect a snap 


(a) If AIX LPAR as root run 
```
snap -gtkc 
```
(b) If VIOS LPAR as padmin run
snap 


b. Collect a ctsnap from the LPAR as root 
```
/usr/sbin/rsct/bin/ctsnap -x runrpttr
```
c. Collect a pedbg from the management console as described in following below. 

(1) If HMC then run "pedbg -c -q 4" as user hscpe and refer to following

document for additional information if needed. 

Gathering and Transmitting PE Debug Data from an HMC 

http://www-01.ibm.com/support/docview.wss?&uid=isg3T1012079 


(2) If FSM or SDMC run "pedbg -c -q r" as pe and refer to following 

document for additional information if needed. 

Collecting pedbg on Flex System Manager (FSM) and Systems Director Management Console (SDMC)
https://www-304.ibm.com/support/docview.wss?uid=nas777a837116ee2fca8862578320079823c

d. Rename the data files collected on the LPAR.

(1) rename then snap file 
(a) On AIX LPAR the snap is in /tmp/ibmsupt so as root run following. 
```
mv /tmp/ibmsupt/snap.pax.Z /tmp/ibmsupt/<PMR#.Branch.000>-snap.pax.Z 
```
(b) On VIOS LPAR the snap is in /home/padmin so as padmin run following.
```
mv /home/padmin/snap.pax.Z /home/padmin/<PMR#.Branch.000>-snap.pax.Z 
```
(2) rename the ctsnap file 

Note: The output file for ctsnap will be in /tmp/ctsupt with a name 

similar to ctsnap.<hostname>.<date time>.tar.gz and so renaming it 

requires you to list /tmp/ctsupt so you can view the current name. 
```
ls -l /tmp/ctsupt 

mv /tmp/ctsupt.<ctsnap filename> <PMR#.Branch.000>-<ctsnap filename> 
```

e. Transmit the data files to IBM. 

(1) FTP or HTTPS site is testcase.software.ibm.com 

(2) User ID is anonymous and password can be your email address 

(3) Directory is /toibm/aix 

(4) Include the snap and ctsnap from the LPAR 

(5) Include the pedbg from the HMC (FSM or SDMC) 
```
# How to disable LPM from command line

Enable/Disable
```
chsyscfg -m SERVER_NAME -r lpar -p LPAR_NAME -i "migration_disabled=1"                                              # desactivation lpm
chsyscfg -m SERVER_NAME -r lpar -p LPAR_NAME -i "migration_disabled=0"                                              # activation lpm
lssyscfg -m SERVER_NAMES -r lpar --filter "lpar_names=LPAR_NAMES" -F name,migration_disabled         # statut de l'attribut
```

Disable de toutes les lpars HEAHMC01 en 1 ligne de commande
```
for serv in $(lssyscfg -r sys -F name | sort) # liste des serveurs
do
   for lpar in $(lssyscfg -m $serv -r lpar -F name | sort | grep -v -e "hlavi" -e "heavi" -e "POOL")   # liste des lpar excluant les VIOS et le STORES_POOL
   do
      chsyscfg -m $serv -r lpar -p $lpar -i "migration_disabled=1"  # modification de l'attribut
   done
done
```
Vérification en CLI
```
lssyscfg -m SERVER_NAMES -r lpar --filter "lpar_names=LPAR_NAMES" -F "name,migration_disabled"
```
en 1 ligne de commande sur toutes les lpars
```
for serv in $(lssyscfg -r sys -F name | sort) # liste des serveurs
do
   for lpar in $(lssyscfg -m $serv -r lpar -F name | sort | grep -v -e "hlavi" -e "heavi" -e "POOL")  #liste des lpars excluant les VIOS et le STORES_POOL
   do
      lssyscfg -m $serv -r lpar --filter "lpar_names=$lpar" -F "name,migration_disabled"   # display de l'attribut
   done
done
```

