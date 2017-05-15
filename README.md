# dbbackup

Script responsible for backing up the database in postgresql and mysql, then copying them to a bucket in S3, in case of an error the script will send an email to warn the administrator.

The email can be sent by mailutils or aws cli, if you installed awscli you can send via the awscli ses.

The script also backs up the crontab.

The script was done in linux environment running the Ubuntu distribution, but nothing prevents you from changing according to your need and distribution.



# running

$ sh dbbackup.sh

# Can be configured by cron to be called from time to time

Script being called in every 12 hours

```sh

* */12 * * *   cd /backup && sh dbbackup.sh >> dbbackup.log

```