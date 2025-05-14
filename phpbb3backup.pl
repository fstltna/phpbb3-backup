#!/usr/bin/perl

# Set these for your situation
my $BACKUPDIR = "/root/backups";
my $TARCMD = "/bin/tar czf";
my $SQLDUMPCMD = "/usr/bin/mysqldump";
my $VERSION = "1.5.0";
my $OPTION_FILE = "/root/.phpbackuprc";
my $LATESTFILE = "$BACKUPDIR/phpbb3backup.mysql-1";
my $DOSNAPSHOT = 0;
my $MYSQLUSER = "";
my $MYSQLPSWD = "";
my $MYSQLDBNAME = "phpbb3";
my $FORUMDIR = "/var/www/html";
my $FILEEDITOR = $ENV{EDITOR};

if ($FILEEDITOR eq "")
{
	$FILEEDITOR = "/usr/bin/nano";
}

my $templatefile = <<'END_TEMPLATE';
# Put mysql user here
phpbb3
# Put mysql password here
changeme
# Put database name here
phpbb3
# Put the forum path here
/var/www/html
# Get more apps like this at https://phpbbhosting.retro-os.live/
END_TEMPLATE

# Get if they said a option
my $CMDOPTION = shift;

sub ReadPrefs
{
	my $LineCount = 0;
	if (! -f $OPTION_FILE)
	{
		open my $fh, '>', "$OPTION_FILE";
		print ($fh $templatefile);
		close($fh);
		system("$FILEEDITOR $OPTION_FILE");
	}

	open(my $fh, '<:encoding(UTF-8)', $OPTION_FILE)
		or die "Could not open file '$OPTION_FILE' $!";

	while (my $row = <$fh>)
	{
		chomp $row;
		if (substr($row, 0, 1) eq "#")
		{
			# Skip comment lines
			next;
		}
		if ($LineCount == 0)
		{
			$MYSQLUSER = $row;
		}
		elsif ($LineCount == 1)
		{
			$MYSQLPSWD = $row;
		}
		elsif ($LineCount == 2)
		{
			$MYSQLDBNAME = $row;
		}
		elsif ($LineCount == 3)
		{
			$FORUMDIR = $row;
		}
		$LineCount += 1;
	}
	close($fh);
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
	system("$SQLDUMPCMD --user=$MYSQLUSER --password=$MYSQLPSWD --result-file=$DUMPFILE $MYSQLDBNAME");
	print "\n";
}

if (defined $CMDOPTION)
{
	if (($CMDOPTION ne "-snapshot") && ($CMDOPTION ne "-prefs"))
	{
		print "Unknown command line option: '$CMDOPTION'\nOnly allowed options are '-snapshot' and '-prefs'\n";
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
	system("$TARCMD $BACKUPDIR/snapshot.tgz $FORUMDIR > /dev/null 2>\&1");
	print "\nBackup Completed.\nBacking up MYSQL data: ";
	if (-f "$BACKUPDIR/snapshot.mysql")
	{
		unlink("$BACKUPDIR/snapshot.mysql");
	}
	DumpMysql("$BACKUPDIR/snapshot.mysql");
	print "\n";
}

#-------------------
# No changes below here...
#-------------------

if ((defined $CMDOPTION) && ($CMDOPTION eq "-snapshot"))
{
	$DOSNAPSHOT = -1;
}

print "phpbb3backup.pl version $VERSION\n";
if ($DOSNAPSHOT == -1)
{
	print "Running Manual Snapshot\n";
}
print "==============================\n";

if ((defined $CMDOPTION) && ($CMDOPTION eq "-prefs"))
{
	# Edit the prefs file
	print "Editing the prefs file\n";
	if (! -f $OPTION_FILE)
	{
		open my $fh, '>', "$OPTION_FILE";
		print ($fh $templatefile);
		close($fh);
	}
	system("$FILEEDITOR $OPTION_FILE");
	exit 0;
}

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
	unlink("$BACKUPDIR/phpbb3backup-5.tgz") or warn "Could not unlink $BACKUPDIR/phpbb3backup-5.tgz: $!";
}

my $FileRevision = 4;

while ($FileRevision > 0)
{
	if (-f "$BACKUPDIR/phpbb3backup-$FileRevision.tgz")
	{
		my $NewVersion = $FileRevision + 1;
		rename("$BACKUPDIR/phpbb3backup-$FileRevision.tgz", "$BACKUPDIR/phpbb3backup-$NewVersion.tgz");
	}
	$FileRevision -= 1;
}

print "Done\nCreating New Backup: ";
system("$TARCMD $BACKUPDIR/phpbb3backup-1.tgz $FORUMDIR");
print "Done\nMoving Existing MySQL data: ";
if (-f "$BACKUPDIR/phpbb3backup.mysql-5")
{
	unlink("$BACKUPDIR/phpbb3backup.mysql-5") or warn "Could not unlink $BACKUPDIR/phpbb3backup.mysql-5: $!";
}
$FileRevision = 4;
while ($FileRevision > 0)
{
	if (-f "$BACKUPDIR/phpbb3backup.mysql-$FileRevision")
	{
		my $NewVersion = $FileRevision + 1;
		rename("$BACKUPDIR/phpbb3backup.mysql-$FileRevision", "$BACKUPDIR/phpbb3backup.mysql-$NewVersion");
	}
	$FileRevision -= 1;
}

DumpMysql($LATESTFILE);
print("Done!\n");
exit 0;
