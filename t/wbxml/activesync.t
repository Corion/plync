use strict;
use warnings;

use Test::More tests => 3;

use Plync::WBXML::Parser;
use Plync::WBXML::Builder;

use Plync::WBXML::Schema::ActiveSync;

my $wbxml = pack('H*', '03016a00455c4f5003436f6e746163747300014b0332000152033200014e0331000156474d03323a3100015d00114a46033100014c033000014d033100010100015e0348616c6c2c20446f6e00015f03446f6e0001690348616c6c000100115603310001010101010101');

my $xml = <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<Sync xmlns="AirSync:" xmlns:airsyncbase="AirSyncBase:" xmlns:contacts="Contacts:">
    <Collections>
        <Collection>
            <Class>Contacts</Class>
            <SyncKey>2</SyncKey>
            <CollectionId>2</CollectionId>
            <Status>1</Status>
            <Commands>
                <Add>
                    <ServerId>2:1</ServerId>
                    <ApplicationData>
                        <airsyncbase:Body>
                            <airsyncbase:Type>1</airsyncbase:Type>
                            <airsyncbase:EstimatedDataSize>0</airsyncbase:EstimatedDataSize>
                            <airsyncbase:Truncated>1</airsyncbase:Truncated>
                        </airsyncbase:Body>
                        <contacts:FileAs>Hall, Don</contacts:FileAs>
                        <contacts:FirstName>Don</contacts:FirstName>
                        <contacts:LastName>Hall</contacts:LastName>
                        <airsyncbase:NativeBodyType>1</airsyncbase:NativeBodyType>
                    </ApplicationData>
                </Add>
            </Commands>
        </Collection>
    </Collections>
</Sync>
EOF

my $builder =
  Plync::WBXML::Builder->new(
    schema => Plync::WBXML::Schema::ActiveSync->schema);

$builder->build($xml);
is($builder->to_wbxml, $wbxml);

my $parser = Plync::WBXML::Parser->new(schema => Plync::WBXML::Schema::ActiveSync->schema);

$xml =~ s/>\s+</></g;
$xml =~ s/utf-8"\?>/UTF-8"?>\n/;
ok($parser->parse($wbxml));
is($parser->to_string, $xml);