# DFWFW configuration file (dfwfw.conf)

The DFWFW configuration file is JSON formatted with a hash as root node, which might contain the following keys:

 - docker_socket: Specification of the Docker socket. Default value is `http:/var/run/docker.sock/`. (Note the trailing slash! [Details][AltSocket])
 - external_network_interface: Name of the network interface with the default gateway. Default is `eth0`.
 - initialization: Initial firewall rules for the host.
 - container_to_container: Container to container firewall rules
 - container_to_wider_world: Container to wider world rules
 - container_to_host: Container to host rules
 - wider_world_to_container: Wider world to container rules
 - container_internals: Container internal rules

### initialization

The initialization key takes JSON hashes of the supported netfilter tables. Their values are JSON arrays with the actual
firewall rules you want to have as your initial configuration. Upon startup, DFWFW commits these rules to netfilter.

If you create the DFWFW_INPUT/DFWFW_FORWARD/etc. chains and also rules jumping to them, then DFWFW won't create them by
itself (which is the default behavior).

For example, a useful set of initial rules would look like this:

```
   "initialization": {
      "filter": [
         ":DFWFW_INPUT - [0:0]",
         ":HOST_OUTBOUND - [0:0]",
         ":HOST_INCOMING - [0:0]",

         "-P INPUT DROP",
         "-F INPUT",
         "-A INPUT -m state --state INVALID -j DROP",
         "-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT",
         "-A INPUT -j DFWFW_INPUT",
         "-A INPUT -m state --state NEW -j HOST_INCOMING",

         "-F HOST_INCOMING",
         "-A HOST_INCOMING -p tcp --dport 22 -j ACCEPT",
         "-A HOST_INCOMING -p icmp -j ACCEPT",

         "-P OUTPUT DROP",
         "-F OUTPUT",
         "-A OUTPUT -m state --state INVALID -j DROP",
         "-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT",
         "-A OUTPUT -m state --state NEW -j HOST_OUTBOUND",

         "-F HOST_OUTBOUND",
         "-A HOST_OUTBOUND -p udp --dport 53 -j ACCEPT",
         "-A HOST_OUTBOUND -p tcp --dport 80 -j ACCEPT",
         "-A HOST_OUTBOUND -p tcp --dport 443 -j ACCEPT",
         "-A HOST_OUTBOUND -p icmp -j ACCEPT",

         "-P FORWARD DROP"
      ]
   },
```

In this example, we created and thus specified the location of DFWFW_INPUT chain among the INPUT chain rules.
We did not touch the DFWFW_FORWARD chain, letting DFWFW create it upon startup.
Note, that we did not open additional ports on HOST_INCOMING, since we intend to run only the SSH service on the host,
all other services would be dockerized, their firewall rules are covered in the `wider_world_to_container` section.

### container_to_container

You can specify rules to affect communication between Docker containers. 
By design, it is not possible to grant communication between containers not being on the same network.

The following keys can be specified inside `container_to_container`:
 - default_policy: see `default_policy_definition`
 - rules: array of `container_to_container_rule_definition`

The following keys can be specified inside `container_to_container_rule_definition`:
 - network: see `network_definition`
 - src_container: optional, see `container_definition`
 - dst_container: optional, see `container_definition`
 - filter: optional string, additional iptables filters like `-p tcp --dport 25`
 - action: see `action_definition`

### container_to_wider_world
You can specify rules affecting the communication originating inside a container towards the wider world.

The following keys can be specified inside `container_to_wider_world`:
 - default_policy: see `default_policy_definition`
 - rules: array of `container_to_wider_world_rule_definition`

The following keys can be specified inside `container_to_wider_world_rule_definition`:
 - network: see `network_definition`
 - src_container: optional, see `container_definition`
 - filter: optional string, additional iptables filters like `-p tcp --dport 25`
 - action: see `action` definition

Note:
By specifying `bridge` as network, you can configure dedicated rules for build-time containers.
 
### container_to_host
You can specify rules affecting the communication originating inside a container towards services running directly on the host.

The following keys can be specified inside `container_to_host`:
 - default_policy: see `default_policy_definition`
 - rules: array of `container_to_host_rule_definition`

The following keys can be specified inside `container_to_wider_world_rule_definition`:
 - network: see `network_definition`
 - src_container: optional, see `container_definition`
 - filter: optional string, additional iptables filters like `-p tcp --dport 25`
 - action: see `action` definition

### wider_world_to_container
Using wider_world_to_container rules you can make services running inside your containers accessible from the outside world. DFWFW configures DNAT rules in the background according to the configuration.

The following keys can be specified inside `container_to_host`:
 - rules: array of `wider_world_to_container_rule_definition`

The following keys can be specified inside `wider_world_to_container_rule_definition`:
 - network: see `network_definition`
 - dst_container: see `container_definition`
 - expose_port: optional, see `expose_port_definition`

### container_internals
Using container_internals you can inject iptables rules into your containers for additional security. DFWFW needs access to the host process namespace and also `SYS_ADMIN` capability to be able to do this.

The following keys can be specified inside `container_internals`:
 - rules: array of `container_internals_rule_definition`

The following keys can be specified inside `container_internals_rule_definition`:
 - container: see `container_definition`
 - table: optional, see `table` definition, default is `filter`
 - rules: see `container_internals_iptables_rule_definition`

### network_definition

The network key is a JSON string, which can be one the following:

 - Name of a network. This is a syntax sugar of the following: `"Name == name_of_the_network"`
 - An expression of key operator value

The expression components:
 - key can be: `Name`, `IdShort` or `Id`
   - Name refers to the name of the network
   - IdShort refers to the short (12 letters) ID of the network
   - Id refers to the full ID of the network (so the full SHA256 string)
 - operator can be: `==`, `=~` or `!~`
   - `==`: the equality operator
   - `=~`: matching via regular expression operator
   - `!~`: negated matching via regular expression operator
 - value can be: anything you want your expression match. For regular expressions the backslashes must be escaped since the expression is parsed by a JSON library first.

An example:
```
"network": "Name =~ ^web(-testing)?$"
```

### container_definition       

The container/src_container/dst_container key is a JSON string, which can be one the following:

 - Name of a container. This is a syntax sugar of the following: `"Name == name_of_the_container"`
 - An expression of key operator value

The expression components:
 - key can be: `Name`, `IdShort` or `Id`
   - Name refers to the name of the container
   - IdShort refers to the short (12 letters) ID of the container
   - Id refers to the full ID of the container (so the full SHA256 string)
 - operator can be: `==`, `=~` or `!~`
   - `==`: the equality operator
   - `=~`: matching via regular expression operator
   - `!~`: negated matching via regular expression operator
 - value can be: anything you want your expression match. For regular expressions the backslashes must be escaped since the expression is parsed by a JSON library first.

An example:
```
"container": "Name =~ ^php-\\d+"
```

### expose_port_definition

The `expose_port` key can be a JSON string or array. If `expose_port` is missing from a wider_world_to_container rule definition then DFWFW would iterate over all the matching containers and use their exposed port (the ones specified via the `-p` flag on `docker run` commandline or via the `EXPOSE` command in the respective Dockerfile).

The string version can be one of the following versions:
 - a numerical value: a TCP port number
 - port_number slash protocol_specification: 
Examples:
```
8080
80/tcp
53/udp
```

The array version holds array of hashes with the following keys:
 - host_port: port number on the host machine
 - container_port: port number inside the container where the service is listening
 - family: optional, protocol family, default is tcp


### table_definition

The `table` key must be a JSON string holding one of the tables supported by iptables, such as: "filter", "nat", "raw" or "mangle".

### action_definition

The `action` key is a JSON string with the following possible values:
 - ACCEPT
 - DROP
 - REJECT
 - LOG

### default_policy_definition

Default policy is an action, so action definition applies here. If the defaul policy is specified, then a new rule is appended to the end of the chain with the following network definition:
```
"network": "Name =~ .*"
```
The action for this new rule is the same as default policy. This way DFWFW generates a category specific iptables rule on each network according to the specified default policy.


 [AltSocket]: http://search.cpan.org/~sharyanto/LWP-Protocol-http-SocketUnixAlt-0.0204/lib/LWP/Protocol/http/SocketUnixAlt.pm
