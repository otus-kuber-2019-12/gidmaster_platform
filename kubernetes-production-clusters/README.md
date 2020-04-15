# Домашнее задание 14

[Содержание](../README.md)

*NB: Использован дистрибутив `Ubuntu 18.04` с предустановленным `Ansible`, `kubectl` и `gcould` и `gsuit` ПО.*

1. Создание нод для кластера:

    Создадим ноды с помощью `terraform` и запровиженим их `ansible`

    *NB: опущен момент с добавлением сервис аккаунта и выдачей ему разрешений на работу с GCP*

    ```bash
    cd terraform
    rm ~/.ssh/known_hosts
    terrafom init
    terraform apply --auto-approve=true
    cd ../ansible
    ansible-playbook provision.yaml -i inventory.compute.gcp.yml
    cd ..
    ```

2. Установка кластера:

    *NB: опущен момент с добавлением SSH ключей на виртуальные машины*

    ```bash
    ssh gidmaster@104.197.195.31
    ```

    Создадим настроим мастер ноду при помощи kubeadm, для этого на ней выполним:

    ```bash
    kubeadm init --pod-network-cidr=192.168.0.0/24
    sudo -i
    kubeadm init --pod-network-cidr=192.168.0.0/24

    I0412 21:48:21.576717   19581 version.go:251] remote version is much newer: v1.18.1; falling back to: stable-1.17
    W0412 21:48:21.608508   19581 validation.go:28] Cannot validate kube-proxy config - no validator is available
    W0412 21:48:21.608546   19581 validation.go:28] Cannot validate kubelet config - no validator is available
    [init] Using Kubernetes version: v1.17.4
    [preflight] Running pre-flight checks
    [preflight] Pulling images required for setting up a Kubernetes cluster
    [preflight] This might take a minute or two, depending on the speed of your internet connection
    [preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
    [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
    [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
    [kubelet-start] Starting the kubelet
    [certs] Using certificateDir folder "/etc/kubernetes/pki"
    [certs] Generating "ca" certificate and key
    [certs] Generating "apiserver" certificate and key
    [certs] apiserver serving cert is signed for DNS names [master-instance-0 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 10.128.0.46]
    [certs] Generating "apiserver-kubelet-client" certificate and key
    [certs] Generating "front-proxy-ca" certificate and key
    [certs] Generating "front-proxy-client" certificate and key
    [certs] Generating "etcd/ca" certificate and key
    [certs] Generating "etcd/server" certificate and key
    [certs] etcd/server serving cert is signed for DNS names [master-instance-0 localhost] and IPs [10.128.0.46 127.0.0.1 ::1]
    [certs] Generating "etcd/peer" certificate and key
    [certs] etcd/peer serving cert is signed for DNS names [master-instance-0 localhost] and IPs [10.128.0.46 127.0.0.1 ::1]
    [certs] Generating "etcd/healthcheck-client" certificate and key
    [certs] Generating "apiserver-etcd-client" certificate and key
    [certs] Generating "sa" key and public key
    [kubeconfig] Using kubeconfig folder "/etc/kubernetes"
    [kubeconfig] Writing "admin.conf" kubeconfig file
    [kubeconfig] Writing "kubelet.conf" kubeconfig file
    [kubeconfig] Writing "controller-manager.conf" kubeconfig file
    [kubeconfig] Writing "scheduler.conf" kubeconfig file
    [control-plane] Using manifest folder "/etc/kubernetes/manifests"
    [control-plane] Creating static Pod manifest for "kube-apiserver"
    [control-plane] Creating static Pod manifest for "kube-controller-manager"
    W0412 21:48:41.903251   19581 manifests.go:214] the default kube-apiserver authorization-mode is "Node,RBAC"; using "Node,RBAC"
    [control-plane] Creating static Pod manifest for "kube-scheduler"
    W0412 21:48:41.904591   19581 manifests.go:214] the default kube-apiserver authorization-mode is "Node,RBAC"; using "Node,RBAC"
    [etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
    [wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
    [apiclient] All control plane components are healthy after 15.502751 seconds
    [upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
    [kubelet] Creating a ConfigMap "kubelet-config-1.17" in namespace kube-system with the configuration for the kubelets in the cluster
    [upload-certs] Skipping phase. Please see --upload-certs
    [mark-control-plane] Marking the node master-instance-0 as control-plane by adding the label "node-role.kubernetes.io/master=''"
    [mark-control-plane] Marking the node master-instance-0 as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
    [bootstrap-token] Using token: lbogp9.vvjv5dhyymdkx0ag
    [bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
    [bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
    [bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
    [bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
    [bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
    [kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
    [addons] Applied essential addon: CoreDNS
    [addons] Applied essential addon: kube-proxy

    Your Kubernetes control-plane has initialized successfully!

    To start using your cluster, you need to run the following as a regular user:

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    You should now deploy a pod network to the cluster.
    Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
    https://kubernetes.io/docs/concepts/cluster-administration/addons/

    Then you can join any number of worker nodes by running the following on each as root:

    kubeadm join 10.128.0.46:6443 --token lbogp9.vvjv5dhyymdkx0ag \
        --discovery-token-ca-cert-hash sha256:b2d51681269cd30d47a768c208ce4881cde81333c71ea80b8ff5f39bc897c351 
    ```

    В выводе будут:
    * команда для копирования конфига kubectl
    * сообщение о том, что необходимо установить сетевой плагин
    * команда для присоединения worker ноды

    Копируем конфиг kubectl

    ```bash
    exit
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```

    Проверяем, что всё завелось:

    ```bash
    kubectl get nodes
    NAME                STATUS     ROLES    AGE     VERSION
    master-instance-0   NotReady   master   2m33s   v1.17.4
    ```

    Устанавливаем сетевой плагин:

    ```bash
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
    ```

3. Подключаем ноды к кластеру:

    Последовательно коннектимся на ноды по SSH и выполняем команду:

    ```bash
    kubeadm join 10.128.0.46:6443 --token lbogp9.vvjv5dhyymdkx0ag \
        --discovery-token-ca-cert-hash sha256:b2d51681269cd30d47a768c208ce4881cde81333c71ea80b8ff5f39bc897c351
    ```

    На мастер ноде смотрим, что ноды добавились:

    ```bash
    kubectl get nodes
    NAME                STATUS   ROLES    AGE     VERSION
    master-instance-0   Ready    master   10m     v1.17.4
    worker-instance-0   Ready    <none>   2m46s   v1.17.4
    worker-instance-1   Ready    <none>   101s    v1.17.4
    worker-instance-2   Ready    <none>   64s     v1.17.4
    ```

4. Демонстрация работы:

    создадим манифест и задеплоим его в кластер.

    ```bash
    kubectl apply -f deployment.yaml

    kubectl get pods
    NAME                               READY   STATUS    RESTARTS   AGE
    nginx-deployment-c8fd555cc-5729s   1/1     Running   0          10s
    nginx-deployment-c8fd555cc-dgbmv   1/1     Running   0          10s
    nginx-deployment-c8fd555cc-n95h6   1/1     Running   0          10s
    nginx-deployment-c8fd555cc-xn47w   1/1     Running   0          10s
    ````

    Работает!

5. Обновление кластера | Обновление мастера:

    Обновим пакеты:

    ```bash
    apt-get update && apt-get install -y kubeadm=1.18.0-00 kubelet=1.18.0-00 kubectl=1.18.0-00
    ```

    ```bash
    kubectl get nodes
    NAME                STATUS   ROLES    AGE   VERSION
    master-instance-0   Ready    master   19m   v1.18.0
    worker-instance-0   Ready    <none>   11m   v1.17.4
    worker-instance-1   Ready    <none>   10m   v1.17.4
    worker-instance-2   Ready    <none>   10m   v1.17.4
    ```

    Видим, что версия мастер ноды стала `v1.18.0`

    Версия ноды определяется на основе `kebelet`, а вот версии API-server, kube-proxy, controller-manager остались прежние.

    Обновим компоненты кластера.

    ```bash
    # План изменений
    kubeadm upgrade plan

    kubeadm upgrade apply v1.18.0
    ```

    Проверим, что все компоненты обновились:

    ```bash
    kubeadm version
    kubeadm version: &version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.0", GitCommit:"9e991415386e4cf155a24b1da15becaa390438d8", GitTreeState:"clean", BuildDate:"2020-03-25T14:56:30Z", GoVersion:"go1.13.8", Compiler:"gc", Platform:"linux/amd64"}
    kubelet --version
    Kubernetes v1.18.0
    kubectl version
    Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.0", GitCommit:"9e991415386e4cf155a24b1da15becaa390438d8", GitTreeState:"clean", BuildDate:"2020-03-25T14:58:59Z", GoVersion:"go1.13.8", Compiler:"gc", Platform:"linux/amd64"}
    Server Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.0", GitCommit:"9e991415386e4cf155a24b1da15becaa390438d8", GitTreeState:"clean", BuildDate:"2020-03-25T14:50:46Z", GoVersion:"go1.13.8", Compiler:"gc", Platform:"linux/amd64"}
    kubectl describe pod kube-apiserver-master-instance-0 -n kube-system
    Name:                 kube-apiserver-master-instance-0
    Namespace:            kube-system
    Priority:             2000000000
    Priority Class Name:  system-cluster-critical
    Node:                 master-instance-0/10.128.0.46
    Start Time:           Sun, 12 Apr 2020 21:48:59 +0000
    Labels:               component=kube-apiserver
                        tier=control-plane
    Annotations:          kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 10.128.0.46:6443
                        kubernetes.io/config.hash: a19adc21510a5d0cca528602e0d4a7b8
                        kubernetes.io/config.mirror: a19adc21510a5d0cca528602e0d4a7b8
                        kubernetes.io/config.seen: 2020-04-12T22:13:59.516033438Z
                        kubernetes.io/config.source: file
    Status:               Running
    IP:                   10.128.0.46
    IPs:
    IP:           10.128.0.46
    Controlled By:  Node/master-instance-0
    Containers:
    kube-apiserver:
        Container ID:  docker://59457c26eaab8ed4850c51a7d9901119b187fb38374b05c36d54105d0c2f89fb
        Image:         k8s.gcr.io/kube-apiserver:v1.18.0
        Image ID:      docker-pullable://k8s.gcr.io/kube-apiserver@sha256:fc4efb55c2a7d4e7b9a858c67e24f00e739df4ef5082500c2b60ea0903f18248
        Port:          <none>
        Host Port:     <none>
        Command:
        kube-apiserver
        --advertise-address=10.128.0.46
        --allow-privileged=true
        --authorization-mode=Node,RBAC
        --client-ca-file=/etc/kubernetes/pki/ca.crt
        --enable-admission-plugins=NodeRestriction
        --enable-bootstrap-token-auth=true
        --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
        --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
        --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
        --etcd-servers=https://127.0.0.1:2379
        --insecure-port=0
        --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
        --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
        --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt
        --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key
        --requestheader-allowed-names=front-proxy-client
        --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
        --requestheader-extra-headers-prefix=X-Remote-Extra-
        --requestheader-group-headers=X-Remote-Group
        --requestheader-username-headers=X-Remote-User
        --secure-port=6443
        --service-account-key-file=/etc/kubernetes/pki/sa.pub
        --service-cluster-ip-range=10.96.0.0/12
        --tls-cert-file=/etc/kubernetes/pki/apiserver.crt
        --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
        State:          Running
        Started:      Sun, 12 Apr 2020 22:14:00 +0000
        Ready:          True
        Restart Count:  0
        Requests:
        cpu:        250m
        Liveness:     http-get https://10.128.0.46:6443/healthz delay=15s timeout=15s period=10s #success=1 #failure=8
        Environment:  <none>
        Mounts:
        /etc/ca-certificates from etc-ca-certificates (ro)
        /etc/kubernetes/pki from k8s-certs (ro)
        /etc/ssl/certs from ca-certs (ro)
        /usr/local/share/ca-certificates from usr-local-share-ca-certificates (ro)
        /usr/share/ca-certificates from usr-share-ca-certificates (ro)
    Conditions:
    Type              Status
    Initialized       True 
    Ready             True 
    ContainersReady   True 
    PodScheduled      True 
    Volumes:
    ca-certs:
        Type:          HostPath (bare host directory volume)
        Path:          /etc/ssl/certs
        HostPathType:  DirectoryOrCreate
    etc-ca-certificates:
        Type:          HostPath (bare host directory volume)
        Path:          /etc/ca-certificates
        HostPathType:  DirectoryOrCreate
    k8s-certs:
        Type:          HostPath (bare host directory volume)
        Path:          /etc/kubernetes/pki
        HostPathType:  DirectoryOrCreate
    usr-local-share-ca-certificates:
        Type:          HostPath (bare host directory volume)
        Path:          /usr/local/share/ca-certificates
        HostPathType:  DirectoryOrCreate
    usr-share-ca-certificates:
        Type:          HostPath (bare host directory volume)
        Path:          /usr/share/ca-certificates
        HostPathType:  DirectoryOrCreate
    QoS Class:         Burstable
    Node-Selectors:    <none>
    Tolerations:       :NoExecute
    Events:
    Type    Reason   Age    From                        Message
    ----    ------   ----   ----                        -------
    Normal  Pulled   2m25s  kubelet, master-instance-0  Container image "k8s.gcr.io/kube-apiserver:v1.18.0" already present on machine
    Normal  Created  2m25s  kubelet, master-instance-0  Created container kube-apiserver
    Normal  Started  2m25s  kubelet, master-instance-0  Started container kube-apiserver
    ```

6. Обновление кластера | Обновление worker ноды

    Выводим ноду из работы:

    ```bash
    kubectl drain worker-instance-0 --ignore-daemonsets
    ```

    Посмотрим на результат:

    ```bash
    kubectl get nodes -o wide
    NAME                STATUS                     ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION   CONTAINER-RUNTIME
    master-instance-0   Ready                      master   31m   v1.18.0   10.128.0.46   <none>        Ubuntu 18.04.4 LTS   5.0.0-1033-gcp   docker://19.3.8
    worker-instance-0   Ready,SchedulingDisabled   <none>   22m   v1.17.4   10.128.0.48   <none>        Ubuntu 18.04.4 LTS   5.0.0-1033-gcp   docker://19.3.8
    worker-instance-1   Ready                      <none>   21m   v1.17.4   10.128.0.45   <none>        Ubuntu 18.04.4 LTS   5.0.0-1033-gcp   docker://19.3.8
    worker-instance-2   Ready                      <none>   21m   v1.17.4   10.128.0.47   <none>        Ubuntu 18.04.4 LTS   5.0.0-1033-gcp   docker://19.3.8
    ```

    к статусу добавилась строчка `SchedulingDisabled`

    Идём на ноду и ставим пакеты:

    ```bash
    apt-get install -y kubelet=1.18.0-00 kubeadm=1.18.0-00
    systemctl restart kubelet
    ```

    на местер ноде проверям, что всё обновилось:

    ```bash
    kubectl get nodes
    NAME                STATUS                     ROLES    AGE   VERSION
    master-instance-0   Ready                      master   35m   v1.18.0
    worker-instance-0   Ready,SchedulingDisabled   <none>   27m   v1.18.0
    worker-instance-1   Ready                      <none>   26m   v1.17.4
    worker-instance-2   Ready                      <none>   25m   v1.17.4
    ```

    Возвращаем ноду в кластер:

    ```bas
    kubectl uncordon worker-instance-0
    ```

    Выполним теже операции на остальных нодах кластера.

    Полсе обновления удалим кластер:

    ```bash
    cd ../terrafrom/
    terraform destroy --auto-approve=true
    ```

7. Автоматическое развертывание кластеров `kubespary`

    Переразвернём ноды:

    ```bash
    rm ~/.ssh/known_hosts # Мф можем получить теже IP адерса поэтому очистим список известных хостов
    terraform apply --auto-approve=true
    ```

    Ansible у нас уже установлен, так что приступим сразу к разворачиванию кластера:

    ```bash
    # получение kubespray
    git clone https://github.com/kubernetes-sigs/kubespray.git
    # установка зависимостей
    cd kubespray
    pip install -r requirements.txt
    # копирование примера конфига в отдельную директорию
    cp -rfp inventory/sample inventory/mycluster
    ```

    Фиксим `inventory.ini` - добавляем IP адреса своих нод и запускаем ansible-playbook

    ```bash
    ansible-playbook -i inventory/mycluster/inventory.ini --become --become-user=root \
    --user=gidmaster --key-file=~/.ssh/id_rsa.pub cluster.yml
    ```

[Назад к содержанию](../README.md)
