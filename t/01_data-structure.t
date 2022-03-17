#! /usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::Most;
use Test::MockTime qw(set_absolute_time);

use Business::DPD::shipperAPI;
use Business::DPD::shipperAPI::Data::Address;
use Business::DPD::shipperAPI::Data::Parcel;
use Business::DPD::shipperAPI::Data::CreateResp;

set_absolute_time('2022-03-11T09:00:00Z');    # friday, so pick-up date will be next monday

subtest 'Data::Address' => sub {
    my $a1 = Business::DPD::shipperAPI::Data::Address->new(
        name                => 'a b',
        street_house_number => 'Str. 123',
        zip                 => '0123',
        country             => 'at',
        city                => 'C',
        phone               => '+43',
    );
    eq_or_diff(
        $a1->as_data,
        {   type        => 'b2b',
            name        => 'a b',
            street      => 'Str.',
            houseNumber => '123',
            zip         => '0123',
            city        => 'C',
            country     => '040',
            phone       => '+43',
        },
        'Business::DPD::shipperAPI::Data::Address->as_data',
    );
};

subtest 'Data::Parcel' => sub {
    my $p1 = Business::DPD::shipperAPI::Data::Parcel->new(
        weight    => '30.1',
        width     => '31',
        height    => '32',
        depth     => '33',
        parcel_no => '0123',
    );
    eq_or_diff(
        $p1->as_data,
        {   weight    => '30.1',
            width     => '31',
            height    => '32',
            depth     => '33',
            parcel_no => '0123',
        },
        'Business::DPD::shipperAPI::Data::Parcel->as_data',
    );
};

subtest 'Data::CreateReq' => sub {
    my $sapi = Business::DPD::shipperAPI::Data::CreateReq->new(
        login_email => 'e@d.co',
        delis_id    => 'BA1234',
        api_key     => 'super-secret',
        pickup_id   => '123456',
        reference   => 'ref',
        parcels     => [
            Business::DPD::shipperAPI::Data::Parcel->new(
                weight    => '30.1',
                width     => '31',
                height    => '32',
                depth     => '33',
                parcel_no => '0123',
            ),
        ],
        address_recipient => Business::DPD::shipperAPI::Data::Address->new(
            name                => 'a b',
            street_house_number => 'Str. 123',
            zip                 => '0123',
            country             => 'at',
            city                => 'C',
            phone               => '+43',
        ),
    );
    eq_or_diff(
        $sapi->as_data,
        {   jsonrpc => '2.0',
            method  => 'create',
            params  => {
                DPDSecurity => {
                    SecurityToken => {
                        ClientKey => 'super-secret',
                        Email     => 'e@d.co'
                    }
                },
                shipment => [
                    {   addressRecipient => {
                            city        => 'C',
                            country     => '040',
                            houseNumber => 123,
                            name        => 'a b',
                            phone       => '+43',
                            street      => 'Str.',
                            type        => 'b2b',
                            zip         => '0123'
                        },
                        addressSender => {id => 123456},
                        delisId       => 'BA1234',
                        parcels       => {
                            parcel => [
                                {   depth     => 33,
                                    height    => 32,
                                    parcel_no => '0123',
                                    weight    => '30.1',
                                    width     => 31
                                }
                            ]
                        },
                        pickup => {
                            date       => 20220314,
                            timeWindow => {beginning => '0800'}
                        },
                        product   => 1,
                        reference => 'ref'
                    }
                ]
            }
        },
        'Business::DPD::shipperAPI::Data::CreateReq->as_data',
    );

};

subtest 'Data::CreateResp lables created' => sub {
    my $cresp = Business::DPD::shipperAPI::Data::CreateResp->new(
        resp_data => {
            'id'     => 'null',
            'method' => 'create',
            'result' => {
                'result' => [
                    {   'messages' =>
                            ["Objedn\x{e1}vka bola \x{fa}spe\x{161}ne ulo\x{17e}en\x{e1}."],
                        'label'     => 'https://capi.dpd.sk/labels?data=EAAAAM...',
                        'ackCode'   => 'success',
                        'reference' => 'PO-2105175',
                        'success'   => 1,
                        'mpsid'     => '9650502546730520123456'
                    }
                ]
            },
            'jsonrpc' => '2.0'
        },
        _ua => Test::Mock::Future::HTTP->new(),
    );
    ok($cresp->is_success, 'is_success()');
    is($cresp->label_url,     'https://capi.dpd.sk/labels?data=EAAAAM...',      'label_url()');
    is($cresp->mpsid,         '9650502546730520123456',                         'mpsid()');
    is($cresp->get_label_pdf, 'body:https://capi.dpd.sk/labels?data=EAAAAM...', 'get_label_pdf()');
};

subtest 'Data::CreateResp lables created (fail)' => sub {
    my $cresp = Business::DPD::shipperAPI::Data::CreateResp->new(
        resp_data => {
            'jsonrpc' => '2.0',
            'result'  => {
                'result' => [
                    {   'reference' => 'PO-2105175',
                        'messages'  => [
                            {   'value'    => '\'Weight\' must be less than or equal to \'31,5\'.',
                                'element'  => 'weight',
                                'envelope' => 'parcel[0]'
                            },
                            {   'envelope' => 'parcel[1]',
                                'element'  => 'weight',
                                'value'    => '\'Weight\' must be less than or equal to \'31,5\'.'
                            }
                        ],
                        'success' => bless(do {\(my $o = 0)}, 'JSON::PP::Boolean'),
                        'ackCode' => 'validation'
                    }
                ]
            },
            'id'     => 'null',
            'method' => 'create'
        },
    );
    ok(!$cresp->is_success, 'is_success()');
    is( $cresp->error_msg,
        join("\n",
            '\'Weight\' must be less than or equal to \'31,5\'.',
            '\'Weight\' must be less than or equal to \'31,5\'.'),
        'error_msg()'
    );
};

subtest 'Data::CreateResp lables created (fail2)' => sub {
    my $cresp = Business::DPD::shipperAPI::Data::CreateResp->new(
        resp_data => {
          'id' => 'null',
          'jsonrpc' => '2.0',
          'result' => {
                        'result' => [
                                      {
                                        'success' => 0,
                                        'reference' => 'PO-2106890',
                                        'messages' => [
                                                        'Product / service DPD CLASSIC is not allowed in specified destination.'
                                                      ],
                                        'ackCode' => 'validation'
                                      }
                                    ]
                      },
          'method' => 'create'
        },
    );
    ok(!$cresp->is_success, 'is_success()');
    is($cresp->error_msg,
        join("\n", 'Product / service DPD CLASSIC is not allowed in specified destination.'),
        'error_msg()');
};

done_testing();

package Test::Mock::Future::HTTP;

use Moose;
use FindBin qw($Bin);

sub http_post {
    my ($self, $url, $body, %options) = @_;
    return Future->done($body, \%options);
}

sub http_get {
    my ($self, $url) = @_;
    return Future->done('body:' . $url, {Status => 200});
}

1;
