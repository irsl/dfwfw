FROM debian:jessie

MAINTAINER imre.rad@search-lab.hu

RUN apt-get update && \
    apt-get install -y libfile-slurp-perl libjson-xs-perl libwww-perl iptables ca-certificates && \
    apt-get install -y build-essential cpanminus wget && \
    cpanm LWP/Protocol/http/SocketUnixAlt.pm && \
    apt-get remove -y build-essential cpanminus wget && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

ADD dfwfw /opt/dfwfw/

ENTRYPOINT ["/opt/dfwfw/dfwfw.pl"]
