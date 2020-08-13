FROM centos:7.6.1810
#docker build --network=host -t zdgtdui:v1 .

LABEL MAINTAINER=wanghq@bjzdgt.com

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python get-pip.py

RUN yum install openssh-clients openssh sshpass openssl -y

COPY requirements.txt /

RUN pip install -r /requirements.txt -i http://mirrors.aliyun.com/pypi/simple/   --trusted-host mirrors.aliyun.com

RUN mkdir /mnt/zdgtdui && mkdir /mnt/secrets && touch /mnt/secrets/ansible_running.pid

COPY . /mnt/zdgtdui
WORKDIR /mnt/zdgtdui

CMD ["/usr/bin/tail","-f","../secrets/ansible_running.pid"]