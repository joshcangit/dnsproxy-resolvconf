#!/usr/bin/env perl
use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use File::Spec;
eval {
  require YAML::PP;
  'YAML::PP'->import();
}
or do {
  require YAML::XS;
  'YAML::XS'->import('LoadFile');
};

exit 0 if (! @ARGV);

my $yaml_file = "/etc/adguard/dnsproxy.yml";
my $yaml;

SWITCH: {
  if ($INC{'YAML/PP.pm'}) {
    my $ypp = YAML::PP->new;
    $yaml = $ypp->load_file($yaml_file);
    undef $ypp;
    last SWITCH;
  }
  if ($INC{'YAML/XS.pm'}) {
    $yaml = LoadFile($yaml_file);
    last SWITCH;
  }
  my $nothing = 1;
}

my @listen = @{ $yaml->{'listen-addrs'} };
my @conf = map { "nameserver $_$/"; } @listen;
@conf = (@conf, "options edns0$/");

sub file_io {
  my ($opt, $file, @lines) = @_;
  open FH, $opt, $file or die "Can't open ${file}:\n$!";
  SWITCH:
  for ($opt) {
    if (/^</) {
      return <FH>;
      last SWITCH;
    }
    if (/^>/) {
      print FH @lines;
      last SWITCH;
    }
  }
  close FH;
  system("resolvconf -u");
}

my $resolv_file = "/etc/resolvconf/resolv.conf.d/head";
my @resolv = file_io("<:encoding(utf8)", $resolv_file);
my $dnsproxy = File::Spec->catfile(dirname(abs_path(__FILE__)), "dnsproxy");

SWITCH:
for ($ARGV[0]) {
  if (/^start$/) {
    my %resolv = map {$_=>1} @resolv;
    my @new_conf = grep { !$resolv{$_} } @conf;
    if (@new_conf) {
      file_io(">>:encoding(utf8)", $resolv_file, @new_conf);
      system("${dnsproxy} --config-path=${yaml_file}");
    }
    last SWITCH;
  }
  if (/^stop$/) {
    my %conf = map {$_=>1} @conf;
    my @new_conf = grep { !$conf{$_} } @resolv;
    if (@new_conf != @resolv) {
      system("killall -9 ${dnsproxy}");
      file_io(">:encoding(utf8)", $resolv_file, @new_conf);
    }
    last SWITCH;
  }
  my $nothing = 1;
}
