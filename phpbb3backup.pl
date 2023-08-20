#!/usr/bin/perl

# Set these for your situation
my $MTDIR = "/var/www/html";
my $BACKUPDIR = "/root/backups";
my $TARCMD = "/bin/tar czf";
my $SQLDUMPCMD = "/usr/bin/mysqldump";
my $VERSION = "1.0.0";
my $OPTION_FILE = "/root/.phpbackuprc";
my $LATESTFILE = "$BACKUPDIR/phpbb3backup.sql-1";
my $DOSNAPSHOT = 0;
my $MYSQLUSER = "";
my $MYSQLPSWD = "";
my $MYSQLDBNAME = "phpbb3";
my $FORUMDIR = "/var/www/html";

# Get if they said a option
my $CMDOPTION = shift;

sub ReadPrefs
{
	my $LineCount = 0;
	if (! -f $OPTION_FILE)
	{
		print "Unable to open '$OPTION_FILE'. Please create it with your mysql data in this format:\n";
		print "First line - mysql user\nSecond line = mysql-password\nThird line = database name\nFourth line = forum folder\n";
		print "--- Press Enter To Continue: ";
		my $entered = <STDIN>;
		exit 0;
	}

	open(my $fh, '<:encoding(UTF-8)', $OPTION_FILE)
		or die "Could not open file '$OPTION_FILE' $!";

	while (my $row = <$fh>)
	{
		chomp $row;
		if ($LineCount == 0)
		{
			$MYSQLUSER = $row;
		}
		if ($LineCount == 1)
		{
			$MYSQLPSWD = $row;
		}
		if ($LineCount == 2)
		{
			$MYSQLDBNAME = $row;
		}
		if ($LineCount == 3)
		{
			$FORUMDIR = $row;
		}
		$LineCount += 1;
	}
	close($fh);
	# print "User = $MYSQLUSER, PSWD = $MYSQLPSWD\n";
}

sub DumpMysql
{
	my $DUMPFILE = $_[0];

	print "Backing up MYSQL data: ";
	if (-f "$DUMPFILE")
	{
		unlink("$DUMPFILE");
	}
	# print "User = $MYSQLUSER, PSWD = $MYSQLPSWD\n";
	system("$SQLDUMPCMD  --user=$MYSQLUSER --password=$MYSQLPSWD --result-file=$DUMPFILE $MYSQLDBNAME");
	print "\n";
}

if (defined $CMDOPTION)
{
	if ($CMDOPTION ne "-snapshot")
	{
		print "Unknown command line option: '$CMDOPTION'\nOnly allowed option is '-snapshot'\n";
		exit 0;
	}
}

sub SnapShotFunc
{
	print "Backing up java files: ";
	if (-f "$BACKUPDIR/snapshot.tgz")
	{
		unlink("$BACKUPDIR/snapshot.tgz");
	}
	system("$TARCMD $BACKUPDIR/snapshot.tgz $MTDIR > /dev/null 2>\&1");
	print "\nBackup Completed.\nBacking up MYSQL data: ";
	if (-f "$BACKUPDIR/snapshot.sql")
	{
		unlink("$BACKUPDIR/snapshot.sql");
	}
	# print "User = $MYSQLUSER, PSWD = $MYSQLPSWD\n";
	DumpMysql("$BACKUPDIR/snapshot.sql");
	print "\n";
}

#-------------------
# No changes below here...
#-------------------

if ((defined $CMDOPTION) && ($CMDOPTION eq "-snapshot"))
{
	$DOSNAPSHOT = -1;
}

print "phpBB3Backup.pl version $VERSION\n";
if ($DOSNAPSHOT == -1)
{
	print "Running Manual Snapshot\n";
}
print "==============================\n";

ReadPrefs();

if (! -d $BACKUPDIR)
{
	print "Backup dir $BACKUPDIR not found, creating...\n";
	system("mkdir -p $BACKUPDIR");
}
if ($DOSNAPSHOT == -1)
{
	SnapShotFunc();
	exit 0;
}

print "Moving existing backups: ";

if (-f "$BACKUPDIR/phpbb3backup-5.tgz")
{
	unlink("$BACKUPDIR/phpbb3backup-5.tgz")  or warn "Could not unlink $BACKUPDIR/phpbb3backup-5.tgz: $!";
}
if (-f "$BACKUPDIR/phpbb3backup-4.tgz")
{
	rename("$BACKUPDIR/phpbb3backup-4.tgz", "$BACKUPDIR/phpbb3backup-5.tgz");
}
if (-f "$BACKUPDIR/phpbb3backup-3.tgz")
{
	rename("$BACKUPDIR/phpbb3backup-3.tgz", "$BACKUPDIR/phpbb3backup-4.tgz");
}
if (-f "$BACKUPDIR/phpbb3backup-2.tgz")
{
	rename("$BACKUPDIR/phpbb3backup-2.tgz", "$BACKUPDIR/phpbb3backup-3.tgz");
}
if (-f "$BACKUPDIR/phpbb3backup-1.tgz")
{
	rename("$BACKUPDIR/phpbb3backup-1.tgz", "$BACKUPDIR/phpbb3backup-2.tgz");
}
print "Done\nCreating New Backup: ";
system("$TARCMD $BACKUPDIR/phpbb3backup-1.tgz $MTDIR");
print "Done\nMoving Existing MySQL data: ";
if (-f "$BACKUPDIR/phpbb3backup.sql-5")
{
	unlink("$BACKUPDIR/phpbb3backup.sql-5")  or warn "Could not unlink $BACKUPDIR/phpbb3backup.sql-5: $!";
}
if (-f "$BACKUPDIR/phpbb3backup.sql-4")
{
	rename("$BACKUPDIR/phpbb3backup.sql-4", "$BACKUPDIR/phpbb3backup.sql-5");
}
if (-f "$BACKUPDIR/phpbb3backup.sql-3")
{
	rename("$BACKUPDIR/phpbb3backup.sql-3", "$BACKUPDIR/phpbb3backup.sql-4");
}
if (-f "$BACKUPDIR/phpbb3backup.sql-2")
{
	rename("$BACKUPDIR/phpbb3backup.sql-2", "$BACKUPDIR/phpbb3backup.sql-3");
}
if (-f "$BACKUPDIR/phpbb3backup.sql-1")
{
	rename("$BACKUPDIR/phpbb3backup.sql-1", "$BACKUPDIR/phpbb3backup.sql-2");
}
DumpMysql($LATESTFILE);
print("Done!\n");
exit 0;
