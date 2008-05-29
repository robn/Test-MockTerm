package Test::MockTerm;

use 5.008;

our $VERSION = '0.01';

#
# XXX this description is old, from when this was based on IO::Pty
#
# This module allows testing of interactive programs that also poke at
# terminal settings. It was specifically designed for testing IO::Prompt, but
# might be useful elsewhere.
#
# IO::Prompt uses the following methods to communicate with the terminal:
#   - opens /dev/tty for reading        open $IN, "</dev/tty"
#   - opens /dev/tty for writing        open $OUT, ">/dev/tty"
#   - tests to see if its a terminal    -t $IN
#   - changes terminal modes            use Term::ReadKey
#                                       ReadMode 'xyz', $IN
#   - gets current term control chars   GetControlChars $IN
#
# We handle this in the following way:
#   - open          - override CORE::GLOBAL::open and look for attempts to
#                     open the terminal device
#   - -t            - make sure the handles returned from open actually are
#                     (pseudo) terminals via IO::Pty
#   - Term::ReadKey - since the handles are terminals already, this just works
#
# (This does mean that the tests will only work on systems that have
# pseudo-terminals. A more portable solution would be to override or otherwise
# control Perl's -t operator, and then install fake Term::ReadKey functions.
# As of Perl 5.8.8 there is no way to override -t, so we're stuck with this
# method for now).
#
# To start, you create a Test::MockTerm object, with the file that would
# normally be opened to get at the terminal.
#
#   my $mock = Test::MockTerm->new("/dev/tty");
#
# This arranges for Perl's "open" operator to return IO::Pty/IO::Tty objects
# when something attempts to open the named file for read (<) or write (>).
#
# You can "type" input onto the console with $mock->put. Similarly you can
# read back off the console with $mock->get (for a single char) or
# $mock->getline (calls the underlying IO::Handle::getline). Neither of these
# will block; get will return undef if there's nothing waiting to be read.
#
# Because its more useful for testing, put and getline will turn \r\n, \n\r
# and \r sequences into \n. get won't do this though.
#
# Be aware that pseudo-ttys (like most real terminals) echo input directly, so
# if you do ->put then ->get, you'll get back whatever you just wrote. Of
# course the program on the other end can control echoing.
#

use warnings;
use strict;

use Tie::Handle;
use Scalar::Util qw(refaddr weaken);
use Symbol ();
use Carp;

use base qw(Tie::Handle);

my %devices;

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
        if (not $file or not exists $devices{$file}) {

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

        my $handle;
        if ($mode eq "<") {
            $handle = $devices{$file}->{read_handle};
        }
        elsif ($mode eq ">") {
            $handle = $devices{$file}->{write_handle};
        }
        else {
            croak "no support for mode '$mode' for $file";
        }

        # they passed a plain globby symboly thing
        if (defined $_[0]) {

            # see above
            use Symbol ();
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
    my ($class, @files) = @_;

    my %files = map { $_ => 1 } @files;
    @files = keys %files;

    croak "no files specified" if @files == 0;

    if (@files == 1) {
        return $devices{$files[0]}->{self} if exists $devices{$files[0]};
    }
    else {
        my $count = 0;
        for my $file (@files) {
            $count++ if exists $devices{$file};
        }
        return $devices{$files[0]}->{self} if $count == @files;

        croak "two or more of the specified files we're previously opened independently, and can't be grouped now" if $count > 1;
    }

    my $device = {
        files  => \@files,
    };

    my $buffer = '';
    open $device->{handle}, "+<", \$buffer;

    $device->{handle} = Symbol::gensym();
    tie *{$device->{handle}}, $class;

    $device->{slave} = Test::MockTerm::Slave->new($device);

    $devices{$_} = $device for @files;

    my $self = bless \$device, $class;

    return $device->{handle};
}

sub DESTROY {
    my ($self) = @_;
    delete $devices{$_} for @{$$self->{files}};
}

sub TIEHANDLE {
}

# typing something
sub PRINT {
    my ($self, @stuff) = @_;

    # normalise newlines
    # XXX should I do this at all?
    map { s/(?:\r\n|\n\r|\r)/\n/g } @stuff;

    # put it onto the slave
    print {$self->{slave}} @stuff;

    # and back onto us
    # XXX unless local echo disabled
    $self->{buffer} .= $_ for @stuff;
}

# reading off the screen
sub GETC {
    my ($self) = @_;

    return $self->{handle}->getc;
}

# read a whole line off the screen
sub READLINE {
    my ($self) = @_;
    my $handle = $self->{handle};
    my $line = <$handle>;
    return if not defined $line;
    $line =~ s/(?:\r\n|\n\r|\r)/\n/g;
    return $line;
}


# slave is the process (ie /dev/tty) side
package Test::MockTerm::Slave;

use Tie::Handle;
use Scalar::Util qw(weaken);
use Carp;

use base qw(Tie::Handle);

sub TIEHANDLE {
    my ($class, $master) = @_;

    croak "no master device hashref provided" if not $master;

    my $buffer = '';
    open my $handle, "+<", \$buffer;

    my $self = bless {
        buffer => $buffer,
        handle => $handle,
        master => $master,
    }, $class;

    weaken $self->{master};

    return $self;
}

# writing to the screen
sub PRINT {
    my ($self, @stuff) = @_;

    # put it onto the master
    print {$self->{master}->{handle}} @stuff;
}

# reading from the keyboard
sub GETC {
    my ($self) = @_;

    return $self->{handle}->getc;
}

sub READLINE {
    my ($self) = @_;

    return $self->{handle}->getline;
}

1;
