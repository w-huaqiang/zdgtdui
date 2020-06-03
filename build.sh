#!/bin/bash

zdgtdui_version=v1.1
kube_version_list=(1.16.8 1.16.10 1.17.6 1.18.3)


get_kube(){

kube_version=v$1

if [ ! -d roles/master/${kube_version}/files ]
  then 
    mkdir -p roles/master/${kube_version}/files
fi 

if [ ! -d roles/node/${kube_version}/files ]
  then
    mkdir -p roles/node/${kube_version}/files
fi
wget https://storage.googleapis.com/kubernetes-release/release/${kube_version}/kubernetes-server-linux-amd64.tar.gz
tar zxvf kubernetes-server-linux-amd64.tar.gz
cp kubernetes/server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl} roles/master/files/${kube_version}/
cp kubernetes/server/bin/{kubelet,kube-proxy} roles/node/files//${kube_version}/
rm -rf kubernetes
rm -rf kubernetes-server-linux-amd64.tar.gz

}

for i in ${kube_version_list[*]}
  do
    get_kube $i
  done

docker build --network=host -t zdgtdui:$zdgtdui_version .