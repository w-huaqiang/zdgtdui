FROM dgutierrez1287/yum-repo:latest

MAINTAINER wanghq@bjzdgt.com

RUN rm -rf /etc/yum.repos.d/*

COPY docker-ce.repo /etc/yum.repos.d/
COPY CentOS-Base.repo /etc/yum.repos.d/
COPY epel.repo /etc/yum.repos.d/
COPY down_repo.sh /

RUN sh down_repo.sh