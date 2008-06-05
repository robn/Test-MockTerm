package Test::MockTerm;

use 5.008;

our $VERSION = '0.01';

use warnings;
use strict;

use Symbol ();
use Carp;
use Tie::Handle;

sub new {
    my ($class, @args) = @_;

    my $self = bless { }, $class;

    my $master = Symbol::gensym;
    tie *$master, "Test::MockTerm::Master", $self;

    my $slave = Symbol::gensym;
    tie *$slave, "Test::MockTerm::Slave", $self;

    $self->{master} = $master;
    $self->{slave} = $slave;

    return $self;
}

sub DESTROY {
    my ($self) = @_;
    untie *{$self->{master}};
    delete $self->{master};
    untie *{$self->{slave}};
    delete $self->{slave};
}

sub master {
    my ($self) = @_;

    return $self->{master};
}

sub slave {
    my ($self) = @_;

    return $self->{slave};
}

package Test::MockTerm::Master;

use base qw(Tie::Handle);

sub TIEHANDLE {
    my ($class, $mock) = @_;

    my $self = bless {
        mock   => $mock,
        buffer => '',
    }, $class;

    open $self->{reader}, "<", \$self->{buffer};

    return $self;
}

sub PRINT {
    my ($self, @stuff) = @_;

    tied(*{$self->{mock}->{slave}})->{buffer} .= $_ for @stuff;
}

sub GETC {
    my ($self) = @_;

    return $self->{reader}->getc;
}

sub READLINE {
    my ($self) = @_;
    my $reader = $self->{reader};
    return <$reader>;
}

package Test::MockTerm::Slave;

use base qw(Tie::Handle);

sub TIEHANDLE {
    my ($class, $mock) = @_;

    my $self = bless {
        mock   => $mock,
        buffer => '',
    }, $class;

    open $self->{reader}, "<", \$self->{buffer};

    return $self;
}

sub PRINT {
    my ($self, @stuff) = @_;

    tied(*{$self->{mock}->{master}})->{buffer} .= $_ for @stuff;
}

sub GETC {
    my ($self) = @_;

    return $self->{reader}->getc;
}

sub READLINE {
    my ($self) = @_;
    my $reader = $self->{reader};
    return <$reader>;
}

1;
