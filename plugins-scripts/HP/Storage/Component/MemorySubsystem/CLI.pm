package HP::Storage::Component::MemorySubsystem::CLI;
our @ISA = qw(HP::Storage::Component::MemorySubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    dimms => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  my %params = @_;
  $self->{dimms} = [];
  my %tmpdimm = (
    runtime => $params{runtime},
  );
  my $inblock = 0;
  foreach (grep(/^dimm/, split(/\n/, $self->{rawdata}))) {
    s/^dimm\s*$//g;
    if (/Cartridge #:\s+(\d+)/) {
      $tmpdimm{cartridge} = $1;
      $tmpdimm{board} = $1;
      $inblock = 1;
    } elsif (/Module #:\s+(\d+)/) {
      $tmpdimm{module} = $1;
    } elsif (/Present:\s+(\w+)/) {
      $tmpdimm{status} = lc $1 eq 'yes' ? 'present' :
          lc $1 eq 'no' ? 'notpresent' : 'other';
    } elsif (/Status:\s+(.+?)\s*$/) {
      $tmpdimm{condition} = lc $1 =~ /degraded/ ? 'degraded' :
          lc $1 eq 'ok' ? 'ok' : lc $1 =~ /n\/a/ ? 'n/a' : 'other';
    } elsif (/Size:\s+(\d+)\s*(.+?)\s*$/) {
      $tmpdimm{size} = $1 * (lc $2 eq 'mb' ? 1024*1024 :
          lc $2 eq 'gb' ? 1024*1024*1024 : 1);
    } elsif (/^\s*$/) {
      if ($inblock) {
        $inblock = 0;
        push(@{$self->{dimms}},
            HP::Storage::Component::MemorySubsystem::Dimm->new(%tmpdimm));
        %tmpdimm = (
          runtime => $params{runtime},
        );
      }
    }
  }
  if ($inblock) {
    push(@{$self->{dimms}},
        HP::Storage::Component::MemorySubsystem::Dimm->new(%tmpdimm));
  }
}

sub is_faulty {
  my $self = shift;
  return 0; # cli hat so einen globalen status nicht
}

1;
