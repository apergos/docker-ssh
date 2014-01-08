FROM ubuntu:12.04

# set up apt properly
ENV DEBIAN_FRONTEND noninteractive

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list

RUN apt-get update
RUN apt-get install -y apt-utils

# set up ppa for libselinux
RUN apt-get install -y python-software-properties
RUN add-apt-repository ppa:ariel-wikimedia/ppa
RUN apt-get update

# no steenkin selinux
RUN apt-get install -y libselinux1

# ssh access into container
RUN apt-get install -y openssh-server
RUN mkdir -p /var/run/sshd 
RUN echo 'root:testing' |chpasswd

EXPOSE 22
CMD /usr/sbin/sshd -D
