FROM debian:jessie

MAINTAINER imre.rad@search-lab.hu

ADD dfwfw-install /bin/
RUN dfwfw-install

ADD dfwfw /opt/dfwfw/

ENTRYPOINT ["/opt/dfwfw/dfwfw.pl"]
