# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

package Bugzilla::Extension::WSChunked;

use strict;
use warnings;

use parent qw(Bugzilla::Extension);

our $VERSION = '1.0';

use Bugzilla::Config::Common;

use constant WSC_CHUNK_SIZE_DEFAULT => '7';
use constant WSC_CHUNK_PATH_DEFAULT => '/tmp/bugzila_WSchunked';

sub webservice {
    my ($self, $args) = @_;
    my $dispatch = $args->{dispatch};
    $dispatch->{WSChunked} = "Bugzilla::Extension::WSChunked::WebService";
}

#-- add a new Bugzilla configuration parameters to the 'attachment' tab
sub config_modify_panels {
    my ( $self, $args ) = @_;
    my $panels         = $args->{panels};
    my $attachment_params = $panels->{'attachment'}->{params};

    #-- add a WSChunk parameter to store chunk size
    push(
        @$attachment_params,
            {
                name    => 'WSC_chunk_size',
                type    => 't',
                default => WSC_CHUNK_SIZE_DEFAULT,
                checker => \&check_regexp
            }
    );

    #-- add a WSChunk parameter to store chunks path
    push(
        @$attachment_params,
            {
                name    => 'WSC_chunk_path',
                type    => 't',
                default => WSC_CHUNK_PATH_DEFAULT,
                checker => \&check_regexp
            }
        );
}

# This must be the last line of your extension.
__PACKAGE__->NAME;
