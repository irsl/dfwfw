FROM debian:jessie

MAINTAINER imre.rad@search-lab.hu

ADD dfwfw /opt/dfwfw/
RUN /opt/dfwfw/dfwfw-install

ENTRYPOINT ["/opt/dfwfw/dfwfw.pl"]
