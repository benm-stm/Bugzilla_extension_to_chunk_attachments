package Corp::Base;

use Carp;

our $AUTOLOAD;

my %fields = (
	myname => undef,
);

sub new {
	my ($class, $myname) = @_;
	my $self = {};
	$self->{_permitted} = {};
	bless $self, $class;
	$self->{myname} = $myname;
	return $self;
}

#
# AUTOLOAD - Handle automatic methods
#
sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) or croak "$self is not an object";
	
	my $name = $AUTOLOAD;
	$name =~ s/.*://; # Strip fully-qualified portion
	return if $name eq 'DESTROY';
	
	unless (exists $self->{_permitted}->{$name}) {
		croak "Can't access '$name' field in class $type";
	}
	
	if (@_) {
		return $self->{$name} = shift;
	}
	else {
		return $self->{$name};
	}
}

1;

__END__

################ Documentation ################

=pod

=head1 NAME

Corp::Base - A generic base class

=head1 SYNOPSIS

 package MyPackage;
 
 use base (Corp::Base);
  
  my %fields = (
	field1 => 1,
	field2 => 'foo',
 );
 
 sub new {
	my ($class) = @_;
	my $self  = $class->SUPER::new();
	foreach my $element (keys %fields) {
		$self->{_permitted}->{$element} = $fields{$element};
	}
	@{$self}{keys %fields} = values %fields;
		return $self;
 }

 my $x = new MyPackage();
 my $p1 = $x->field1();
 $x->field2('bar');

=head1 DESCRIPTION

The Corp::Base module implements a simple base class relying on recommendations
defined in the I<perltoot> manpage (Tom's object-oriented tutorial for perl).

=head1 CLASS VARIABLE

=over 4

=item C<%fields>

Hash of permitted fields. Fields defined in this hash can be accessed using dedicated 
accessor methods provided by the C<AUTOLOAD> proxy method.
This variable may (and actually I<should>) be overriden in sub-classes.

=back

=head1 METHODS

=over 4

=item C<new>

This method creates a new object.

=item C<AUTOLOAD>

This proxy method handles calls to data access methods. Only fields defined in
the C<%fields> hash may be accessed this way.
It is therfore possible to get and set fields values as follows:

 # Set value 234 to field field1
 $x->field1(234);

 # Get value of field field1
 $y = $x->field1();

=back

=head1 AUTHOR

=over 4

S<Philippe ChahwE<eacute>kilian (ELSYS Design SA)><olivier.cheron@st.com>

=back

=head1 COPYRIGHT

=over 4

Copyright 2009 by ST.

=back

=cut
