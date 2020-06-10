FROM centos:centos7.6.1810
LABEL maintainer="wang huaqiang <wanghq@bjzdgt.com>"


RUN rm -rf /etc/yum.repos.d/*

COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf
COPY docker-ce.repo /etc/yum.repos.d/
COPY CentOS-Base.repo /etc/yum.repos.d/
COPY epel.repo /etc/yum.repos.d/


RUN yum -y install epel-release && \
    yum -y update && \
    yum -y install supervisor createrepo yum-utils nginx && \
    yum clean all

RUN mkdir -p /logs && \
    mkdir -p /repo
    
RUN yumdownloader --resolve --destdir=/repo vim \
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
        python-chardet \
        libxml2-python \
        python-kitchen \
        yum-utils \
        etcd \
        keepalived \
        haproxy \
        docker-ce-19.03.5

EXPOSE 80
VOLUME /repo /logs

CMD ["/usr/sbin/nginx", "-c","/etc/nginx/nginx.conf","-g", "daemon off;"]