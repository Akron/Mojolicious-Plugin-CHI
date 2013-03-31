package Mojolicious::Plugin::CHI;
use Mojo::Base 'Mojolicious::Plugin';
use CHI;

our $VERSION = '0.07';

# Register Plugin
sub register {
  my ($plugin, $mojo, $param) = @_;

  # Add 'chi' command
  push @{$mojo->commands->namespaces}, __PACKAGE__;

  # Load parameter from Config file
  if (my $config_param = $mojo->config('CHI')) {
    $param = { %$config_param, %$param };
  };

  # Hash of cache handles
  my $caches;

  # Add 'chi_handles' attribute
  unless ($mojo->can('chi_handles')) {
    $mojo->attr(
      chi_handles => sub {
	return $caches;
      }
    );
  }

  else {
    $mojo->chi_handles($caches);
  };

  # Support namespaces
  my $ns = delete $param->{namespaces} // 1;

  # Loop through all caches
  foreach my $name (keys %$param) {
    my $cache_param = $param->{$name};

    # Already exists
    if (exists $caches->{$name}) {
      $mojo->log->warn("Multiple attempts to establish cache '$name'");
      next;
    };

    # Set namespace
    if ($ns) {
      $cache_param->{namespace} //= $name unless $name eq 'default';
    };

    # Get CHI handle
    my $cache = CHI->new( %$cache_param );

    # No succesful creation
    unless ($cache) {
      $mojo->log->warn("Unable to create cache handle '$name'");
    };

    # Store CHI handle
    $caches->{$name} = $cache;
  };


  # Add 'chi' helper
  $mojo->helper(
    chi => sub {
      my $c = shift;
      my $name = shift // 'default';

      my $cache = $caches->{$name};

      # Cache unknown
      $mojo->log->warn("Unknown cache handle '$name'") unless $cache;

      # Return cache
      return $cache;
    });

  # Add 'chi_ua' helper
  $mojo->helper(
    chi_ua => sub {
      shift;
      my $ua = Mojo::UserAgent->new;
      my %param = @_;

      # LWP::UserAgent::Cached
      # LWP::UserAgent::Cache::Memcached
      # LWP::UserAgent::WithCache

      my $support;
      my $headers = $c->req->headers;
      if ($param{with}) {
	foreach (sort cmp @{$param{with}}) {
	  $support .= $_  ': ' . $headers->{$_} . "\n" if exists $headers->{$_};
	};
      }
      elsif ($param{without}) {
	$headers = $headers->clone;
	foreach (@{$param{without}}) {
	  delete $headers->{$_};
	};
	foreach (sort cmp keys %{$headers}) {
	  $support .= $_  ': ' . $headers->{$_} . "\n";
	};
      };

      # Method
      # URL
      # Param (sorted)

      # Do not cache in case of accept_ranges

      # Session is in Cookie
      # Default support:
      # accept
      # accept_charset
      # accept_encoding
      # accept_language
      # accept_ranges
      # transfer_encoding

      # Without:
      # date
      # dnt

      # How about: expires, e-tag, if-modified-since

      # Use MOJO_USERAGENT_DEBUG

      # Information:
      # - no_cache_if => sub { ... }
      # - recache_if => sub { ... }
      # - on_uncached => sub { ... }

      my $seconds;

      # Get information from cache_control
      if (my $age = $headers->cache_control) {
	if ($age =~ s/max-age\s*(\d+)/$1/i) {
	  $seconds = $age;
	};
      }

      # Get information from expires header
      elsif (my $expires = $headers->expires) {
	if ($expires = Mojo::Date->new($expires)) {
	  $seconds = $expires - time;
	}
      };

      # ...
    }
  );

  # Add 'chi' shortcut
  $mojo->routes->add_shortcut(
    chi => sub {
      my $r = shift;
      my %param = @_;

      # Add bridge
      # Generate E-Tag
      # - Render from cache, if existing
      # - Support full path
      # - Support param
      # - Support chosen headers
      # otherwise
      # - Add E-Tag
      # - Add X-Cache-Header

      # If shortcut once established,
      # add hook for Caching
      # Save Response based on E-Tag

      # ->chi(default => {
      #    header => ['Session'],
      #    session => []}
      # )->to()
      # Or
      # ->chi_to(cb => sub {}, chi => {})
      # This would only work, if this is an endpoint
    }
  );
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::CHI - Use CHI caches in Mojolicious


=head1 SYNOPSIS

  # Mojolicious
  $app->plugin(CHI => {
    MyCache => {
      driver     => 'FastMmap',
      root_dir   => '/cache',
      cache_size => '20m'
    }
  });

  # Mojolicious::Lite
  plugin 'CHI' => {
    default => {
      driver => 'Memory',
      global => 1
    }
  };

  # In Controllers:
  $c->chi('MyCache')->set(my_key => 'This is my value');
  print $c->chi('MyCache')->get('my_key');

  # Using the default cache
  $c->chi->set(from_memory => 'With love!');
  print $c->chi->get('from_memory');


=head1 DESCRIPTION

L<Mojolicious::Plugin::CHI> is a simple plugin to work with
L<CHI> caches within Mojolicious.


=head1 METHODS

=head2 register

  # Mojolicious
  $app->plugin(CHI => {
    MyCache => {
      driver     => 'FastMmap',
      root_dir   => '/cache',
      cache_size => '20m'
    },
    default => {
      driver => 'Memory',
      global => 1
    },
    namespaces => 1
  });

  # Mojolicious::Lite
  plugin 'CHI' => {
    default => { driver => 'Memory', global => 1 }
  };

  # Or in your config file
  {
    CHI => {
      default => {
        driver => 'Memory',
        global => 1
      }
    }
  }

Called when registering the plugin.
On creation, the plugin accepts a hash of cache names
associated with L<CHI> objects.

All cache handles are qualified L<CHI> namespaces.
You can omit this mapping by passing a C<namespaces>
parameter with a C<false> value.

The handles have to be unique, i.e.
you can't have multiple different C<default> caches in mounted
applications using L<Mojolicious::Plugin::Mount>.

All parameters can be set either on registration or
as part of the configuration file with the key C<CHI>.


=head1 HELPERS

=head2 chi

  # In Controllers:
  $c->chi('MyCache')->set(my_key => 'This is my value', '10 min');
  print $c->chi('MyCache')->get('my_key');
  print $c->chi->get('from_default_cache');

Returns a L<CHI> handle if registered.
Accepts the name of the registered cache.
If no cache handle name is given, a cache handle name
C<default> is assumed.


=head1 COMMANDS

=head2 chi list

  perl app.pl chi list

List all chi caches associated with your application.

=head2 chi purge

  perl app.pl chi purge 'mycache'

Remove all expired entries from the cache namespace.

=head2 chi clear

  perl app.pl chi clear 'mycache'

Remove all entries from the cache namespace.

=head2 chi expire

  perl app.pl chi expire 'mycache' 'mykey'

Set the expiration date of a key to the past.
This does not necessarily delete the data.

=head2 chi remove

  perl app.pl chi remove 'mycache' 'mykey'

Remove a key from the cache.


=head1 DEPENDENCIES

L<Mojolicious>,
L<CHI>.

B<Note:> L<CHI> has a lot of dependencies. It is
thus not recommended to use this plugin in a CGI
environment.


=head1 CONTRIBUTORS

L<Boris Däppen|https://github.com/borisdaeppen>

L<reneeb|https://github.com/reneeb>


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-CHI


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
