package Corp::Bgzsync::BugzillaWS;

use strict;
use warnings;
use DBI;

use File::Basename;
use HTTP::Cookies;
use XMLRPC::Lite;
use lib dirname(__FILE__);
use Corp::Bgzsync::Config qw(BGZSYNC_HOME);
use base qw(Corp::Base);
use Data::Dumper;
use SOAP::Lite;

my %fields = (
	cookieJar => undef,
	proxy => undef,
	URI => undef,
	authToken => undef,
);

#-- define the list of known Bugzilla web services 
my %_validBugzillaWS = (
	'Bug.add_attachment' => 1,
	'Bug.add_comment' => 1,
	'Bug.attachments' => 1,
	'Bug.comments' => 1,
	'Bug.create' => 1,
	'Bug.get' => 1,
	'Bug.history' => 1,
	'Bug.search' => 1,
	'Bug.update' => 1,
	'Bugzilla.time' => 1,
	'Product.get' => 1,
	'Product.get_selectable_products' => 1,
	'User.login' => 1,
	'User.logout' => 1,
	'CustomWorkflow.cws_get_all_users' => 1,
	'CustomWorkflow.cws_get_products' => 1,
	'CustomWorkflow.cws_set_attachment_properties' => 1,
	'CustomWorkflow.cws_set_product_versions' => 1,
	'InternalWorkflow.cws_get_remote_user' => 1,
	'WSChunked.chunk' => 1,
	'WSChunked.attachments' => 1,
	'WSChunked.add_chunk' => 1
);

sub new {
	my ($class, $myname, $URI, $debug) = @_;
	my $self = $class->SUPER::new($myname);
	foreach my $element (keys %fields) {
		$self->{_permitted}->{$element} = $fields{$element};
	}
	#-- set the Bugzilla URI
	$self->{URI} = $URI;
	#-- set the cookie jar (saved in a file named after $myname)
	$self->{cookieJar} = new HTTP::Cookies('file' => BGZSYNC_HOME . '/' . $myname . '.txt', 'autosave' => 1);
	#-- set the XMLRPC proxy
	$self->{proxy} = XMLRPC::Lite->proxy($self->{URI}, 'cookie_jar' => $self->{cookieJar})
		or Corp::Bgzsync::Exception::WSconnection->throw('uri' => $self->{URI}, 'service' => 'na', 'params' => {}, 'error' => 'error while setting XMLRPC::Lite proxy');
	#-- fix problem of badly base64 encoding of non ASCII chars:
	#-- even if parameter values in XML messages are utf8 encoded by default,
	#-- XMLRPC::Lite base64-encodes all non ASCII chars which are not correctly decoded on the receiver side
	#-- => change this default behavior by encoding strings iff they are NOT already utf8
	my $serializer = $self->{proxy}->serializer( );
	$serializer->typelookup->{base64} = [10, sub { !utf8::is_utf8($_[0]) && $_[0] =~ /[^\x09\x0a\x0d\x20-\x7f]/}, 'as_base64'];
	#-- if debug mode is required, add trace to the XMLRPC proxy
	if ($debug) {
		$self->{proxy}->import(+trace => 'debug');
	}
	return $self;
}

sub call {
	my $self = shift;
	my $service = shift;
	my $params = shift;
	#-- check validity of Bugzilla service
	if ( exists $_validBugzillaWS{$service} ) {
		#-- except for Login service, add the auth token to any WS call
		unless ($service eq 'User.login') {
			$params->{Bugzilla_token} = $self->{authToken};
		}
		#-- set fault handler to catch "transport" error so that exception is thrown instead of a die
		#-- (note: we set this here and not in the 'new' method so that we can refer to 'service' & 'params' in the exception thrown) 
		$self->{proxy}->on_fault(
			 sub {
				my $soap = shift;
				my $wsResult = shift;	

				chomp( my $err = $soap->transport->status );
				if ( $err =~ m/\b200\b/) {
					#-- the HTTP return code is a success, but an error was raised
					#-- => error during XML parsing of answer is suspected => raise a 'WScalls' exception
					my $parseErrorCode = -1;
					my $parseError = 'Unknown error';
					if ($wsResult =~ m/(not well-formed [^\/]+ at \/.*\/XML\/Parser.pm)/) {
						$parseError = 'XML parsing error: ' . $1;
					}
				}
				return new SOAP::SOM;
			 } );
		#-- call the service
		my $wsResult = $self->{proxy}->call($service, $params);
		#print Dumper($self->{proxy}->{_deserializer}->{_ids});
		#print Dumper($wsResult);
		#print Dumper($wsResult->result->{attachments});
		#
	    	#-- return the result of the WS call
    		return $wsResult;
	}
}

1;

