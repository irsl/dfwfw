# this is a minimalistic example of 3 containers (dfwfw-1, proftpd-test, mariadb-4) in 3 networks (host, db and ftp)
# note that the mocked_container_infos hash is populated here, since DFWFW needs to query them in order to learn the hosts file pathes

  my $re = {
   "mocked_container_infos" => {
     '8ac824b2b1e17145b8458d4ff76e2c7e1434f9dce3fcc47ebbb3a0d5ea5d5b0b' => {
          'Driver' => 'aufs',
          'Id' => '8ac824b2b1e17145b8458d4ff76e2c7e1434f9dce3fcc47ebbb3a0d5ea5d5b0b',
          'NetworkSettings' => {
                                 'Ports' => {},
                                 'GlobalIPv6Address' => '',
                                 'EndpointID' => '',
                                 'Gateway' => '',
                                 'LinkLocalIPv6Address' => '',
                                 'IPAddress' => '',
                                 'IPPrefixLen' => 0,
                                 'SecondaryIPAddresses' => undef,
                                 'IPv6Gateway' => '',
                                 'GlobalIPv6PrefixLen' => 0,
                                 'SandboxID' => '922948ec1908aa7dfed39a284a23e2a05056e5278270578be400103e4500ddec',
                                 'Networks' => {
                                                 'ftp' => {
                                                            'NetworkID' => '62f39412f0978d5232a3a6a1055ea052d86b57452165ed09d1d2b3a5f499a596',
                                                            'Aliases' => undef,
                                                            'IPAddress' => '172.30.0.2',
                                                            'MacAddress' => '02:42:ac:1e:00:02',
                                                            'IPPrefixLen' => 16,
                                                            'GlobalIPv6Address' => '',
                                                            'EndpointID' => 'e3cb82b54845ca74b26f0ba65057ffa1b30e6eb7ff6f7127f866e06188766df1',
                                                            'Gateway' => '172.30.0.1',
                                                            'Links' => undef,
                                                            'IPv6Gateway' => '',
                                                            'IPAMConfig' => undef,
                                                            'GlobalIPv6PrefixLen' => 0
                                                          },
                                                 'db' => {
                                                           'MacAddress' => '02:42:ac:18:00:0b',
                                                           'IPPrefixLen' => 16,
                                                           'IPAddress' => '172.24.0.11',
                                                           'Aliases' => undef,
                                                           'NetworkID' => 'bdc0a1fc82acc0654bdb9ae82feca83e44b8102fdbf66fe10b4f3f6d5f798669',
                                                           'EndpointID' => '6f1d36e818b6ae45fad2908c6a5d3f4a202b4028f72d8cffe7e806ae57ca020d',
                                                           'Gateway' => '172.24.0.1',
                                                           'GlobalIPv6Address' => '',
                                                           'Links' => undef,
                                                           'GlobalIPv6PrefixLen' => 0,
                                                           'IPAMConfig' => {},
                                                           'IPv6Gateway' => ''
                                                         }
                                               },
                                 'Bridge' => '',
                                 'MacAddress' => '',
                                 'LinkLocalIPv6PrefixLen' => 0,
                                 'HairpinMode' => bless( do{\(my $o = 0)}, 'JSON::XS::Boolean' ),
                                 'SandboxKey' => '/var/run/docker/netns/922948ec1908',
                                 'SecondaryIPv6Addresses' => undef
                               },
          'Path' => '/opt/proftpd/proftpd-start',
          'ResolvConfPath' => '/var/lib/docker/containers/8ac824b2b1e17145b8458d4ff76e2c7e1434f9dce3fcc47ebbb3a0d5ea5d5b0b/resolv.conf',
          'Created' => '2016-04-02T09:02:02.323698419Z',
          'Image' => 'sha256:5ff4e6be961ea2b51473af39a4be4aeb253c77f827c31915e260efad0473b1d8',
          'Name' => '/proftpd-test',
          'ProcessLabel' => '',
          'Args' => [],
          'GraphDriver' => {
                             'Data' => undef,
                             'Name' => 'aufs'
                           },
          'ExecIDs' => undef,
          'Mounts' => [
                      ],
          'HostsPath' => '/var/lib/docker/containers/8ac824b2b1e17145b8458d4ff76e2c7e1434f9dce3fcc47ebbb3a0d5ea5d5b0b/hosts',
          'RestartCount' => 0,
          'State' => {
                       'Error' => '',
                       'StartedAt' => '2016-05-15T08:43:45.407529545Z',
                       'FinishedAt' => '2016-05-15T08:42:16.182539739Z',
                       'Status' => 'running',
                       'ExitCode' => 0,
                       'Pid' => 1886
                     },
          'LogPath' => '/var/lib/docker/containers/8ac824b2b1e17145b8458d4ff76e2c7e1434f9dce3fcc47ebbb3a0d5ea5d5b0b/8ac824b2b1e17145b8458d4ff76e2c7e1434f9dce3fcc47ebbb3a0d5ea5d5b0b-json.log',
          'HostnamePath' => '/var/lib/docker/containers/8ac824b2b1e17145b8458d4ff76e2c7e1434f9dce3fcc47ebbb3a0d5ea5d5b0b/hostname',
          'AppArmorProfile' => '',
          'Config' => {
                        'WorkingDir' => '',
                        'OnBuild' => undef,
                        'Entrypoint' => [
                                          '/opt/proftpd/proftpd-start'
                                        ],
                        'Cmd' => undef,
                        'Volumes' => {
                                       '/var/log' => {}
                                     },
                        'Labels' => {},
                        'Image' => 'proftpd',
                        'Hostname' => '8ac824b2b1e1',
                        'StopSignal' => 'SIGTERM',
                        'Env' => [
                                   'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
                                 ],
                        'User' => '',
                        'Domainname' => ''
                      },
          'HostConfig' => {
                            'Isolation' => '',
                            'PidsLimit' => 0,
                            'KernelMemory' => 0,
                            'MemorySwap' => 0,
                            'CapDrop' => undef,
                            'UTSMode' => '',
                            'NetworkMode' => 'ftp',
                            'BlkioWeightDevice' => undef,
                            'Binds' => [
                                       ],
                            'MemoryReservation' => 0,
                            'BlkioWeight' => 0,
                            'BlkioDeviceReadIOps' => undef,
                            'ShmSize' => 67108864,
                            'SecurityOpt' => undef,
                            'BlkioDeviceReadBps' => undef,
                            'CgroupParent' => '',
                            'Dns' => [],
                            'ContainerIDFile' => '',
                            'LogConfig' => {
                                             'Config' => {
                                                           'max-file' => '20',
                                                           'max-size' => '1m'
                                                         },
                                             'Type' => 'json-file'
                                           },
                            'Ulimits' => undef,
                            'Links' => undef,
                            'PortBindings' => {},
                            'Memory' => 0,
                            'IpcMode' => '',
                            'Devices' => [],
                            'ConsoleSize' => [
                                               0,
                                               0
                                             ],
                            'CpuQuota' => 0,
                            'PidMode' => '',
                            'MemorySwappiness' => -1,
                            'GroupAdd' => undef,
                            'CpusetMems' => '',
                            'RestartPolicy' => {
                                                 'Name' => 'always',
                                                 'MaximumRetryCount' => 0
                                               },
                            'CpusetCpus' => '',
                            'VolumesFrom' => undef,
                            'OomScoreAdj' => 0,
                            'BlkioDeviceWriteIOps' => undef,
                            'BlkioDeviceWriteBps' => undef,
                            'DnsSearch' => [],
                            'CapAdd' => undef,
                            'VolumeDriver' => '',
                            'DnsOptions' => [],
                            'CpuPeriod' => 0,
                            'ExtraHosts' => undef,
                            'CpuShares' => 0
                          },
          'MountLabel' => ''
        },


'c1ec849ba65e5639e896a1c763f4df677fbb02241ed97187b5fb2b4ab2ef102f' => {
          'GraphDriver' => {
                             'Data' => undef,
                             'Name' => 'aufs'
                           },
          'Mounts' => [
                      ],
          'ExecIDs' => undef,
          'ProcessLabel' => '',
          'Name' => '/mariadb-4',
          'Args' => [
                      'mysqld'
                    ],
          'Created' => '2016-03-30T18:28:09.081515181Z',
          'ResolvConfPath' => '/var/lib/docker/containers/c1ec849ba65e5639e896a1c763f4df677fbb02241ed97187b5fb2b4ab2ef102f/resolv.conf',
          'Path' => '/opt/mariadb/mariadb-start',
          'Image' => 'sha256:8c58bba704428f9f120582973b72b424de8b3adcd6a34c89d8aa552b727cfbc5',
          'Driver' => 'aufs',
          'NetworkSettings' => {
                                 'SandboxID' => '11fd424d1b1923cc7a9d30b05296e7c148ae06faccc3c3e2b3af1f7895eb8d70',
                                 'IPv6Gateway' => '',
                                 'GlobalIPv6PrefixLen' => 0,
                                 'IPAddress' => '',
                                 'LinkLocalIPv6Address' => '',
                                 'SecondaryIPAddresses' => undef,
                                 'IPPrefixLen' => 0,
                                 'Ports' => {
                                              '3306/tcp' => undef
                                            },
                                 'GlobalIPv6Address' => '',
                                 'Gateway' => '',
                                 'EndpointID' => '',
                                 'HairpinMode' => bless( do{\(my $o = 0)}, 'JSON::XS::Boolean' ),
                                 'SandboxKey' => '/var/run/docker/netns/11fd424d1b19',
                                 'SecondaryIPv6Addresses' => undef,
                                 'Bridge' => '',
                                 'MacAddress' => '',
                                 'LinkLocalIPv6PrefixLen' => 0,
                                 'Networks' => {
                                                 'db' => {
                                                           'NetworkID' => 'bdc0a1fc82acc0654bdb9ae82feca83e44b8102fdbf66fe10b4f3f6d5f798669',
                                                           'IPAddress' => '172.24.0.5',
                                                           'Aliases' => [
                                                                          'mysql.alias'
                                                                        ],
                                                           'IPPrefixLen' => 16,
                                                           'MacAddress' => '02:42:ac:18:00:05',
                                                           'GlobalIPv6Address' => '',
                                                           'Gateway' => '172.24.0.1',
                                                           'EndpointID' => 'c13867c17fb27af0c4517efa9f334b53ee75c7db34808390f370446ac043e379',
                                                           'Links' => undef,
                                                           'IPv6Gateway' => '',
                                                           'IPAMConfig' => undef,
                                                           'GlobalIPv6PrefixLen' => 0
                                                         }
                                               }
                               },
          'Id' => 'c1ec849ba65e5639e896a1c763f4df677fbb02241ed97187b5fb2b4ab2ef102f',
          'Config' => {
                        'Domainname' => '',
                        'StopSignal' => 'SIGTERM',
                        'User' => '',
                        'Env' => [
                                   'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
                                 ],
                        'Labels' => {},
                        'Image' => 'mariadb',
                        'Hostname' => 'c1ec849ba65e',
                        'Volumes' => {
                                       '/var/lib/mysql' => {}
                                     },
                        'ExposedPorts' => {
                                            '3306/tcp' => {}
                                          },
                        'Entrypoint' => [
                                          '/opt/mariadb/mariadb-start'
                                        ],
                        'Cmd' => [
                                   'mysqld'
                                 ],
                        'OnBuild' => undef,
                        'WorkingDir' => ''
                      },
          'MountLabel' => '',
          'HostConfig' => {
                            'BlkioWeightDevice' => undef,
                            'MemoryReservation' => 0,
                            'Binds' => [
                                       ],
                            'MemorySwap' => 0,
                            'KernelMemory' => 0,
                            'NetworkMode' => 'db',
                            'UTSMode' => '',
                            'CapDrop' => undef,
                            'PidsLimit' => 0,
                            'Isolation' => '',
                            'Links' => undef,
                            'ContainerIDFile' => '',
                            'LogConfig' => {
                                             'Type' => 'none',
                                             'Config' => {}
                                           },
                            'Dns' => [],
                            'Ulimits' => undef,
                            'ShmSize' => 67108864,
                            'CgroupParent' => '',
                            'BlkioDeviceReadBps' => undef,
                            'SecurityOpt' => undef,
                            'BlkioWeight' => 0,
                            'BlkioDeviceReadIOps' => undef,
                            'CpusetCpus' => '',
                            'OomScoreAdj' => 0,
                            'VolumesFrom' => undef,
                            'PidMode' => '',
                            'MemorySwappiness' => -1,
                            'RestartPolicy' => {
                                                 'MaximumRetryCount' => 0,
                                                 'Name' => 'always'
                                               },
                            'CpusetMems' => '',
                            'GroupAdd' => undef,
                            'Devices' => [],
                            'CpuQuota' => 0,
                            'ConsoleSize' => [
                                               0,
                                               0
                                             ],
                            'PortBindings' => {},
                            'IpcMode' => '',
                            'Memory' => 0,
                            'ExtraHosts' => undef,
                            'CpuPeriod' => 0,
                            'CpuShares' => 0,
                            'VolumeDriver' => '',
                            'DnsOptions' => [],
                            'CapAdd' => undef,
                            'DnsSearch' => [],
                            'BlkioDeviceWriteIOps' => undef,
                            'BlkioDeviceWriteBps' => undef
                          },
          'HostnamePath' => '/var/lib/docker/containers/c1ec849ba65e5639e896a1c763f4df677fbb02241ed97187b5fb2b4ab2ef102f/hostname',
          'AppArmorProfile' => '',
          'State' => {
                       'ExitCode' => 0,
                       'Status' => 'running',
                       'Pid' => 1564,
                       'StartedAt' => '2016-05-15T08:43:09.592198483Z',
                       'FinishedAt' => '2016-05-15T08:42:16.162147285Z',
                       'Error' => '',
                     },
          'LogPath' => '',
          'HostsPath' => '/var/lib/docker/containers/c1ec849ba65e5639e896a1c763f4df677fbb02241ed97187b5fb2b4ab2ef102f/hosts',
          'RestartCount' => 0
        },

'568468ea1b56f6420c06f2e4a8da3e01af3aee91719ce6612030ff9afca82510' => {
          'Config' => {
                        'WorkingDir' => '',
                        'OnBuild' => undef,
                        'Cmd' => undef,
                        'Entrypoint' => [
                                          'bash'
                                        ],
                        'Volumes' => undef,
                        'Hostname' => 'builder',
                        'Image' => 'dfwfw',
                        'Labels' => {},
                        'StopSignal' => 'SIGTERM',
                        'Env' => [
                                   'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
                                 ],
                        'User' => '',
                        'Domainname' => ''
                      },
          'MountLabel' => '',
          'HostConfig' => {
                            'PublishAllPorts' => bless( do{\(my $o = 0)}, 'JSON::XS::Boolean' ),
                            'PidsLimit' => 0,
                            'Isolation' => '',
                            'NetworkMode' => 'host',
                            'UTSMode' => '',
                            'CapDrop' => undef,
                            'MemorySwap' => 0,
                            'KernelMemory' => 0,
                            'MemoryReservation' => 0,
                            'Binds' => [
                                       ],
                            'BlkioWeightDevice' => undef,
                            'BlkioDeviceReadIOps' => undef,
                            'BlkioWeight' => 0,
                            'CgroupParent' => '',
                            'SecurityOpt' => [
                                               'label:disable'
                                             ],
                            'BlkioDeviceReadBps' => undef,
                            'ShmSize' => 67108864,
                            'Ulimits' => undef,
                            'LogConfig' => {
                                             'Type' => 'json-file',
                                             'Config' => {}
                                           },
                            'ContainerIDFile' => '',
                            'Dns' => [],
                            'Links' => undef,
                            'Memory' => 0,
                            'IpcMode' => '',
                            'PortBindings' => {},
                            'CpuQuota' => 0,
                            'ConsoleSize' => [
                                               0,
                                               0
                                             ],
                            'Devices' => [],
                            'CpusetMems' => '',
                            'GroupAdd' => undef,
                            'RestartPolicy' => {
                                                 'MaximumRetryCount' => 0,
                                                 'Name' => 'always'
                                               },
                            'MemorySwappiness' => -1,
                            'PidMode' => 'host',
                            'OomScoreAdj' => 0,
                            'VolumesFrom' => undef,
                            'CpusetCpus' => '',
                            'BlkioDeviceWriteBps' => undef,
                            'BlkioDeviceWriteIOps' => undef,
                            'DnsSearch' => [],
                            'VolumeDriver' => '',
                            'DnsOptions' => [],
                            'CapAdd' => [
                                          'NET_ADMIN',
                                          'SYS_ADMIN'
                                        ],
                            'CpuShares' => 0,
                            'ExtraHosts' => undef,
                            'CpuPeriod' => 0
                          },
          'HostnamePath' => '/var/lib/docker/containers/568468ea1b56f6420c06f2e4a8da3e01af3aee91719ce6612030ff9afca82510/hostname',
          'AppArmorProfile' => '',
          'State' => {
                       'Pid' => 3716,
                       'ExitCode' => 0,
                       'Status' => 'running',
                       'StartedAt' => '2016-05-15T09:39:48.220743711Z',
                       'FinishedAt' => '0001-01-01T00:00:00Z',
                       'Error' => ''
                     },
          'LogPath' => '/var/lib/docker/containers/568468ea1b56f6420c06f2e4a8da3e01af3aee91719ce6612030ff9afca82510/568468ea1b56f6420c06f2e4a8da3e01af3aee91719ce6612030ff9afca82510-json.log',
          'HostsPath' => '/var/lib/docker/containers/568468ea1b56f6420c06f2e4a8da3e01af3aee91719ce6612030ff9afca82510/hosts',
          'RestartCount' => 0,
          'GraphDriver' => {
                             'Data' => undef,
                             'Name' => 'aufs'
                           },
          'Mounts' => [
                      ],
          'ExecIDs' => [
                         '089373efe3a4dc2c07e3297f27d1d01e6ff81b59cfd8f96ed06d05ac34abec13'
                       ],
          'ProcessLabel' => '',
          'Name' => '/dfwfw-1',
          'Args' => [],
          'Created' => '2016-05-15T09:39:47.908577437Z',
          'ResolvConfPath' => '/var/lib/docker/containers/568468ea1b56f6420c06f2e4a8da3e01af3aee91719ce6612030ff9afca82510/resolv.conf',
          'Path' => 'bash',
          'Image' => 'sha256:f376d6779b3dd74565fecb26dbce665501282cfc5e731f70e4a749b58c10b4a3',
          'Driver' => 'aufs',
          'NetworkSettings' => {
                                 'SecondaryIPv6Addresses' => undef,
                                 'SandboxKey' => '/var/run/docker/netns/default',
                                 'MacAddress' => '',
                                 'LinkLocalIPv6PrefixLen' => 0,
                                 'Bridge' => '',
                                 'Networks' => {
                                                 'host' => {
                                                             'Links' => undef,
                                                             'GlobalIPv6PrefixLen' => 0,
                                                             'IPAMConfig' => undef,
                                                             'IPv6Gateway' => '',
                                                             'IPPrefixLen' => 0,
                                                             'MacAddress' => '',
                                                             'IPAddress' => '',
                                                             'Aliases' => undef,
                                                             'NetworkID' => '5c47fb464fbb10f0d58f92818caeb31b4674421a46a561814d4f4c56c34c0338',
                                                             'EndpointID' => '4eab38740a1887badaa7c5770ec58086d7cac4f15fb0fab3d646d264be44290d',
                                                             'Gateway' => '',
                                                             'GlobalIPv6Address' => ''
                                                           }
                                               },
                                 'SandboxID' => '874a5c574a579ca3a68cd0da7259b10d65de4a9a376807632ed156c8bf205e5e',
                                 'GlobalIPv6PrefixLen' => 0,
                                 'IPv6Gateway' => '',
                                 'IPPrefixLen' => 0,
                                 'SecondaryIPAddresses' => undef,
                                 'IPAddress' => '',
                                 'LinkLocalIPv6Address' => '',
                                 'EndpointID' => '',
                                 'Gateway' => '',
                                 'Ports' => {},
                                 'GlobalIPv6Address' => ''
                               },
          'Id' => '568468ea1b56f6420c06f2e4a8da3e01af3aee91719ce6612030ff9afca82510'
        }
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
