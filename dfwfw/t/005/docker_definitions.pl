# this configuration was modified by hand which is not really nice
# TODO: regenerate a real config here


  my $re = {
   "mocked_container_infos" => {
   },

  "mocked_networks_response" => [
          {
            'Id' => '62f39412f0978d5232a3a6a1055ea052d86b57452165ed09d1d2b3a5f499a596',
            'Name' => 'ftp',
            'Options' => {},
            'Driver' => 'bridge',
            'Scope' => 'local',
            'Containers' => {
                              '8ac824b2b1e17145b8458d4ff76e2c7e1434f9dce3fcc47ebbb3a0d5ea5d5b0b' => {
                                                                                                      'MacAddress' => '02:42:ac:1e:00:02',
                                                                                                      'IPv4Address' => '172.30.0.2/16',
                                                                                                      'Name' => 'proftpd-test',
                                                                                                      'EndpointID' => 'e3cb82b54845ca74b26f0ba65057ffa1b30e6eb7ff6f7127f866e06188766df1',
                                                                                                      'IPv6Address' => ''
                                                                                                    }
                            },
            'IPAM' => {
                        'Config' => [
                                      {
                                        'Subnet' => '172.30.0.0/16',
                                        'Gateway' => '172.30.0.1/16'
                                      }
                                    ],
                        'Options' => undef,
                        'Driver' => 'default'
                      }
          },
          {
            'Containers' => {
                              '8ac824b2b1e17145b8458d4ff76e2c7e1434f9dce3fcc47ebbb3a0d5ea5d5b0b' => {
                                                                                                      'MacAddress' => '02:42:ac:18:00:0b',
                                                                                                      'IPv4Address' => '172.24.0.11/16',
                                                                                                      'IPv6Address' => '',
                                                                                                      'EndpointID' => '6f1d36e818b6ae45fad2908c6a5d3f4a202b4028f72d8cffe7e806ae57ca020d',
                                                                                                      'Name' => 'proftpd-test'
                                                                                                    },
                              '8ac824b2b1e17145b8458d4ff76e2c7e1434f9dce3fcc47ebbb3a0d5ea5d5bff' => {
                                                                                                      'MacAddress' => '02:42:ac:18:00:ff',
                                                                                                      'IPv4Address' => '172.24.0.253/16',
                                                                                                      'IPv6Address' => '',
                                                                                                      'EndpointID' => '6f1d36e818b6ae45fad2908c6a5d3f4a202b4028f72d8cffe7e806ae57ca02ff',
                                                                                                      'Name' => 'proftpd-other'
                                                                                                    },
                              'c1ec849ba65e5639e896a1c763f4df677fbb02241ed97187b5fb2b4ab2ef102f' => {
                                                                                                      'EndpointID' => 'c13867c17fb27af0c4517efa9f334b53ee75c7db34808390f370446ac043e379',
                                                                                                      'IPv6Address' => '',
                                                                                                      'Name' => 'mariadb-4',
                                                                                                      'IPv4Address' => '172.24.0.5/16',
                                                                                                      'MacAddress' => '02:42:ac:18:00:05'
                                                                                                    },
                            },
            'IPAM' => {
                        'Driver' => 'default',
                        'Options' => undef,
                        'Config' => [
                                      {
                                        'Gateway' => '172.24.0.1/16',
                                        'Subnet' => '172.24.0.0/16'
                                      }
                                    ]
                      },
            'Scope' => 'local',
            'Options' => {},
            'Driver' => 'bridge',
            'Id' => 'bdc0a1fc82acc0654bdb9ae82feca83e44b8102fdbf66fe10b4f3f6d5f798669',
            'Name' => 'db'
          },
	  
          {
            'Containers' => {},
            'IPAM' => {
                        'Options' => undef,
                        'Config' => [],
                        'Driver' => 'default'
                      },
            'Scope' => 'local',
            'Options' => {},
            'Driver' => 'null',
            'Id' => '70ac192369757615bed43a834700f7c2d7f27c904d812443313d9c1b0a920d21',
            'Name' => 'none'
          },
	  
          {
            'Id' => '5c47fb464fbb10f0d58f92818caeb31b4674421a46a561814d4f4c56c34c0338',
            'Name' => 'host',
            'Options' => {},
            'Driver' => 'host',
            'Scope' => 'local',
            'Containers' => {
                              '568468ea1b56f6420c06f2e4a8da3e01af3aee91719ce6612030ff9afca82510' => {
                                                                                                      'MacAddress' => '',
                                                                                                      'IPv4Address' => '',
                                                                                                      'IPv6Address' => '',
                                                                                                      'EndpointID' => '4eab38740a1887badaa7c5770ec58086d7cac4f15fb0fab3d646d264be44290d',
                                                                                                      'Name' => 'dfwfw-1'
                                                                                                    },
                            },
            'IPAM' => {
                        'Config' => [],
                        'Options' => undef,
                        'Driver' => 'default'
                      }
          },

          {
            'Scope' => 'local',
            'IPAM' => {
                        'Config' => [
                                      {
                                        'Subnet' => '172.17.0.0/16'
                                      }
                                    ],
                        'Options' => undef,
                        'Driver' => 'default'
                      },
            'Containers' => {
                            },
            'Name' => 'bridge',
            'Id' => '7d9fb0dce9a9811a47dff8b832eb925ee4d5a2758eba7784fb8fbf24658a3768',
            'Driver' => 'bridge',
            'Options' => {
                           'com.docker.network.bridge.default_bridge' => 'true',
                           'com.docker.network.driver.mtu' => '1500',
                           'com.docker.network.bridge.enable_ip_masquerade' => 'false',
                           'com.docker.network.bridge.enable_icc' => 'true',
                           'com.docker.network.bridge.host_binding_ipv4' => '0.0.0.0',
                           'com.docker.network.bridge.name' => 'docker0'
                         }
          },

        ],

  "mocked_containers_response" =>  [
          {
            'HostConfig' => {
                              'NetworkMode' => 'host'
                            },
            'Created' => 1463305187,
            'Names' => [
                         '/dfwfw-1'
                       ],
            'ImageID' => 'sha256:f376d6779b3dd74565fecb26dbce665501282cfc5e731f70e4a749b58c10b4a3',
            'Image' => 'dfwfw',
            'Ports' => [],
            'Status' => 'Up 5 hours',
            'NetworkSettings' => {
                                   'Networks' => {
                                                   'host' => {
                                                               'IPAddress' => '',
                                                               'EndpointID' => '4eab38740a1887badaa7c5770ec58086d7cac4f15fb0fab3d646d264be44290d',
                                                               'Aliases' => undef,
                                                               'Gateway' => '',
                                                               'IPv6Gateway' => '',
                                                               'IPPrefixLen' => 0,
                                                               'GlobalIPv6PrefixLen' => 0,
                                                               'IPAMConfig' => undef,
                                                               'MacAddress' => '',
                                                               'Links' => undef,
                                                               'NetworkID' => '',
                                                               'GlobalIPv6Address' => ''
                                                             }
                                                 }
                                 },
            'Id' => '568468ea1b56f6420c06f2e4a8da3e01af3aee91719ce6612030ff9afca82510',
            'Command' => 'bash',
            'Labels' => {}
          },
          {
            'ImageID' => 'sha256:5ff4e6be961ea2b51473af39a4be4aeb253c77f827c31915e260efad0473b1d8',
            'Image' => 'proftpd',
            'Ports' => [],
            'Status' => 'Up 6 hours',
            'NetworkSettings' => {
                                   'Networks' => {
                                                   'ftp' => {
                                                              'NetworkID' => '',
                                                              'GlobalIPv6Address' => '',
                                                              'IPPrefixLen' => 16,
                                                              'IPv6Gateway' => '',
                                                              'MacAddress' => '02:42:ac:1e:00:02',
                                                              'Links' => undef,
                                                              'GlobalIPv6PrefixLen' => 0,
                                                              'IPAMConfig' => undef,
                                                              'Aliases' => undef,
                                                              'Gateway' => '172.30.0.1',
                                                              'EndpointID' => 'e3cb82b54845ca74b26f0ba65057ffa1b30e6eb7ff6f7127f866e06188766df1',
                                                              'IPAddress' => '172.30.0.2'
                                                            },
                                                   'db' => {
                                                             'IPAddress' => '172.24.0.11',
                                                             'EndpointID' => '6f1d36e818b6ae45fad2908c6a5d3f4a202b4028f72d8cffe7e806ae57ca020d',
                                                             'Aliases' => undef,
                                                             'Gateway' => '172.24.0.1',
                                                             'IPPrefixLen' => 16,
                                                             'IPv6Gateway' => '',
                                                             'Links' => undef,
                                                             'MacAddress' => '02:42:ac:18:00:0b',
                                                             'GlobalIPv6PrefixLen' => 0,
                                                             'IPAMConfig' => {},
                                                             'NetworkID' => '',
                                                             'GlobalIPv6Address' => ''
                                                           }
                                                 }
                                 },
            'Id' => '8ac824b2b1e17145b8458d4ff76e2c7e1434f9dce3fcc47ebbb3a0d5ea5d5b0b',
            'Command' => '/opt/proftpd/proftpd-start',
            'Labels' => {},
            'HostConfig' => {
                              'NetworkMode' => 'ftp'
                            },
            'Created' => 1459587722,
            'Names' => [
                         '/proftpd-test'
                       ]
          },




          {
            'ImageID' => 'sha256:5ff4e6be961ea2b51473af39a4be4aeb253c77f827c31915e260efad0473b1d8',
            'Image' => 'proftpd',
            'Ports' => [],
            'Status' => 'Up 6 hours',
            'NetworkSettings' => {
                                   'Networks' => {
                                                   'ftp' => {
                                                              'NetworkID' => '',
                                                              'GlobalIPv6Address' => '',
                                                              'IPPrefixLen' => 16,
                                                              'IPv6Gateway' => '',
                                                              'MacAddress' => '02:42:ac:1e:00:ff',
                                                              'Links' => undef,
                                                              'GlobalIPv6PrefixLen' => 0,
                                                              'IPAMConfig' => undef,
                                                              'Aliases' => undef,
                                                              'Gateway' => '172.30.0.1',
                                                              'EndpointID' => 'e3cb82b54845ca74b26f0ba65057ffa1b30e6eb7ff6f7127f866e06188766dff',
                                                              'IPAddress' => '172.30.0.253'
                                                            },
                                                   'db' => {
                                                             'IPAddress' => '172.24.0.253',
                                                             'EndpointID' => '6f1d36e818b6ae45fad2908c6a5d3f4a202b4028f72d8cffe7e806ae57ca02ff',
                                                             'Aliases' => undef,
                                                             'Gateway' => '172.24.0.1',
                                                             'IPPrefixLen' => 16,
                                                             'IPv6Gateway' => '',
                                                             'Links' => undef,
                                                             'MacAddress' => '02:42:ac:18:00:ff',
                                                             'GlobalIPv6PrefixLen' => 0,
                                                             'IPAMConfig' => {},
                                                             'NetworkID' => '',
                                                             'GlobalIPv6Address' => ''
                                                           }
                                                 }
                                 },
            'Id' => '8ac824b2b1e17145b8458d4ff76e2c7e1434f9dce3fcc47ebbb3a0d5ea5d5bff',
            'Command' => '/opt/proftpd/proftpd-start',
            'Labels' => {},
            'HostConfig' => {
                              'NetworkMode' => 'ftp'
                            },
            'Created' => 1459587722,
            'Names' => [
                         '/proftpd-other'
                       ]
          },


          {
            'Ports' => [
                         {
                           'Type' => 'tcp',
                           'PrivatePort' => 3306
                         }
                       ],
            'Image' => 'mariadb',
            'ImageID' => 'sha256:8c58bba704428f9f120582973b72b424de8b3adcd6a34c89d8aa552b727cfbc5',
            'Command' => '/opt/mariadb/mariadb-start mysqld',
            'Labels' => {},
            'Id' => 'c1ec849ba65e5639e896a1c763f4df677fbb02241ed97187b5fb2b4ab2ef102f',
            'Status' => 'Up 6 hours',
            'NetworkSettings' => {
                                   'Networks' => {
                                                   'db' => {
                                                             'IPPrefixLen' => 16,
                                                             'IPv6Gateway' => '',
                                                             'MacAddress' => '02:42:ac:18:00:05',
                                                             'Links' => undef,
                                                             'IPAMConfig' => undef,
                                                             'GlobalIPv6PrefixLen' => 0,
                                                             'NetworkID' => '',
                                                             'GlobalIPv6Address' => '',
                                                             'IPAddress' => '172.24.0.5',
                                                             'EndpointID' => 'c13867c17fb27af0c4517efa9f334b53ee75c7db34808390f370446ac043e379',
                                                             'Aliases' => undef,
                                                             'Gateway' => '172.24.0.1'
                                                           }
                                                 }
                                 },
            'HostConfig' => {
                              'NetworkMode' => 'db'
                            },
            'Names' => [
                         '/mariadb-4'
                       ],
            'Created' => 1459362489
          },
        ]

}
