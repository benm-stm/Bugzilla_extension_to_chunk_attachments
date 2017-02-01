# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

package Bugzilla::Extension::WSChunked::WebService;

use Bugzilla::Constants;
use File::Path qw(rmtree);
use parent qw(Bugzilla::WebService::Bug);
use Bugzilla::WebService::Util qw(validate);
use Bugzilla::Error;
use constant PUBLIC_METHODS => qw(
    attachments
    chunk
    add_chunk
);

#This part was added to force values when the admin params are not introduced
my $WSC_chunk_path;
my $WSC_chunk_size;

if (Bugzilla->params->{'WSC_chunk_size'} eq '') {
    $WSC_chunk_size = "7";
} else {
    $WSC_chunk_size = Bugzilla->params->{'WSC_chunk_size'};
}
if (Bugzilla->params->{'WSC_chunk_path'} eq '') {
    $WSC_chunk_path = "/tmp/bugzila_WSchunked";
} else {
    $WSC_chunk_path = Bugzilla->params->{'WSC_chunk_path'};
}

=cut
  name    attachments
  desc    split the attachment which is extracted from bugzilla given its ID
          into chunks and save them in the given FS (as admin param).

  @param  $attachment_ids       INT     : ID of the given attachment

  @return %attach_chunks        HASH    : hash containing attachment infos + number of chunks
=cut
sub attachments {
    my ($self, $params) = validate(@_, 'ids', 'attachment_ids');
    my %attach_chunks;

    Bugzilla->switch_to_shadow_db();

    if (!(defined $params->{ids}
          or defined $params->{attachment_ids}))
    {
        ThrowCodeError('param_required',
                       { function => 'WSChunked.attachments',
                         params   => ['ids', 'attachment_ids'] });
    }

    my $ids = $params->{ids} || [];
    my $attach_ids = $params->{attachment_ids} || [];

    my %bugs;
    foreach my $bug_id (@$ids) {
        my $bug = Bugzilla::Bug->check($bug_id);
        $bugs{$bug->id} = [];
        foreach my $attach (@{$bug->attachments}) {
            push @{$bugs{$bug->id}},
                $self->_attachment_to_hash($attach, $params);
        }
    }

    my %attachments;
    foreach my $attach (@{Bugzilla::Attachment->new_from_list($attach_ids)}) {
        Bugzilla::Bug->check($attach->bug_id);
        if ($attach->isprivate && !Bugzilla->user->is_insider) {
            ThrowUserError('auth_failure', {action    => 'access',
                                            object    => 'attachment',
                                            attach_id => $attach->id});
        }

        $attachments{$attach->id} =
            $self->_attachment_to_hash($attach, $params);

                my $data = $attach->{data};

                my ($nb_chunks, @chunks) = split2Chunks($data, $WSC_chunk_size);
                $attach_chunks{$attach->id}->{nb_chunks} = $nb_chunks;
                $attach_chunks{$attach->id}->{file_name} = $attachments{$attach->id}->{file_name};
                $attach_chunks{$attach->id}->{summary} = $attachments{$attach->id}->{summary};
                $attach_chunks{$attach->id}->{content_type} = $attachments{$attach->id}->{content_type};
                $attach_chunks{$attach->id}->{is_patch} = $attachments{$attach->id}->{is_patch};
                $attach_chunks{$attach->id}->{creation_time} = $attachments{$attach->id}->{creation_time};
                $attach_chunks{$attach->id}->{creator} = $attachments{$attach->id}->{creator};

                for my $i (0 .. $#chunks)
                {
                        save2Files($attach->id, "to_be_sent", $chunks[$i], $i);
                }
    }

        #Send number of chunks and attachment's ID
        return {attach_chunks => \%attach_chunks};

}

=cut
  name    chunk
  desc    Will be called as a Web service, its main purpose is to read the chunk
          given by its id and return it to the caller

  @param  $attachment_id        INT     : ID of the given attachment
          $chunk_id             INT     : ID of the given chunk

  @return %attach_chunk         HASH    : chunk content and attachment ID
=cut
sub chunk {
        my ($self, $params) = validate(@_, 'ids', 'attachment_id', 'chunk_id', 'last_chunk');

        Bugzilla->switch_to_shadow_db();

    if (!(defined $params->{ids}
          or defined $params->{attachment_id}
          or defined $params->{last_chunk}
          or defined $params->{chunk_id}))
    {
        ThrowCodeError('param_required',
                       { function => 'WSChunked.chunk',
                         params   => ['ids', 'attachment_id', 'chunk_id', 'last_chunk'] });
    }

    my $attach_id = $params->{attachment_id};
    my $chunk_id = $params->{chunk_id};
    my $last_chunk = $params->{last_chunk};

        my %attach_chunk;
        my $data;

        #used to sanitize the input (bypass tainted)
    if ($$attach_id[0] =~ m/(.*)/i) {
                $untainted_attach_id = $1;
        }
        if ($$chunk_id[0] =~ m/(.*)/i) {
                $untainted_chunk_id = $1;
        }
        if ($$last_chunk[0] =~ m/(.*)/i) {
                $untainted_last_chunk = $1;
        }

        my $dir = $WSC_chunk_path.'/to_be_sent/'.$untainted_attach_id;

        my $filename = $dir.'/'.$untainted_chunk_id;
        open(my $fh, '<', $filename) or die "cannot open file $filename";
    {
        local $/;
        $data = <$fh>;
    }
    close($fh);

    if($untainted_chunk_id == $untainted_last_chunk) {
                cleanup($untainted_attach_id, 'to_be_sent');
        }

    $attach_chunk{data} = $data;
    $attach_chunk{attachment_id} = $untainted_attach_id;
    return {attach_chunk => \%attach_chunk};
}

=cut
  name    add_chunk
  desc    Will be called as a Web service, its main purpose is to get attachment
                  fields, and chunk and store it under received dir to reconstruct it later
                  and inject it inti bugzilla's main instance

  @param  $attachment_id                INT     : ID of the given attachment
                  $chunk                BLOB    : Chunk content
                  $chunk_id             INT     : ID of the given chunk
                  $last_chunk           INT     : last chunk of the splitted attachment
                  $file_name            String  : attachment name
                  $summary              String  : attachment summary
                  $content_type         String  : attachment content_type
                  $is_patch             String  : attachment specific field
                  $comment              String  : attachment comment
                  $is_private           String  : attachment specific field

  @return NONE
=cut
sub add_chunk {

        my ($self, $params) = validate(@_, 'ids', 'attachment_id', 'chunk', 'chunk_id',
                                      'last_chunk', 'file_name', 'summary', 'content_type',
                                      'is_patch', 'comment', 'is_private');
        my $created_ids;

        Bugzilla->switch_to_shadow_db();

        if (!(defined $params->{ids}
          or defined $params->{attachment_id}
          or defined $params->{chunk}
          or defined $params->{last_chunk}
          or defined $params->{chunk_id}))
    {
        ThrowCodeError('param_required',
                       { function => 'WSChunked.chunk',
                         params   => ['ids', 'attachment_id', 'chunk', 'chunk_id', 'last_chunk'] });
    }

    my $attach_id = $params->{attachment_id};
    my $chunk = $params->{chunk};
    my $chunk_id = $params->{chunk_id};
    my $last_chunk = $params->{last_chunk};
    my $file_name = $params->{file_name};
    my $summary = $params->{summary};
    my $content_type = $params->{content_type};
    my $is_patch = $params->{is_patch};
    my $comment = $params->{comment};
    my $remoteTicketID = $params->{ids};
    my $is_private = $params->{is_private};

    my $untainted_attach_id;
    my $untainted_chunk_id;
    my $untainted_last_chunk;
    my $untainted_file_name;
    my $untainted_summary;
    my $untainted_content_type;
    my $untainted_is_patch;
    my $untainted_comment;
    my $untainted_is_private;
    my $untainted_remoteTicketID;

    #used to sanitize the input (bypass tainted)
    if ($$remoteTicketID[0] =~ m/(.*)/i) {
                $untainted_remoteTicketID = $1;
        }

        if ($$attach_id[0] =~ m/(.*)/i) {
                $untainted_attach_id = $1;
        }

    if ($$chunk_id[0] =~ m/(.*)/i) {
                $untainted_chunk_id = $1;
        }

    if ($$last_chunk[0] =~ m/(.*)/i) {
                $untainted_last_chunk = $1;
        }

        if ($$file_name[0] =~ m/(.*)/i) {
                $untainted_file_name = $1;
        }

        if ($$summary[0] =~ m/(.*)/i) {
                $untainted_summary = $1;
        }

        if ($$content_type[0] =~ m/(.*)/i) {
                $untainted_content_type = $1;
        }

        if ($$is_patch[0] =~ m/(.*)/i) {
                $untainted_is_patch = $1;
        }

        if ($$comment[0] =~ m/(.*)/i) {
                $untainted_comment = $1;
        }

        if ($$is_private[0] =~ m/(.*)/i) {
                $untainted_is_private = $1;
        }

    save2Files($untainted_attach_id, "received", $$chunk[0], $untainted_chunk_id);

    if ($untainted_last_chunk == $untainted_chunk_id) {
                regroup_chunks($untainted_attach_id, $untainted_last_chunk);

                my $dir = $WSC_chunk_path.'/received/'.$untainted_attach_id.'/'.$untainted_attach_id;
                my $data;

                open(my $fh, '<', $dir) or die "cannot open file $dir";
                {
                        local $/;
                        $data = <$fh>;
                }
                close($fh);

                $created_ids = inject_data($untainted_attach_id, $untainted_file_name, $untainted_summary, $untainted_content_type,
                                           $untainted_is_patch, $untainted_comment,$untainted_is_private, $data, [$untainted_remoteTicketID]);

                cleanup($untainted_attach_id, 'received');
        }
        return { ids => $created_ids };
}

=cut
  name    split2Chunks
  desc    split the given data into chunks using the unpack methode given the size of the chunk in Mb

  @param  $data         BLOB    : ID of the given attachment
          $sizeInMb     FLOAT   : folder under which we're gonna seve the chunks

  @return $nb_chunks    INT     : number of splitted chunks
          @chunks       ARRAY   : chunks array
=cut
sub split2Chunks {
        my($data, $sizeInMb) = @_;
        my $sizeInMb = int(1024*1024*$sizeInMb);    # transorm demanded size to byte

        if(length($data)> $sizeInMb) {
                my $nb_chunks = 0;
                my @chunks = unpack "a$sizeInMb" x (length( $data ) /$sizeInMb ), $data;
                $nb_chunks = $#chunks+1;
                my $already_chunked = "";
                for my $i (0 .. $#chunks)
                {
                        $already_chunked .= $chunks[$i];
                }
                if(length($data) > length($already_chunked)) {
                        $nb_chunks += 1;
                        my $last_chunk = substr($data, length($already_chunked), length($data));
                        push(@chunks, $last_chunk);
                }
                return ($nb_chunks, @chunks);
        }
        return (1, $data);
}

=cut
  name    save2Files
  desc    save the input content into the FS which is given in params in bugzilla administration attachment panel

  @param  $idAttachment INT     : ID of the given attachment
          $opType       STRING  : folder under which we're gonna seve the chunks
          $chunk        BLOB    : Chunk content
          $chunk_id     INT     : ID of the given chunk

  @return NONE
=cut
sub save2Files {
        my($idAttachment, $opType, $chunk, $chunk_id) = @_;

        #create bugzilla temp dir
        my $dir = $WSC_chunk_path;
        mkdir $dir unless -d $dir; # Check if dir exists. If not create it.

        #create operation dir
        $dir = $WSC_chunk_path.'/'.$opType;
        mkdir $dir unless -d $dir; # Check if dir exists. If not create it.

        #create attachment dir
        $dir = $dir.'/'.$idAttachment;
        mkdir $dir unless -d $dir; # Check if dir exists. If not create it.

        my $filename = $dir.'/'.$chunk_id;
        open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
        print $fh $chunk;
        close $fh;
}

=cut
  name    regroup_chunks
  desc    gonna read chunks in the local FS and regroup them in 1 file
                  having as name the attachment ID.

  @param  $attach_id            INT     : ID of the given attachment
                  $chunk_nbr            INT             : Number of chunks

  @return NONE
=cut
sub regroup_chunks {
        my($attach_id, $chunk_nbr) = @_;
        my $data;
        my $dir = $WSC_chunk_path.'/received/'.$attach_id;

        for my $i (0 .. $chunk_nbr)
        {

                open(my $fh, '<', $dir.'/'.$i) or die "cannot open file $dir/$i";
                {
                        local $/;
                        $data = <$fh>;
                }
                close($fh);

                open(my $fh, '>>', $dir.'/'.$attach_id) or die "Could not open file $dir.'/'.$attach_id $!";
                print $fh $data;
        }
        close $fh;
}

=cut
  name    inject_data
  desc    add attachment to bugzilla

  @param  $attach_id            INT     : ID of the given attachment
          $file_name            String  : attachment name
          $summary              String  : attachment summary
          $content_type         String  : attachment content_type
          $is_patch             String  : attachment specific field
          $comment              String  : attachment comment
          $is_private           String  : attachment specific field
          $data                 BLOB    : attachment content
          $ids                  INT     : bugs IDs

  @return @created_ids          ARRAY   : created attachment IDs
=cut
sub inject_data {
        my($attach_id, $file_name, $summary, $content_type, $is_patch, $comment, $is_private, $data, $ids ) = @_;
    my $dbh = Bugzilla->dbh;

        Bugzilla->login(LOGIN_REQUIRED);
        defined $ids
        || ThrowCodeError('param_required', { $ids });
    defined $data
        || ThrowCodeError('param_required', { $data });
        $data ne ""
        || ThrowCodeError('zero_length_file');
    my @bugs = map { Bugzilla::Bug->check_for_edit($_) } @{ $ids };

    my @created;
    $dbh->bz_start_transaction();
    my $timestamp = $dbh->selectrow_array('SELECT LOCALTIMESTAMP(0)');

    my $flags = delete $params->{flags};

    foreach my $bug (@bugs) {
        my $attachment = Bugzilla::Attachment->create({
            bug         => $bug,
            creation_ts => $timestamp,
            data        => $data,
            description => $summary,
            filename    => $file_name,
            mimetype    => $content_type,
            ispatch     => $is_patch,
            isprivate   => $is_private,
        });

        if ($flags) {
            my ($old_flags, $new_flags) = extract_flags($flags, $bug, $attachment);
            $attachment->set_flags($old_flags, $new_flags);
        }

        $attachment->update($timestamp);
        my $comment = $comment || '';
        $attachment->bug->add_comment($comment,
            { isprivate  => $attachment->isprivate,
              type       => CMT_ATTACHMENT_CREATED,
              extra_data => $attachment->id });
        push(@created, $attachment);
    }

    $_->bug->update($timestamp) foreach @created;
    $dbh->bz_commit_transaction();

    $_->send_changes() foreach @bugs;

    my @created_ids = map { $_->id } @created;

    return \@created_ids;
}

=cut
  name    cleanup
  desc    delete operations folder and its subtree in the end of the operation

  @param  $attach_id    INT     : ID of the given attachment
          $opType       STRING  : folder under which there are c

  @return NONE
=cut
sub cleanup {
        my($attach_id, $optype) = @_;

        my $deletedir = $WSC_chunk_path.'/'.$optype.'/'.$attach_id;
        rmtree($deletedir);
}

1;
