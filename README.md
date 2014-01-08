docker-ssh
==========

TL;DR
if you can't seem to ssh into your container and you think it's
selinux playing tricks, and your container is derived from
ubuntu precise, have a look at this.

Long version

This Dockerfile is a proof of concept addressing the following issue:

Your host is running an selinux-enabled kernel with policies set.
Your docker containers are derived from the ubuntu 12.04 (precise)
image in the Docker repo, which has the selinux libraries, but
there is no mounted selinuxfs, which causes various things to fail.

A typical example: you try to run sshd as a daemon in the container
and ssh in from the host, and while your password is accepted, the
connection is immediately closed by sshd afterwards.  When you turn
on debugging you see that one of the things sshd says is
'SELinux support enabled'.

You could do what some posts suggest and mess around with the
pam modules.  That will solve the sshd problem but nothing else.
See https://groups.google.com/forum/#!topic/docker-user/73AiwlZEgY4

Or... you could install a modified form of the libselinux1 library
in your image, mount selinuxfs from your host read-only at
the docker run command line, and sshd and other programs will
decide that selinux is disabled and act accordingly.

Instructions for use

* modify the Dockerfile so that root has some password other than
  'testing' unless you would like everyone to try to hack into your container(s)
* docker build against the included Dockerfile
* determine where selinuxfs is mounted on your host
  e.g. 'mount | grep selinux'
* docker run -v  <path-to-selinux-fs>:/selinux:ro <new-image-id> /usr/sbin/sshd -D
  where path-to-selinux-fs is the path on your host that you found in the previous step
  so e.g. if selinuxfs on our host is at /sys/fs/selinux then you would run
  docker run -v /sys/fs/selinux:/selinux:ro <new-image-id> /usr/sbin/sshd -D
* to get the container id of the running instance:
    docker ps
* to get the ip address of the instance:
    docker inspect <container-id> | grep IPAddress
* ssh -l root <ip-address-here>   (and use the password specified in the Dockerfile)
* profit!

A few words about the libselinux1 hack

Newer versions of the library than are included in precise have a nice
feature which permits mock and other things to work well against a
chroot environment, and that is that if selinuxfs is mounted ro,
selinux is treated as disabled by the library calls.  I hacked this
change in, without updating anything else.

Why, you may ask, can't we just not mount it at all?  Isn't that good enough?
No, sadly, because the library is clever enough, if it doesn't find a mount
point at the expected location, to check /proc/filesystems to see if
such a filesystem is listed, and in a Docker container where the host
has selinuxfs mounted, that will show up in /proc in all containers too.

What about Fedora containers, you may wonder?  I have no idea what
they do about selinux, I haven't played with them at all.

Caveat

Is this secure?  Doubtful.  Should you run this on a production container?
Beats me.  Will it work for anything else?  No idea.
