FROM centos:7.6.1810
#docker build --network=host -t zdgtdui:v1 .

LABEL MAINTAINER=wanghq@bjzdgt.com

RUN yum install openssh-clients openssh sshpass openssl \
     zlib-devel bzip2-devel openssl-devel ncurses-devel \
     sqlite-devel readline-devel tk-devel gdbm-devel db4-devel \
     libpcap-devel xz-devel wget -y

RUN mkdir /root/python36 && wget https://www.python.org/ftp/python/3.6.8/Python-3.6.8.tgz && tar -xvf Python-3.6.8.tgz \
     && cd Python-3.6.8 && ./configure --prefix=/root/python36 && make && make install

# RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python get-pip.py

RUN ln -s /root/python36/bin/python3.6 /usr/bin/python3
RUN ln -s /root/python36/bin/pip3 /usr/bin/pip3

COPY requirements.txt /

RUN pip3 install -r /requirements.txt -i http://mirrors.aliyun.com/pypi/simple/   --trusted-host mirrors.aliyun.com

RUN mkdir /mnt/zdgtdui && mkdir /mnt/secrets && touch /mnt/secrets/ansible_running.pid

COPY . /mnt/zdgtdui
WORKDIR /mnt/zdgtdui

ENV PATH=$PATH:/root/python36/bin/


CMD ["/usr/bin/tail","-f","../secrets/ansible_running.pid"]