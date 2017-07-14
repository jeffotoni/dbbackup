#!/bin/bash

#
# autor: @jeffotoni
# about: Script to deploy our applications
# date:  15/05/2017
# since: Version 0.1
#

#
#
#
TYPE_BK_POSTGRESQL='ALL'

#
#
#
#TYPE_BK_POSTGRESQL='LIST'

#
#
#
POSTGRES_BD_LIST='database1 database2 database3 database4 database5 database6';

#
#
#
AWSCP_S3="no"

#
#
#
script_nome=$(basename $0)

#
#
#
script_versao="1.0"

#
#
#
data_iso_bd="unico-"$(date +%u-%H)

#
#
#
data_iso="-unico-"$(date +%u-%H)

#
#
#
dia_semana=$(date +%w)

#
#
#
dir_corrente=$PWD

#dir_dmps=${dir_corrente}/dmps${data_iso}
#
dir_dmps=${dir_corrente}/dmps-semanal/dmps${data_iso}

#
#
#
dir_mysql=${dir_corrente}/mydmps${data_iso}

#
#
#
dir_virt=${dir_corrente}/virtualhosts_unico

#
#
#
dir_etc=${dir_corrente}/etc-backup

#
#
#
dir_logs=${dir_corrente}/logs

#
#
#
dir_cron=${dir_corrente}/cron-file

#
#
#
lock=${dir_corrente}/${script_nome}.lock

#
#
#
tmp=${dir_corrente}/${script_nome}.tmp

#
#
#
test -f ${lock} && {
   teste=$(ps --no-headers -p $(head -1 ${lock} 2>/dev/null) 2>/dev/null)
   test -z "${teste}" && rm -vf ${lock} || {
      echo -e "\nERRO:\tLock archive found."
      echo "\n\tMake sure another backup is running"
      echo "\n\t you remove the file '${lock}' And try again.\n\n"
      exit 1
   }
}

#
#
#
echo -e "\n# ${script_nome} (v${script_versao})\n# ${data_iso}\n### Start ###"

#
#
#
echo -e $$"\n"${data_iso} > ${lock}

#
#
#
test -d ${dir_dmps} || mkdir -pv ${dir_dmps}

#
#
#
test -d ${dir_mysql} || mkdir -pv ${dir_mysql}

#
#
#
test -d ${dir_virt} || mkdir -pv ${dir_virt}

#
#
#
test -d ${dir_logs} || mkdir -pv ${dir_logs}

#
#
#
test -d ${dir_cron} || mkdir -pv ${dir_cron}

#
#
#
chown -Rf postgres. ${dir_dmps} ${dir_logs}


#
# Do for all database
#
if [ "$TYPE_BK_POSTGRESQL" = "ALL" ]
  then

for bd in $(psql -U postgres -Alt | awk 'BEGIN {FS="|"} ! /^postgres|^template/ {print $1}')
do
  echo -en "\nBase '${bd}'... "
  psql -U postgres -Atc "SELECT pg_size_pretty(pg_database_size(current_database()));"
  pg_dump -Upostgres -Fc -Z9 -b -o ${bd} -f ${dir_dmps}/${bd}.${data_iso_bd}.dmp 2> ${dir_logs}/${bd}.${data_iso_bd}.dmp.log && echo -en "OK" || echo -en "ERRO"

  if [ "$AWSCP_S3" = "yes" ]
    then
      echo "Copying to aws s3"
      aws s3 cp ${dir_dmps}/${bd}.${data_iso_bd}.dmp s3://bucket/
    fi

done
fi

#
# Do for some database
#
if [ "$TYPE_BK_POSTGRESQL" = "LIST" ]
  then
for bd in $list;
do
echo ${bd}
pg_dump -Upostgres -Fc -Z9 -b -o ${bd} -f ${dir_dmps}/${bd}.${data_iso_bd}.dmp 2> ${dir_logs}/${bd}.${data_iso_bd}.dmp.log && echo -en "OK" || echo -en "ERRO"

if [ "$AWSCP_S3" = "yes" ]
    then
      echo "Copying to aws s3"
      aws s3 cp ${dir_dmps}/${bd}.${data_iso_bd}.dmp s3://bucket/
    fi
done
fi

echo ""
echo "${dir_dmps} backup" >> log_backup.log

#cp -r ${dir_dmps} /media/pen
rm -f ${lock} ${tmp} $(find ${dir_dmps} ${dir_logs} -empty -type f)

chown -Rf postgres. ${dir_dmps} ${dir_logs}

# backup of cron
crontab -l > ${dir_cron}/crontab.txt

if [ "$AWSCP_S3" = "yes" ]
    then
      aws s3 cp ${dir_cron}/crontab.txt s3://bucket/crontab.txt
    fi
    
echo -e "\n### Fim dump ###"

exit 0
