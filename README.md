# phpBB3 backup script (1.1.0)
Creates a backup of your phpBB3 forum and mysql data

---

1. Edit the settings at the top of phpbb3backup.pl if needed
2. create a cron job like this:

        1 1 * * * /root/phpbb3-backup/phpbb3backup.pl

3. This will back up your forum installation at 1:01am each day, and keep the last 5 backups.

4. Manually run a backup and the first time it will ask you for the mysql config info.

If you need more help visit https://phpbbhosting.retro-os.live/
