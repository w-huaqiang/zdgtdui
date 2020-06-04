
### 一、准备

#### 1.1、build构建kubedui 容器镜像

```bash
git clone git@3.1.11.12:deliver/zdgtdui.git
cd zdgtdui
./build.sh buffer

```



### 二、准备资源


#### 2.1、启动kubedui

```bash

docker run -d --network=host --name zdgtdui zdgtdui:v1.1
docker exec  -ti zdgtdui bash

```

#### 2.2、修改相关参数

请按照inventory格式修改对应资源

```
[all]
3.1.20.21  hostname=node01 ansible_ssh_user=root ansible_ssh_pass=password
3.1.20.22  hostname=node02 ansible_ssh_user=root ansible_ssh_pass=password
3.1.20.23  hostname=node03 ansible_ssh_user=root ansible_ssh_pass=password
3.1.20.24  hostname=node04 ansible_ssh_user=root ansible_ssh_pass=password
3.1.20.25  hostname=node05 ansible_ssh_user=root ansible_ssh_pass=password
3.1.20.26  hostname=node06 ansible_ssh_user=root ansible_ssh_pass=password

[etcd]
3.1.20.21  
3.1.20.22
3.1.20.23


[master]
3.1.20.21  
3.1.20.22
3.1.20.23


[node]
3.1.20.24
3.1.20.25
3.1.20.26

[haproxy]
3.1.20.21  type=MASTER priority=100
3.1.20.22 type=BACKUP priority=90
3.1.20.22 type=BACKUP priority=80
[all:vars]
lb_port=9443
vip=3.1.20.28
```


###  三、修改相关配置

编辑group_vars/all.yml文件，填入自己的配置

| 配置项                | 说明                                                         |
| --------------------- | ------------------------------------------------------------ |
| ssl_dir               | 签发ssl证书保存路径，ansible控制端机器上的路径。默认签发10年有效期的证书 |
| kubernetes_version        | 安装kubernetes 的版本  |
| yum_config_internet        | 安是否使用互联网上面的yum源  |
| docker_version        | 可通过查看版本yum list docker-ce --showduplicates\|sort -rn |
| apiserver_domain_name | kube-apiserver的访问域名。此playbook中默认在 |
| service_ip_range      | 指定k8s集群service的网段                                     |
| pod_ip_range          | 指定k8s集群pod的网段                                         |
| calico_ipv4pool_ipip  | 指定k8s集群使用calico的ipip模式或者bgp模式，Always为ipip模式，off为bgp模式。注意bgp模式不适用于公有云环境。当值为off的时候，切记使用引号`""`引起来。 |

- 请将etcd安装在独立的服务器上，不建议跟master安装在一起。数据盘尽量使用SSD盘。
- Pod 和Service IP网段建议使用保留私有IP段，建议（Pod IP不与Service IP重复，也不要与主机IP段重复）：
  - Pod 网段
    - A类地址：10.0.0.0/8
    - B类地址：172.16-31.0.0/12-16
    - C类地址：192.168.0.0/16
  - Service网段
    - A类地址：10.0.0.0/16-24
    - B类地址：172.16-31.0.0/16-24
    - C类地址：192.168.0.0/16-24




### 四、使用方法

#### 4.1、部署集群

先执行格式化磁盘并挂载目录。如已经自行格式化磁盘并挂载，请跳过此步骤。

```
ansible-playbook fdisk.yml -i inventory -l etcd -e "disk=sdb dir=/var/lib/etcd"
ansible-playbook fdisk.yml -i inventory -l master,node -e "disk=sdb dir=/var/lib/docker"
```
安装k8s
```
ansible-playbook -i inventory cluster.yml
```

如是公有云环境，不安装`haproy`和`keepalived`则执行：

```
ansible-playbook k8s.yml -i inventory --skip-tags=install_haproxy,install_keepalived
```


#### 4.3、扩容mater节点

扩容master前，请将{{ssl_dir}}目录中的kube-apiserver的证书备份并移除。

扩容时，请不要在inventory文件master组中保留旧服务器信息。

```
ansible-playbook fdisk.yml -i inventory -l master -e "disk=sdb dir=/var/lib/docker"
ansible-playbook k8s.yml -i inventory -l master -t init
ansible-playbook k8s.yml -i inventory -l master -t cert,install_master,install_docker,install_node,install_ceph --skip-tags=bootstrap,cni
```



#### 4.4、扩容node节点

扩容时，请不要在inventory文件node组中保留旧服务器信息。

```
ansible-playbook fdisk.yml -i inventory -l node -e "disk=sdb dir=/var/lib/docker"
ansible-playbook k8s.yml -i inventory -l node -t init
ansible-playbook k8s.yml -i inventory -l node -t install_docker,install_node,install_ceph --skip-tags=create_label,cni
```



#### 4.5、替换集群证书

先备份并删除证书目录{{ssl_dir}}，然后执行以下步骤重新生成证书并分发证书。

```
ansible-playbook k8s.yml -i inventory -t cert,dis_certs
```

然后依次重启每个节点。

重启etcd

```
ansible -i inventory etcd -m systemd -a "name=etcd state=restarted"
```

验证etcd

```
ETCDCTL_API=3 etcdctl \
  --endpoints=https://172.16.100.201:2379,https://172.16.100.202:2379,https://172.16.100.203:2379 \
  --cacert=/etc/kubernetes/pki/etcd-ca.pem \
  --cert=/etc/kubernetes/pki/etcd-client.pem \
  --key=/etc/kubernetes/pki/etcd-client.key \
  endpoint health 
```

逐个删除旧的kubelet证书

```
ansible -i inventory master,node -l master,node -m shell -a "rm -rf /etc/kubernetes/pki/kubelet-*"
```

- `-l`参数更换为具体节点IP或者组。

逐个重启节点

```
ansible-playbook k8s.yml -i inventory -l master-01 -t restart_apiserver,restart_controller,restart_scheduler,restart_kubelet,restart_proxy,healthcheck,approve_node
```

- 如calico、metrics-server等服务也使用了etcd，请记得一起更新相关证书。
-  `-l`参数更换为具体节点IP。



#### 4.6、升级kubernetes版本

在`group_vars/all.yml`中先将`kubernetes_version`修改为新版本

```
ansible-playbook cluster.yml -i inventory -t kube_master,kube_node
```

重启每个kubernetes组件。

```bash
ansible-playbook k8s.yml -i inventory -l master -t restart_apiserver,restart_controller,restart_scheduler

ansible-playbook k8s.yml -i inventory -l master,node -t restart_kubelet,restart_proxy
```


