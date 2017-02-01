package Corp::Bgzsync::Config;

use strict;
use warnings;

our (@ISA, @EXPORT_OK);

use constant {
	BGZSYNC_HOME => '.',
};

use constant {
	FAR_PAST => '19700101T00:00:00',
	LASTRUN_FILE => BGZSYNC_HOME.'/.LASTRUN',
	SYNCING_FLAG_FILE => BGZSYNC_HOME.'/.SYNCING',
	PROCEED_FLAG_FILE => BGZSYNC_HOME.'/.PROCEED',
	ERROR_FILE => BGZSYNC_HOME.'/errors.log',
	
	#-- define the minimum time between 2 loop rounds
	LOOP_DURATION => 60,
	#-- the ST Customer instance
	CUSTOMER_INSTANCE_URI => 'http://10.157.15.31:80/xmlrpc.cgi',
	CUSTOMER_INSTANCE_LOGIN => 'bgzqasync@st.com',
	CUSTOMER_INSTANCE_EMAIL => 'bgzqasync@st.com',
	CUSTOMER_INSTANCE_PASSWORD => 'J3_5u15_Ch4rl13_Q4',
	CUSTOMER_INSTANCE_REMEMBER_CRED => '',
	CUSTOMER_COOKIE_FILE => BGZSYNC_HOME.'/cookiescustomer.txt',
	#-- the ST R&D instance (a.k.a. the Internal instance)
	RD_INSTANCE_URI => 'http://10.157.15.60:80/xmlrpc.cgi',
	RD_INSTANCE_LOGIN => 'bgzqasync@st.com',
	RD_INSTANCE_EMAIL => 'bgzqasync@st.com',
	RD_INSTANCE_PASSWORD => 'J3_5u15_Ch4rl13_Q4',
	RD_INSTANCE_REMEMBER_CRED => '',
	RD_COOKIE_FILE => BGZSYNC_HOME.'/cookiesinternal.txt',
	#-- database connection settings
	MYSQL_HOST_NAME => 'localhost',
	MYSQL_SOCKET => '',
	MYSQL_PORT => '3306',
	MYSQL_DB_NAME => 'bgzsync',
	MYSQL_LOGIN_NAME => 'bgzsyncadm',
	MYSQL_PASSWORD => '0/admin',
	#-- sync info types
	SYNC_INFO_TYPE_ATTACHMENT => 'Att',
	SYNC_INFO_TYPE_COMMENT => 'Com',
	SYNC_INFO_TYPE_EVENT => 'Evt',
	#-- error/warning alerts
	ALERTS_SENT_TO => 'mohamedamin.doghri@st.com',
#	ALERTS_SENT_TO => 'olivier.cheron@st.com',
	ALERTS_SUBJECT => '[ENV=DEV] BGZSYNC',
	#-- retry configuration
	MAX_RETRY => 3,
	RETRY_SLEEP => 20,
	#-- must be 1 to use chunked attachment method or anything else to use the regular bugzilla webservice end point
	CHUNKED_ATTACHMENT => 1,
};

BEGIN {
	require Exporter;
	@ISA = qw(Exporter);
	@EXPORT_OK = qw(
		BGZSYNC_HOME FAR_PAST LASTRUN_FILE SYNCING_FLAG_FILE PROCEED_FLAG_FILE ERROR_FILE
		LOOP_DURATION CUSTOMER_INSTANCE_URI CUSTOMER_INSTANCE_LOGIN CUSTOMER_INSTANCE_EMAIL CUSTOMER_INSTANCE_PASSWORD CUSTOMER_INSTANCE_REMEMBER_CRED
		CUSTOMER_COOKIE_FILE RD_INSTANCE_URI RD_INSTANCE_LOGIN RD_INSTANCE_EMAIL RD_INSTANCE_PASSWORD RD_INSTANCE_REMEMBER_CRED RD_COOKIE_FILE
		MYSQL_HOST_NAME MYSQL_SOCKET MYSQL_DB_NAME MYSQL_PORT MYSQL_LOGIN_NAME MYSQL_PASSWORD MYSQL_DBNAME SYNC_INFO_TYPE_ATTACHMENT
		SYNC_INFO_TYPE_COMMENT SYNC_INFO_TYPE_EVENT ALERTS_SENT_TO ALERTS_SUBJECT MAX_RETRY RETRY_SLEEP CHUNKED_ATTACHMENT
	);
}

1;

__END__

################ Documentation ################

=pod

=head1 NAME

Corp::Bgzsync::Config - A class defining constant values used to configure a Bugzilla synchronizer.

=head1 SYNOPSIS

 package MyPackage;
 
 use Corp::Bgzsync::Config qw(FAR_PAST MYSQL_HOST_NAME);

 
=head1 DESCRIPTION

The Corp::Bgzsync::Config module exports all required constant values needed to configure a Bugzilla synchronizer.

 
=head1 CONSTANTS


=head2 C<FAR_PAST>:

 oldest possible value for a time stamp (formatted as a Bugzilla UTC timestamp) 

=head2 C<LASTRUN_FILE>:

 flag file containing the time stamp of the last run of the synchronizer: in the next run, the synchronizer will consider tickets created/updated since this time.

=head2 C<SYNCING_FLAG_FILE>:

 flag file indicating that the synchronizer is currently running

=head2 C<PROCEED_FLAG_FILE>:

 flag file that the synchronizer checks at every round: if not present, the synchronizer stops 

=head2 C<ERROR_FILE>:

 file where errors captured by the synchronizer are logged

=head2 C<LOOP_DURATION>:

 minimum duration of the synchronizer loop (in seconds): if the treatment takes less than this, the synchronizer gets to sleep...

=head2 C<CUSTOMER_INSTANCE_URI>:

 URI of the XML-RPC web service of the Bugzilla Customer instance

=head2 C<CUSTOMER_INSTANCE_LOGIN>:

 Login to use when authenticating against the Bugzilla Customer instance

=head2 C<CUSTOMER_INSTANCE_EMAIL>:

 Email of the synchronizer user when operating on the Bugzilla Customer instance

=head2 C<CUSTOMER_INSTANCE_PASSWORD>:

 Password to use when authenticating against the Bugzilla Customer instance

=head2 C<CUSTOMER_INSTANCE_REMEMBER_CRED>:

 Boolean to state whether or not the credentials are remembered when login in the Bugzilla Customer instance

=head2 C<CUSTOMER_COOKIE_FILE>:

 File where cookies exchanged with the Bugzilla Customer instance are kept

=head2 C<RD_INSTANCE_URI>:

 URI of the XML-RPC web service of the Bugzilla R&D instance

=head2 C<RD_INSTANCE_LOGIN>:

 Login to use when authenticating against the Bugzilla R&D instance

=head2 C<RD_INSTANCE_EMAIL>:

 Email of the synchronizer user when operating on the Bugzilla R&D instance

=head2 C<RD_INSTANCE_PASSWORD>:

 Password to use when authenticating against the Bugzilla R&D instance

=head2 C<RD_INSTANCE_REMEMBER_CRED>:

 Boolean to state whether or not the credentials are remembered when login in the Bugzilla R&D instance

=head2 C<RD_COOKIE_FILE>:

 File where cookies exchanged with the Bugzilla R&D instance are kept

=head2 C<MYSQL_HOST_NAME>:

 IP address or DNS name of the server hosting the MySQL database where synchronization records are kept 

=head2 C<MYSQL_SOCKET>:

 path of the socket file to be used when connecting to the MySQL server

=head2 C<MYSQL_PORT>:

 Port to be used when connecting to the MySQL database where synchronization records are kept

=head2 C<MYSQL_DB_NAME>:

 Name of the MySQL database where synchronization records are kept

=head2 C<MYSQL_LOGIN_NAME>:

 Login to use when authenticating against the MySQL database where synchronization records are kept

=head2 C<MYSQL_PASSWORD>:

 Password to use when authenticating against the MySQL database where synchronization records are kept

=head2 C<SYNC_INFO_TYPE_ATTACHMENT>:

 Type corresponding to "highest attachment ID pushed" information in a synchronization record

=head2 C<SYNC_INFO_TYPE_COMMENT>:

 Type corresponding to "highest comment ID pushed" information in a synchronization record

=head2 C<SYNC_INFO_TYPE_EVENT>:

 Type corresponding to "latest history event considered" information in a synchronization record

=head2 C<ALERTS_SENT_TO>:

 Email addresses of people to be notified when the synchronizer raises an alert

=head2 C<ALERTS_SUBJECT>:

 Subject of email notifications sent when the synchronizer raises an alert;
 this subject should uniquely identify the Bugzilla environment raising the alert

=head2 C<MAX_RETRY>:

 in the main loop of the synchronizer, in case connection to a Bugzilla instance fails, the synchronizer will retry MAX_RETRY times before actually dying

=head2 C<RETRY_SLEEP>:

 in the main loop of the synchronizer, in case connection to a Bugzilla instance fails, the synchronizer will sleep RETRY_SLEEP seconds before retrying

=head1 AUTHOR

=over 4

L<Olivier CHERON|olivier.cheron@st.com>

=back

=head1 COPYRIGHT

=over 4

Copyright 2014 by ST.

=back

=cut
 
