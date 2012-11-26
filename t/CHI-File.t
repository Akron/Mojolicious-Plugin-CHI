#!/usr/bin/env perl
use Mojolicious::Lite;
use Test::More tests => 5;
use Test::Mojo;
use File::Temp qw/:POSIX tempdir/;

$|++;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::CHI';

my $t = Test::Mojo->new;
my $app = $t->app;

my $c = Mojolicious::Controller->new;
$c->app($app);

my $path = tempdir(CLEANUP => 1);

$app->plugin(CHI => {
  MyCache2 => {
    driver => 'File',
    root_dir => $path
  },
  namespaces => 1
});

$c = Mojolicious::Controller->new;
$c->app($app);

Mojo::IOLoop->start;

my $my_cache = $c->chi('MyCache2');
ok($my_cache, 'CHI handle');
ok($my_cache->set(key_1 => 'Wert 1'), 'Wert 1');
is($my_cache->get('key_1'), 'Wert 1', 'Wert 1');

opendir(D, $path);
my @test = readdir(D);
closedir(D);

ok('MyCache2' ~~ \@test, 'Namespace option valid');
