package Test::MockTerm;

use 5.008;

our $VERSION = '0.01';

use warnings;
use strict;

use Symbol ();
use Scalar::Util qw(refaddr weaken);
use Carp;
use Tie::Handle;

our %bound;

sub import {

    # override the system open so we can intercept stuff
    *CORE::GLOBAL::open = sub {

        # first figure out what they're trying to do
        my ($mode, $file);

        # three-arg form is easy
        if (@_ == 3) {
            $mode = $_[1];
            $file = $_[2];
        }

        # two-arg form, just take the first character
        elsif (@_ == 2) {
            $mode = substr $_[1], 0, 1;
            $file = substr $_[1], 1;
        }

        # magical one-arg form, sigh
        elsif (@_ == 1) {
            no strict "refs";
            $mode = "<";
            $file = ${$_[0]};
        }

        # if we couldn't extract a filename, or we're not interested in that
        # file, just pass it through to the normal open
        if (not $file or not exists $bound{$file}) {

            # first arg can be a symbol
            if (defined $_[0]) {

                # since they're bouncing through us, open will get the caller
                # wrong unless we qualify the handle name
                my $handle = Symbol::qualify($_[0], (caller)[0]);

                no strict "refs";
                if    (@_ == 1) { return CORE::open $handle }
                elsif (@_ == 2) { return CORE::open $handle, $_[1] }
                else            { return CORE::open $handle, $_[1], @_[2..$#_] }
            }

            # or a scalar
            else {
                if    (@_ == 1) { return CORE::open $_[0] }
                elsif (@_ == 2) { return CORE::open $_[0], $_[1] }
                else            { return CORE::open $_[0], $_[1], @_[2..$#_] }
            }
        }

        # so we're handling this file. if they're trying to do something other
        # than just read or write, then we're confused
        if ($mode ne "<" and $mode ne ">") {
            croak "no support for mode '$mode' for $file";
        }

        # send the slave back
        my $handle = $bound{$file}->slave;

        # they passed a plain globby symboly thing
        if (defined $_[0]) {

            # see above
            my $glob = Symbol::qualify($_[0], (caller)[0]);

            no strict "refs";
            *{$glob} = $handle;
        }

        # otherwise its a just a scalar, and we can trample it
        else {
            $_[0] = $handle;
        }

        return 1;
    };
}

sub new {
    my ($class, @args) = @_;

    my $self = bless { }, $class;

    my $master = Symbol::gensym;
    tie *$master, "Test::MockTerm::Master", $self;

    my $slave = Symbol::gensym;
    tie *$slave, "Test::MockTerm::Slave", $self;

    $self->{master} = $master;
    $self->{slave} = $slave;

    $self->{files} = { };

    return $self;
}

sub DESTROY {
    my ($self) = @_;

    untie *{$self->{master}};
    delete $self->{master};

    untie *{$self->{slave}};
    delete $self->{slave};

    for my $file (keys %{$self->{files}}) {
        delete $bound{$file} if defined $bound{$file} and refaddr $bound{$file} == refaddr $self;
    }
}

sub master {
    my ($self) = @_;

    return $self->{master};
}

sub slave {
    my ($self) = @_;

    return $self->{slave};
}

sub bind {
    my ($self, @files) = @_;

    for my $file (@files) {
        $bound{$file} = $self;
        weaken $bound{$file};

        $self->{files}->{$file} = 1;
    }
}

package Test::MockTerm::Master;

use base qw(Tie::Handle);

use Scalar::Util qw(weaken);

sub TIEHANDLE {
    my ($class, $mock) = @_;

    my $self = bless {
        mock   => $mock,
        buffer => '',
    }, $class;
    weaken $self->{mock};

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

use Scalar::Util qw(weaken);

sub TIEHANDLE {
    my ($class, $mock) = @_;

    my $self = bless {
        mock   => $mock,
        buffer => '',
    }, $class;
    weaken $self->{mock};

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
