#!/usr/bin/perl -wT

use lib qw(lib);
use Getopt::Long;
use Pod::Usage;
use File::Basename qw(dirname);
use File::Spec;
use HTTP::Cookies;
use XMLRPC::Lite;
use Data::Dumper;
use DateTime;
use DBI;
use POSIX 'strftime';
use Storable;
#use Tie::IxHash;

#-- load synchronizer configuration
#-- NOTE: the user performing automatic updates during the synchronization process is
#    - CUSTOMER_INSTANCE_EMAIL for tickets belonging to the ST Customer Bugzilla instance
#    - RD_INSTANCE_EMAIL for tickets belonging to the ST Internal Bugzilla instance
use Corp::Bgzsync::Config qw(BGZSYNC_HOME FAR_PAST LASTRUN_FILE SYNCING_FLAG_FILE PROCEED_FLAG_FILE ERROR_FILE LOOP_DURATION CUSTOMER_INSTANCE_URI CUSTOMER_INSTANCE_LOGIN CUSTOMER_INSTANCE_EMAIL CUSTOMER_INSTANCE_PASSWORD CUSTOMER_INSTANCE_REMEMBER_CRED CUSTOMER_COOKIE_FILE RD_INSTANCE_URI RD_INSTANCE_LOGIN RD_INSTANCE_EMAIL RD_INSTANCE_PASSWORD RD_INSTANCE_REMEMBER_CRED RD_COOKIE_FILE SYNC_INFO_TYPE_ATTACHMENT SYNC_INFO_TYPE_COMMENT SYNC_INFO_TYPE_EVENT ALERTS_SENT_TO ALERTS_SUBJECT MAX_RETRY RETRY_SLEEP);
use Corp::Bgzsync::BugzillaWS;
use Try::Tiny;
$| = 1;

        #-- create to 2 objects used to encapsulate WS calls made on 'ST Customer' and 'ST Internal' respectively
        $customerWS = new Corp::Bgzsync::BugzillaWS('customer', CUSTOMER_INSTANCE_URI, ($debug = 3));
        $internalWS = new Corp::Bgzsync::BugzillaWS('internal', RD_INSTANCE_URI, ($debug = 3));
        #-- login to both instances
        
        printf STDERR "*** Login to Customer instance...\n" if $debug;
	$L_SoapResultCustomer = $customerWS->call('User.login',
	                                   { login => CUSTOMER_INSTANCE_LOGIN, 
	                                     password => CUSTOMER_INSTANCE_PASSWORD,
	                                     remember => CUSTOMER_INSTANCE_REMEMBER_CRED } );
	                             
        printf STDERR "*** Login to internal instance...\n" if $debug;
        $L_SoapResultInternal = $internalWS->call('User.login',
                                           { login => CUSTOMER_INSTANCE_LOGIN,
                                             password => CUSTOMER_INSTANCE_PASSWORD,
                                             remember => CUSTOMER_INSTANCE_REMEMBER_CRED } );
                                                
	# to get attachments
	$L_SoapResultInternal = $internalWS->call('WSChunked.attachments', {attachment_ids => [101271]}); # hardcoded internal ticket ID
	
	foreach my $attachmentId (sort {$a <=> $b} keys %{$L_SoapResultInternal->result->{attach_chunks}}) {
		my $attachment = $L_SoapResultInternal->result->{attach_chunks}->{$attachmentId};
		$attacherInfo .= ('[id: ' . $attachmentId . "]\n");
		$attacherInfo .= "[file_name: " . $attachment->{file_name} . "]\n";
		$attacherInfo .= ('[summary: ' . $attachment->{summary} . "]\n");
		$attacherInfo .= ('[attachment data: ' . $attachment->{data} . "]\n");
		
		print $attacherInfo;

	#################################################get chunk ########################################
	my $chunk_nbr = $L_SoapResultInternal->result->{attach_chunks}->{$attachmentId}->{nb_chunks};
	for my $i (0 .. $chunk_nbr-1) {
		$L_SoapResultInternalget = $internalWS->call('WSChunked.chunk', {attachment_id => $attachmentId, chunk_id => $i, last_chunk => $chunk_nbr-1});
		my $chunk = $L_SoapResultInternalget->result->{attach_chunk}->{data};
		my $attach_id = $L_SoapResultInternalget->result->{attach_chunk}->{attachment_id};
	
		$L_SoapResultCustomeradd = $customerWS->call('WSChunked.add_chunk', 
				{
					ids => 77880, #hardcoded remote ticket ID
					attachment_id => $attachmentId,
					chunk => $chunk,
					chunk_id => $i,
					last_chunk => $chunk_nbr-1,
					file_name => $attachment->{file_name},
					summary => $attachment->{summary},
					content_type => $attachment->{content_type},
					is_patch => $attachment->{is_patch},
					comment => "",
					is_private => ""
				}
		);	
		print ".";

		}
	}	

