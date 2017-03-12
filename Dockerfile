FROM debian:jessie

ADD dfwfw /opt/dfwfw/
RUN /opt/dfwfw/dfwfw-install

ENTRYPOINT ["/opt/dfwfw/dfwfw.pl"]
