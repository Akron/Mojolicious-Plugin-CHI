#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::CHI',
  VERSION_FROM => 'lib/Mojolicious/Plugin/CHI.pm',
  ABSTRACT     => 'Use CHI Caches in Mojolicious',
  AUTHOR       => 'Nils Diewald',
  BUILD_REQUIRES => {
    'Test::More' => 0,
    'Test::Output' => 1.0
  },
  PREREQ_PM => {
    'Mojolicious' => 4.77,
    'CHI'         => 0
  },
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/Akron/Mojolicious-Plugin-CHI'
    }
  },
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);
