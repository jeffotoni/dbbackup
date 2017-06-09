# dbbackup

Script responsible for backing up the database in postgresql, mysql and redis, then copying them to a bucket in S3, in case of an error the script will send an email to warn the administrator.

The email can be sent by mailutils or aws cli, if you installed awscli you can send via the awscli ses.

The script also backs up the crontab.

The script was done in linux environment running the Ubuntu distribution, but nothing prevents you from changing according to your need and distribution.


# Setting up some variables

Setting the backup type in postgresql

```sh
#
# 
#
TYPE_BK_POSTGRESQL=all

#
#
#
#TYPE_BK_POSTGRESQL=list

#
#
#
POSTGRES_BD_LIST='database1 database2 database3 database4 database5 database6';

#
# Do for all database
#
for bd in $(psql -U postgres -Alt | awk 'BEGIN {FS="|"} ! /^postgres|^template/ {print $1}')
do
  echo -en "\nBase '${bd}'... "
  psql -U postgres -Atc "SELECT pg_size_pretty(pg_database_size(current_database()));"
  pg_dump -Upostgres -Fc -Z9 -b -o ${bd} -f ${dir_dmps}/${bd}.${data_iso_bd}.dmp 2> ${dir_logs}/${bd}.${data_iso_bd}.dmp.log && echo -en "OK" || echo -en "ERRO"
done

#
# Do for some database
#
for bd in $list;
do
echo ${bd}
pg_dump -Upostgres -Fc -Z9 -b -o ${bd} -f ${dir_dmps}/${bd}.${data_iso_bd}.dmp 2> ${dir_logs}/${bd}.${data_iso_bd}.dmp.log && echo -en "OK" || echo -en "ERRO"

echo "Copying to aws s3"
aws s3 cp ${dir_dmps}/${bd}.${data_iso_bd}.dmp s3://bucket/
done

```

Setting the backup type in mysql

```sh

$ mysqldump -uroot -p --all-databases > /home/bkp.databases.db
$  
$ mysqldump -uroot -p database > /home/bkp.database.db  
$  
$ mysqldump --databases db1 db2 db3 > dump.sql
$  
$ aws s3 cp bkp.database.db  s3://bucket/mysql/bkp.database.db

```

Setting the backup type in redis


```sh

$ redis-cli save
$ aws s3 cp /var/lib/redis/dump.rdb s3://bucket/redis/dump.rdb

```



# running

$ sh dbbackup.sh

# Can be configured by cron to be called from time to time

Script being called in every 12 hours

```sh

* */12 * * *   cd /backup && sh dbbackup.sh >> dbbackup.log

```