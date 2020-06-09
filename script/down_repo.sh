#!/bin/bash
#docker run -d -p 80:80 -v /opt/repo:/repo dgutierrez1287/yum-repo


repo_dir=/repo
package=(vim \
        mtr \
        nscd \
        curl \
        wget \
        lsof \
        lrzsz \
        rsync \
        telnet \
        bash-completion \
        nmap-ncat \
        net-tools \
        nfs-utils \
        yum-utils \
        etcd \
        keepalived \
        haproxy \
        docker-ce-19.03.5)



#download package
for i in ${package[*]}
  do
    yum install --downloadonly --downloaddir=${repo_dir} $i
  done