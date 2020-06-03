#!/bin/bash
set -e

zdgtdui_version=v1.1
kube_version_list=(1.16.10 1.17.6 1.18.3)


get_kube_internet(){

kube_version=v$1

if [ ! -d roles/master/files/${kube_version} ]
  then 
    mkdir -p roles/master/files/${kube_version}
fi 

if [ ! -d roles/node/files/${kube_version} ]
  then
    mkdir -p roles/node/files/${kube_version}
fi
wget https://storage.googleapis.com/kubernetes-release/release/${kube_version}/kubernetes-server-linux-amd64.tar.gz
tar zxvf kubernetes-server-linux-amd64.tar.gz
cp kubernetes/server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl} roles/master/files/${kube_version}/
cp kubernetes/server/bin/{kubelet,kube-proxy} roles/node/files//${kube_version}/
rm -rf kubernetes
rm -rf kubernetes-server-linux-amd64.tar.gz

}

get_kube(){

kube_version=v$1

if [ ! -d roles/master/files/${kube_version} ]
  then 
    mkdir -p roles/master/files/${kube_version}
fi 

if [ ! -d roles/node/files/${kube_version} ]
  then
    mkdir -p roles/node/files/${kube_version}
fi
wget http://3.1.20.1:8081/kubernetes/${kube_version}/kubernetes-server-linux-amd64.tar.gz
tar zxvf kubernetes-server-linux-amd64.tar.gz
cp kubernetes/server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl} roles/master/files/${kube_version}/
cp kubernetes/server/bin/{kubelet,kube-proxy} roles/node/files//${kube_version}/
rm -rf kubernetes
rm -rf kubernetes-server-linux-amd64.tar.gz

}


for i in ${kube_version_list[*]}
  do
  if [ ! $1 ];then
      get_kube_internet $i
    else
      get_kube $i
    fi

  done

docker build --network=host -t zdgtdui:$zdgtdui_version .