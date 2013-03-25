package Mojolicious::Plugin::CHI::chi;
use Mojo::Base 'Mojolicious::Command';

use Getopt::Long qw/GetOptions :config no_auto_abbrev no_ignore_case/;

has description => "Interact with CHI caches.\n";
has usage       => <<"EOF";
usage: $0 chi [command] [cache] [key]

  perl app.pl chi list
  perl app.pl chi purge
  perl app.pl chi clear 'mycache'
  perl app.pl chi expire 'mykey'
  perl app.pl chi remove 'mycache' 'mykey'

Interact with CHI caches associated with your application.
Valid commands are ..

  list
    List all chi caches associated with your application.

  purge [cache]
    Remove all expired entries from the cache namespace.

  clear [cache]
    Remove all entries from the cache namespace.

  expire [cache] [key]
    Set the expiration date of a key to the past.
    This does not necessarily delete the data.

  remove [cache] [key]
    Remove a key from the cache

"purge" and "expire" expect a cache namespace as their only argument.
If no cache namespace is given, the default cache namespace is assumed.

"expire" and "remove" expect a cache namespace and a key name as their
arguments. If no cache namespace is given, the default cache
namespace is assumed.


EOF


# Run chi
sub run {
  my $self = shift;

  my $command = shift;

  unless ($command) {
    print $self->usage and return;
  };

  # Get the application
  my $app = $self->app;

  # Check the given command
  given ($command) {

    # List all associated caches
    when ('list') {
      my $caches = $app->can('chi_handles') ? $app->chi_handles : {};
      foreach (keys %$caches) {
	printf("  %-16s %-20s\n", $_, ($caches->{$_}->{driver_class} || '[UNKNOWN]'));
      };
      return 1;
    }

    # Purge or clear a cache
    when (['purge', 'clear']) {
      my $cache = $_[0] || 'default';

      # Purge or clear cache
      if ($app->chi($_[0])->$command()) {
	print qq{Cache "$cache" was } . $command . ($command eq 'clear' ? 'ed' : 'd') . ".\n\n";
      }

      # Not successful
      else {
	print 'Unable to ' . $command . qq{ cache "$cache".\n\n};
      };

      return 1;
    }

    # Remove or expire a key
    when (['remove', 'expire']) {
      my $key   = pop(@_);
      my $cache = $_[0] || 'default';

      if ($key) {

	# Remove or expire key
	if ($app->chi($_[0])->$command($key)) {
	  print qq{Key "$key" from cache "$cache" was } . $command . "d.\n\n";
	}

	# Not successful
	else {
	  print 'Unable to ' . $command . qq{ key "$key" from cache "$cache".\n\n};
	};

	return 1;
      };
    }
  };

  # Unknown command
  print $self->usage;

  return;
};


1;


__END__

=pod

=head1 NAME

Mojolicious::Plugin::CHI::chi - Interact with CHI caches

=head1 SYNOPSIS

  use Mojolicious::Plugin::CHI::chi;

  my $chi = Mojolicious::Plugin::CHI::chi->new;
  $chi->run;

Command line usage:

  perl app.pl chi list
  perl app.pl chi purge
  perl app.pl chi clear 'mycache'
  perl app.pl chi expire 'mykey'
  perl app.pl chi remove 'mycache' 'mykey'


=head1 DESCRIPTION

L<Mojolicious::Plugin::CHI::chi> helps you to interact with
caches associated with L<Mojolicious::Plugin::CHI>.

=head1 ATTRIBUTES

L<Mojolicious::Plugin::CHI::chi> inherits all attributes
from L<Mojolicious::Command> and implements the following new ones.

=head2 C<description>

  my $description = $chi->description;
  $chi = $chi->description('Foo!');

Short description of this command, used for the command list.

=head2 C<usage>

  my $usage = $chi->usage;
  $chi = $chi->usage('Foo!');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Plugin::CHI::chi> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 C<run>

  $chi->run;

Run this command.


=head1 DEPENDENCIES

L<Mojolicious>,
L<CHI>.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-CHI


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, L<Nils Diewald||http://nils-diewald.de>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

The documentation is based on L<Mojolicious::Command::eval>,
written by Sebastian Riedel.

=cut
