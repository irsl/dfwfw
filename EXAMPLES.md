# DFWFW examples

### Docker configuration

In the following examples, we have the following Docker configuration:

Networks:
  - web: 172.18.0.0/16
  - mail: 172.19.0.0/16

Containers specify their network memberships in their names:
  - web-1: 172.18.0.2
  - web-2: 172.18.0.3
  - mail-1: 172.19.0.2
  - mail-2: 172.19.0.3
  - web-mail-1: 172.18.0.4 and 172.19.0.4

## container to container rules

### Example #1

Lets say we want to allow connections from web-1 to tcp port 80 of web-2. We can define the following rule:
```
   "container_to_container": {
       "rules": [
          {
             "network": "web",
             "src_container": "web-1",
             "dst_container": "web-2",
             "filter": "-p tcp --dport 80 -m state --state NEW ",
             "action": "ACCEPT"
          }

       ]
   }
```

DFWFW would generate the following rules in the DFWFW_FORWARD chain:
```
Chain DFWFW_FORWARD (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            state INVALID
    0     0 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            state RELATED,ESTABLISHED
    0     0 ACCEPT     tcp  --  br-78ba18a93c68 br-78ba18a93c68  172.18.0.2           172.18.0.3           tcp dpt:80 state NEW
    0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0
```
This chain is referenced from the `FORWARD` chain. The first two rules are for initializing the stateful behavior.
The third iptables rule is generated as direct consequence of the rule we specified in the configuration file.
The forth iptables rule is the default tail of the chain, as DFWFW prefers whitelist based approach of specifying the rules.

### Example #2

Lets say there is a server running on port 80 on each of the containers of web network and we want to grant access from any of it to any of it. We can describe this situation by simple not specifying anything as src and dst_container at all:

```
   "container_to_container": {
       "rules": [
          {
             "network": "web",
             "filter": "-p tcp --dport 80 -m state --state NEW ",
             "action": "ACCEPT"
          }

       ]
   }
```

DFWFW would generate the following rules:
```
Chain DFWFW_FORWARD (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            state INVALID
    0     0 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            state RELATED,ESTABLISHED
    0     0 ACCEPT     tcp  --  br-78ba18a93c68 br-78ba18a93c68  0.0.0.0/0            0.0.0.0/0            tcp dpt:80 state NEW
    0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

### Example #3

Lets say web-2 and web-mail-1 containers are SSL enabled and we want to grant access to them from web-1. We can use the following rule:

```
   "container_to_container": {
       "rules": [
          {
             "network": "web",
             "src_container": "web-1",
             "dst_container": "Name =~ ^(web-2|web-mail-1)$",
             "filter": "-p tcp --dport 443 -m state --state NEW ",
             "action": "ACCEPT"
          }

       ]
   }
```

DFWFW would generate the following rules:
```
Chain DFWFW_FORWARD (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            state INVALID
    0     0 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            state RELATED,ESTABLISHED
    0     0 ACCEPT     tcp  --  br-78ba18a93c68 br-78ba18a93c68  172.18.0.2           172.18.0.4           tcp dpt:443 state NEW
    0     0 ACCEPT     tcp  --  br-78ba18a93c68 br-78ba18a93c68  172.18.0.2           172.18.0.3           tcp dpt:443 state NEW
    0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0
```


More examples are coming.
