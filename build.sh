#!/bin/bash
set -e
LOCAL_DIR=$(dirname $(readlink -f "$0"))

zdgtdui_version=v1.1
kube_version_list=(1.16.10 1.17.6 1.18.3)

# the images which you should pull
kube_images=(calico/cni:v3.15.1 \
calico/cni:v3.15.1 \
calico/pod2daemon-flexvol:v3.15.1 \
calico/node:v3.15.1 \
calico/kube-controllers:v3.15.1 \
rancher/pause:3.1)



# get prameters
parameters=$(getopt -o a  -l include-yum,include-registry -n "$0" -- "$@")
eval set -- "${parameters}"

while true; do
  case "$1" in
      -a)
        build_all=true
        shift
        ;;
      --include-yum)
        build_yum=true
        shift
        ;;
      --include-registry)
        build_registry=true
        shift
        ;;
      --)
        shift
        break;;
      *) echo "wrong";exit 1;;
    esac
done


get_images(){
    
    docker run -d --name zdgtdui-registry -p 5000:5000 -v /opt/zdgtregistry:/var/lib/registry -e REGISTRY_STORAGE_DELETE_ENABLED="true" registry
    for i in ${kube_images[*]}
        do
          docker pull $i
          docker tag $i 127.0.0.1:5000/$i
          docker push 127.0.0.1:5000/$i
        done
}




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
if [ ! -f roles/master/files/${kube_version}/kube-apiserver ];then
  wget https://storage.googleapis.com/kubernetes-release/release/${kube_version}/kubernetes-server-linux-amd64.tar.gz
  tar zxvf kubernetes-server-linux-amd64.tar.gz
  cp kubernetes/server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl} roles/master/files/${kube_version}/
  cp kubernetes/server/bin/{kubelet,kube-proxy} roles/node/files//${kube_version}/
  rm -rf kubernetes
  rm -rf kubernetes-server-linux-amd64.tar.gz
fi
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
cp kubernetes/server/bin/{kubelet,kube-proxy} roles/node/files/${kube_version}/
rm -rf kubernetes
rm -rf kubernetes-server-linux-amd64.tar.gz

}

if [ $build_registry ];then
  get_images
fi

for i in ${kube_version_list[*]}
  do
    if [ "$1" == "buffer" ];then
      get_kube $i     
    else
      get_kube_internet $i
    fi

  done

docker build --network=host -t zdgtdui:$zdgtdui_version .
docker save zdgtdui:$zdgtdui_version -o zdgtdui.tar.gz
docker save registry -o zdgtregistry.tar.gz

echo '''################# info ###########################
# zdgtdui ansible-playbook image: zdgtdui.tar.gz  
# registry image: zdgtregistry.tar.gz             
# registry dir: /opt/zdgtregistry
# docker run -d --name zdgtdui-registry -p 5000:5000 \
    -v /opt/zdgtregistry:/var/lib/registry registry
#########################################################'''