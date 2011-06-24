package PlyncCommandPingTest;

use strict;
use warnings;

use base 'PlyncCommandTestBase';

use Test::Plync;
use Test::MockObject::Extends;

use AnyEvent;
use Plync::Command::Ping;
use Plync::Command::Ping::Request;

sub make_fixture : Test(setup) {
    my $self = shift;

    my $backend = Test::Plync->build_backend;
    my $device = Test::Plync->build_device(backend => $backend);

    $self->{device} = $device;
}

sub test_interval_error : Test {
    my $self = shift;

    my $in = <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<Ping xmlns="Ping:">
  <HeartbeatInterval>100000</HeartbeatInterval>
  <Folders>
    <Folder>
      <Id>5</Id>
      <Class>Email</Class>
    </Folder>
  </Folders>
</Ping>
EOF

    my $out = <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<Ping xmlns="Ping:">
  <Status>5</Status>
  <HeartbeatInterval>600</HeartbeatInterval>
</Ping>
EOF

    is $self->_run_command('Ping', $in), $out;
}

sub test_max_folders_error : Test {
    my $self = shift;

    my $in = <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<Ping xmlns="Ping:">
  <HeartbeatInterval>60</HeartbeatInterval>
  <Folders>
    <Folder>
      <Id>5</Id>
      <Class>Email</Class>
    </Folder>
    <Folder>
      <Id>5</Id>
      <Class>Email</Class>
    </Folder>
    <Folder>
      <Id>5</Id>
      <Class>Email</Class>
    </Folder>
    <Folder>
      <Id>5</Id>
      <Class>Email</Class>
    </Folder>
    <Folder>
      <Id>5</Id>
      <Class>Email</Class>
    </Folder>
    <Folder>
      <Id>5</Id>
      <Class>Email</Class>
    </Folder>
  </Folders>
</Ping>
EOF

    my $out = <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<Ping xmlns="Ping:">
  <Status>6</Status>
  <MaxFolders>5</MaxFolders>
</Ping>
EOF

    is $self->_run_command('Ping', $in), $out;
}

sub test_no_changes : Test {
    my $self = shift;

    my $in = <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<Ping xmlns="Ping:">
  <HeartbeatInterval>60</HeartbeatInterval>
  <Folders>
    <Folder>
      <Id>1</Id>
      <Class>Email</Class>
    </Folder>
  </Folders>
</Ping>
EOF

    my $out = <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<Ping xmlns="Ping:">
  <Status>1</Status>
</Ping>
EOF

    my $device = $self->{device};
    $device->mock(watch => sub { });
    my $command = $self->_build_command(device => $device);
    $command->mock(
        _build_timeout => sub {
            shift;
            my ($interval, $cb) = @_;
            $cb->();
        }
    );

    is $self->_run_command($command, $in), $out;
}

sub test_changes : Test {
    my $self = shift;

    my $in = <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<Ping xmlns="Ping:">
  <HeartbeatInterval>60</HeartbeatInterval>
  <Folders>
    <Folder>
      <Id>1</Id>
      <Class>Email</Class>
    </Folder>
  </Folders>
</Ping>
EOF

    my $out = <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<Ping xmlns="Ping:">
  <Status>2</Status>
  <Folders>
    <Folder>1</Folder>
  </Folders>
</Ping>
EOF

    my $device = $self->{device};
    $device->mock(
        watch => sub {
            my $device = shift;
            my ($folders, $cb) = @_;

            my @ids;
            foreach my $folder (@$folders) {
                push @ids, $folder->{id};
            }

            $cb->([@ids]);
        }
    );

    my $command = $self->_build_command(device => $device);
    $command->mock(_build_timeout => sub { });

    is $self->_run_command($command, $in), $out;
}

sub _build_command {
    my $self = shift;

    my $command = Plync::Command::Ping->new(@_);
    $command = Test::MockObject::Extends->new($command);
    $command->mock(
        _build_request => sub {
            Plync::Command::Ping::Request->new;
        }
    );

    return $command;
}

1;
