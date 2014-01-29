use strict;
use warnings;
package Email::MIME::Header;
# ABSTRACT: the header of a MIME message

use parent 'Email::Simple::Header';

use Email::MIME::Encode;
use Encode 1.9801;

=head1 DESCRIPTION

This object behaves like a standard Email::Simple header, with the following
changes:

=for :list
* the C<header> method automatically decodes encoded headers if possible
* the C<header_raw> method returns the raw header; (read only for now)
* stringification uses C<header_raw> rather than C<header>

Note that C<header_set> does not do encoding for you, and expects an
encoded header.  Thus, C<header_set> round-trips with C<header_raw>,
not C<header>!  Be sure to properly encode your headers with
C<Encode::encode('MIME-Header', $value)> before passing them to
C<header_set>.

Alternately, if you have Unicode (character) strings to set in headers, use the
C<header_str_set> method.

=cut

sub header {
  my $self   = shift;
  my @header = $self->SUPER::header(@_);
  local $@;
  foreach my $header (@header) {
    next unless defined $header;
    next unless $header =~ /=\?/;
    $header = $self->_header_decode_str($header);
  }
  return wantarray ? (@header) : $header[0];
}

sub header_raw {
  Carp::croak "header_raw may not be used to set headers" if @_ > 2;
  my ($self, $header) = @_;
  return $self->SUPER::header($header);
}

sub header_str_set {
  my ($self, $name, @vals) = @_;

  my @values = map {
    Email::MIME::Encode::maybe_mime_encode_header($name, $_, 'UTF-8')
  } @vals;

  $self->header_set($name => @values);
}

sub _header_decode_str {
  my ($self, $str) = @_;
  my $new_str;
  $new_str = $str
    unless eval { $new_str = Encode::decode("MIME-Header", $str); 1 };
  return $new_str;
}

1;
