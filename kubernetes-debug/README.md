# Домашнее задание 12

[Содержание](../README.md)

*NB: Использован дистрибутив `Ubuntu 18.04` с предустановленным `docker`, `minikube` и `VirtualBox` ПО.*

1. Развернём `minikube` кластер

    ```bash
    minikube start
    ```

2. kubectl-debug:

    Установим утилиту `kubectl-debug`

    ```bash
    wget https://github.com/aylei/kubectl-debug/releases/download/v0.1.1/kubectl-debug_0.1.1_linux_amd64.tar.gz
    tar -xzf kubectl-debug_0.1.1_linux_amd64.tar.gz
    mv kubectl-debug /usr/local/bin/
    rm -f kubectl-debug_0.1.1_linux_amd64.tar.gz
    kubectl-debug --version
    debug version v0.0.0-master+$Format:%h$
    ```

    Задеплоим `Daemonset` для kubectl-debug:

    ```bash
    kubectl apply -f strace/agent_daemonset.yml
    ```

    *NB: Ссылка в ДЗ имеет `apiVersion:` для предыдущей версии кубернетес.

    Деплоим простой nginx из предыдущих заданий:

    ```bash
    kubectl apply -f strace/frontend-pod.yaml
    ```

    Попробуем запустить debug:

    ```bash
    kubectl-debug frontend
    ```

    Запустим `strace`

    ```bash
    strace -c -p1
    strace: attach: ptrace(PTRACE_SEIZE, 1): Operation not permitted
    ```

    не хватает прав. Это конечно не очевидно, но возможности запуска трассировки определяется наличием у процесса capability SYS_PTRAC и в версии `0.0.1` к сожалению этогой Capability нет. А вот в версии `v0.1.1`.

    *NB: тэг, ктоторый нам нужен начинается с `v0`*

    Задеплоим новый манифест

    ```bash
    kubectl apply -f strace/agent_daemonset.yml
    ```

    И попробуем ещё раз:

    ```bash
    kubectl-debug frontend
    ```

    Запустим `strace`

    ```bash
    strace -c -p1
    strace: Process 1 attached
    ^Cstrace: Process 1 detached
    ```

    Работает!

3. iptables-tailer

    Чтобы выполнить домашнее задание нам потребуется следующее:

    * Кластер с установленным и запущенным Calico (для GKE - это просто включенные галки Network Policy)
    * Для нод K8s лучше использовать Ubuntu 18.хх или новее (Fedora, CentOS 7/8 тоже можно, если заведете)
    * Тестовое приложение - `netperf`
    * Инсталляция kube-iptables-tailer
    * Результаты работы должны быть в папке kubernetes-debug/kit

    Для разнообразия развернём кластер через `gcloud`.

    ```bash
    gcloud container --project "k8s-platform-266222" clusters create "cluster-k8s" --enable-network-policy --zone "us-central1-c" --image-type "UBUNTU"

    gcloud container clusters get-credentials cluster-k8s --zone us-central1-c --project k8s-platform-266222
    ```

    Установим netperf оператор

    ```bash
    mkdir kit
    cd kit
    git clone https://github.com/piontec/netperf-operator.git
    cd netperf-operator

    kubectl apply -f ./deploy/crd.yaml
    kubectl apply -f ./deploy/rbac.yaml
    kubectl apply -f ./deploy/operator.yaml
    ```

    Теперь можно запустить наш первый тест, применив манифест `cr.yaml` из папки deploy

    ```bash
    kubectl apply -f ./deploy/cr.yaml

    kubectl describe netperf.app.example.com/example
    Name:         example
    Namespace:    default
    Labels:       <none>
    Annotations:  API Version:  app.example.com/v1alpha1
    Kind:         Netperf
    Metadata:
    Creation Timestamp:  2020-04-05T19:43:08Z
    Generation:          4
    Resource Version:    15712
    Self Link:           /apis/app.example.com/v1alpha1/namespaces/default/netperfs/example
    UID:                 f6b98d95-9d58-4a03-a463-aa86a4794ae4
    Spec:
    Client Node:  
    Server Node:  
    Status:
    Client Pod:          netperf-client-aa86a4794ae4
    Server Pod:          netperf-server-aa86a4794ae4
    Speed Bits Per Sec:  14683.47
    Status:              Done
    Events:                <none>
    ```

    В результатах kubectl describe видим `Status: Done` и результат измерений, значит все прошло хорошо. Теперь нужно добавить сетевую политику для Calico, чтобы ограничить доступ к подам Netperf и включить логирование в iptables.

    У нас для этого есть манифест networkPolicy.yml

    ```bash
    cd  ..
    kubectl apply -f networkPolicy.yml
    ```

    *NB: скорее всего потребуется перезапустить pod с netperf `kubectl delete -f netperf-operator/deploy/cr.yaml && kubectl apply -f netperf-operator/deploy/cr.yaml`*

    Теперь, если повторно запустить тест, мы увидим, что тест висит в состоянии `Started test`.

    ```bash
    kubectl describe netperf.app.example.com/example
    Name:         example
    Namespace:    default
    Labels:       <none>
    Annotations:  API Version:  app.example.com/v1alpha1
    Kind:         Netperf
    Metadata:
    Creation Timestamp:  2020-04-05T20:04:57Z
    Generation:          3
    Resource Version:    21303
    Self Link:           /apis/app.example.com/v1alpha1/namespaces/default/netperfs/example
    UID:                 62c8515b-a183-467e-9e11-4fd5c929cce4
    Spec:
    Client Node:  
    Server Node:  
    Status:
    Client Pod:          netperf-client-4fd5c929cce4
    Server Pod:          netperf-server-4fd5c929cce4
    Speed Bits Per Sec:  0
    Status:              Started test
    Events:                <none>
    ```

    В нашей сетевой политике есть ошибка.

    Проверим, что в логах ноды Kubernetes появились сообщения об отброшенных пакетах:

    Подключитесь к ноде по SSH
    `iptables --list -nv | grep DROP` - счетчики дропов ненулевые
    `iptables --list -nv | grep LOG` - счетчики с действием логирования ненулевые

    ```bash
    journalctl -k | grep calico
    Apr 05 20:41:42 gke-cluster-k8s-default-pool-d4371b02-9s00 kernel: calico-packet: IN=cali6e7bb88b982 OUT=eth0 MAC=ee:ee:ee:ee:ee:ee:ea:20:b8:68:45:bd:08:00 SRC=10.4.0.4 DST=10.4.1.6 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=36387 DF PROTO=TCP SPT=60353 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0
    Apr 05 20:41:43 gke-cluster-k8s-default-pool-d4371b02-9s00 kernel: calico-packet: IN=cali6e7bb88b982 OUT=eth0 MAC=ee:ee:ee:ee:ee:ee:ea:20:b8:68:45:bd:08:00 SRC=10.4.0.4 DST=10.4.1.6 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=36388 DF PROTO=TCP SPT=60353 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0
    Apr 05 20:41:45 gke-cluster-k8s-default-pool-d4371b02-9s00 kernel: calico-packet: IN=cali6e7bb88b982 OUT=eth0 MAC=ee:ee:ee:ee:ee:ee:ea:20:b8:68:45:bd:08:00 SRC=10.4.0.4 DST=10.4.1.6 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=36389 DF PROTO=TCP SPT=60353 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0
    Apr 05 20:41:49 gke-cluster-k8s-default-pool-d4371b02-9s00 kernel: calico-packet: IN=cali6e7bb88b982 OUT=eth0 MAC=ee:ee:ee:ee:ee:ee:ea:20:b8:68:45:bd:08:00 SRC=10.4.0.4 DST=10.4.1.6 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=36390 DF PROTO=TCP SPT=60353 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0
    Apr 05 20:41:57 gke-cluster-k8s-default-pool-d4371b02-9s00 kernel: calico-packet: IN=cali6e7bb88b982 OUT=eth0 MAC=ee:ee:ee:ee:ee:ee:ea:20:b8:68:45:bd:08:00 SRC=10.4.0.4 DST=10.4.1.6 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=36391 DF PROTO=TCP SPT=60353 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0
    Apr 05 20:42:13 gke-cluster-k8s-default-pool-d4371b02-9s00 kernel: calico-packet: IN=cali6e7bb88b982 OUT=eth0 MAC=ee:ee:ee:ee:ee:ee:ea:20:b8:68:45:bd:08:00 SRC=10.4.0.4 DST=10.4.1.6 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=36392 DF PROTO=TCP SPT=60353 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0
    Apr 05 20:42:46 gke-cluster-k8s-default-pool-d4371b02-9s00 kernel: calico-packet: IN=cali6e7bb88b982 OUT=eth0 MAC=ee:ee:ee:ee:ee:ee:ea:20:b8:68:45:bd:08:00 SRC=10.4.0.4 DST=10.4.1.6 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=36393 DF PROTO=TCP SPT=60353 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0
    Apr 05 20:43:53 gke-cluster-k8s-default-pool-d4371b02-9s00 kernel: calico-packet: IN=cali6e7bb88b982 OUT=eth0 MAC=ee:ee:ee:ee:ee:ee:ea:20:b8:68:45:bd:08:00 SRC=10.4.0.4 DST=10.4.1.6 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=42854 DF PROTO=TCP SPT=44249 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0
    Apr 05 20:43:54 gke-cluster-k8s-default-pool-d4371b02-9s00 kernel: calico-packet: IN=cali6e7bb88b982 OUT=eth0 MAC=ee:ee:ee:ee:ee:ee:ea:20:b8:68:45:bd:08:00 SRC=10.4.0.4 DST=10.4.1.6 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=42855 DF PROTO=TCP SPT=44249 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0
    Apr 05 20:43:56 gke-cluster-k8s-default-pool-d4371b02-9s00 kernel: calico-packet: IN=cali6e7bb88b982 OUT=eth0 MAC=ee:ee:ee:ee:ee:ee:ea:20:b8:68:45:bd:08:00 SRC=10.4.0.4 DST=10.4.1.6 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=42856 DF PROTO=TCP SPT=44249 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0
    ```

4. Задеплоим `iptaibles-tailer`:

    Манифест возьмём [отсюда](https://github.com/box/kube-iptables-tailer/blob/master/demo/daemonset.yaml).

    Ещё создадим Service Account ClusterRole и биндинг:

    ```bash
    kubectl apply -f serviceAccount.yml
    kubectl apply -f clusterRole.yml
    kubectl apply -f clusterRoleBinding.yml
    kubectl apply -f daemonSet.yml
    ```

    Проверим логи пода iptables-tailer и события в кластере (kubectl get events -A) И опять, мы ничего не увидим. А жаль...

5. Пофиксим это безобразие.

    * В манифесте с DaemonSet была переменная, которая задавала префикс для выбора логов iptables. В ней указан префикс `calico-drop`, а по-умолчанию Calico логирует пакеты с префиксом `calico-packet`. Поменяем значение переменной среды с `calico-drop` на `calico-packet` в `daemonSet.yml`.

    * В манифесте из репозитория `kube-iptables-tailer` настроен так, что ищет текстовый файл с логами iptables в определенной папке. Но во многих современных Linux-дистрибутивах логи по-умолчанию не будут туда отгружаться, а будут складываться в журнал systemd. К счастью, iptables-tailer умеет работать с systemd journal - для этого надо передать ему параметр `JOURNAL_DIRECTORY` указав каталог с файлами журнала `/var/log/journal`

    * После применения манифеста опять что-то пошло не так. Если посмотрим на логи - то увидим, что необходимо пересобрать образ с `kube-iptables-tailer`, включив опцию C-Go (для связывания с C-библиотекой, которая обеспечивает чтение журнала systemd). Не будем грузится этим и подглядим правильный image (да и в целом проверим наш манифест) из готового мапнифеста в [ДЗ](https://github.com/express42/otus-platform-snippets/blob/master/Module-03/Debugging/iptables-tailer.yaml)

6. Передеплоим манифест.

    ```bash
    kubectl apply -f daemonSet.yml
    ```

7. И наконец-то увидим:

    ``bash
    kubectl describe pod --selector=app=netperf-operator
    Name:           netperf-client-42010a80017f
    Namespace:      default
    Priority:       0
    Node:           gke-cluster-k8s-default-pool-1d89c05c-zpm1/10.128.0.16
    Start Time:     Wed, 08 Apr 2020 23:37:13 +0300
    Labels:         app=netperf-operator
                    netperf-type=client
    Annotations:    cni.projectcalico.org/podIP: 10.4.1.6/32
                    kubernetes.io/limit-ranger: LimitRanger plugin set: cpu request for container netperf-client-42010a80017f
    Status:         Running
    IP:             10.4.1.6
    IPs:            <none>
    Controlled By:  Netperf/example
    Containers:
    netperf-client-42010a80017f:
        Container ID:  docker://e137b0c20beafeb78b303d185b42f77cfad2e8f16a1911e392b832e34c0847b1
        Image:         tailoredcloud/netperf:v2.7
        Image ID:      docker-pullable://tailoredcloud/netperf@sha256:0361f1254cfea87ff17fc1bd8eda95f939f99429856f766db3340c8cdfed1cf1
        Port:          <none>
        Host Port:     <none>
        Command:
        netperf
        -H
        10.4.0.16
        State:          Running
        Started:      Wed, 08 Apr 2020 23:37:14 +0300
        Ready:          True
        Restart Count:  0
        Requests:
        cpu:        100m
        Environment:  <none>
        Mounts:
        /var/run/secrets/kubernetes.io/serviceaccount from default-token-gk7rs (ro)
    Conditions:
    Type              Status
    Initialized       True 
    Ready             True 
    ContainersReady   True 
    PodScheduled      True 
    Volumes:
    default-token-gk7rs:
        Type:        Secret (a volume populated by a Secret)
        SecretName:  default-token-gk7rs
        Optional:    false
    QoS Class:       Burstable
    Node-Selectors:  <none>
    Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                    node.kubernetes.io/unreachable:NoExecute for 300s
    Events:
    Type     Reason      Age   From                                                 Message
    ----     ------      ----  ----                                                 -------
    Normal   Scheduled   94s   default-scheduler                                    Successfully assigned default/netperf-client-42010a80017f to gke-cluster-k8s-default-pool-1d89c05c-zpm1
    Normal   Pulled      93s   kubelet, gke-cluster-k8s-default-pool-1d89c05c-zpm1  Container image "tailoredcloud/netperf:v2.7" already present on machine
    Normal   Created     93s   kubelet, gke-cluster-k8s-default-pool-1d89c05c-zpm1  Created container netperf-client-42010a80017f
    Normal   Started     93s   kubelet, gke-cluster-k8s-default-pool-1d89c05c-zpm1  Started container netperf-client-42010a80017f
    Warning  PacketDrop  93s   kube-iptables-tailer                                 Packet dropped when sending traffic to netperf-server-42010a80017f (10.4.0.16)


    Name:           netperf-server-42010a80017f
    Namespace:      default
    Priority:       0
    Node:           gke-cluster-k8s-default-pool-1d89c05c-7q2c/10.128.0.15
    Start Time:     Wed, 08 Apr 2020 23:37:10 +0300
    Labels:         app=netperf-operator
                    netperf-type=server
    Annotations:    cni.projectcalico.org/podIP: 10.4.0.16/32
                    kubernetes.io/limit-ranger: LimitRanger plugin set: cpu request for container netperf-server-42010a80017f
    Status:         Running
    IP:             10.4.0.16
    IPs:            <none>
    Controlled By:  Netperf/example
    Containers:
    netperf-server-42010a80017f:
        Container ID:   docker://a282f500fcaa71f9032664d8a60644dcca8daf00d39c8565f3f65bebaf6f3681
        Image:          tailoredcloud/netperf:v2.7
        Image ID:       docker-pullable://tailoredcloud/netperf@sha256:0361f1254cfea87ff17fc1bd8eda95f939f99429856f766db3340c8cdfed1cf1
        Port:           <none>
        Host Port:      <none>
        State:          Running
        Started:      Wed, 08 Apr 2020 23:37:12 +0300
        Ready:          True
        Restart Count:  0
        Requests:
        cpu:        100m
        Environment:  <none>
        Mounts:
        /var/run/secrets/kubernetes.io/serviceaccount from default-token-gk7rs (ro)
    Conditions:
    Type              Status
    Initialized       True 
    Ready             True 
    ContainersReady   True 
    PodScheduled      True 
    Volumes:
    default-token-gk7rs:
        Type:        Secret (a volume populated by a Secret)
        SecretName:  default-token-gk7rs
        Optional:    false
    QoS Class:       Burstable
    Node-Selectors:  <none>
    Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                    node.kubernetes.io/unreachable:NoExecute for 300s
    Events:
    Type     Reason      Age   From                                                 Message
    ----     ------      ----  ----                                                 -------
    Normal   Scheduled   98s   default-scheduler                                    Successfully assigned default/netperf-server-42010a80017f to gke-cluster-k8s-default-pool-1d89c05c-7q2c
    Normal   Pulled      97s   kubelet, gke-cluster-k8s-default-pool-1d89c05c-7q2c  Container image "tailoredcloud/netperf:v2.7" already present on machine
    Normal   Created     97s   kubelet, gke-cluster-k8s-default-pool-1d89c05c-7q2c  Created container netperf-server-42010a80017f
    Normal   Started     96s   kubelet, gke-cluster-k8s-default-pool-1d89c05c-7q2c  Started container netperf-server-42010a80017f
    Warning  PacketDrop  94s   kube-iptables-tailer                                 Packet dropped when receiving traffic from netperf-client-42010a80017f (10.4.1.6)
    ```

    Чего-то мы всё-таки блокируем нашей сетевой политикой.

8. Задача со *.

    * Исправьте ошибку в нашей сетевой политике, чтобы Netperf снова начал работать. Поправим селекторы в ingress/egress секциях:

    ```yaml
    ingress: 
        - action: Allow
        source:
            # selector: netperf-role == "netperf-client"
            selector: app == "netperf-operator"
        - action: Log
        - action: Deny
    egress:
        - action: Allow
        destination:
            # selector: netperf-role == "netperf-client"
            selector: app == "netperf-operator"
        - action: Log
        - action: Deny
    ```

    Редеплоимся и проверяем:

    ```bash
    kubectl apply -f networkPolicy.yml
    kubectl delete -f netperf-operator/deploy/cr.yaml && kubectl apply -f netperf-operator/deploy/cr.yaml
    kubectl describe pod --selector=app=netperf-operator
    Name:                      netperf-server-42010a80017f
    Namespace:                 default
    Priority:                  0
    Node:                      gke-cluster-k8s-default-pool-1d89c05c-7q2c/10.128.0.15
    Start Time:                Thu, 09 Apr 2020 00:26:40 +0300
    Labels:                    app=netperf-operator
                            netperf-type=server
    Annotations:               cni.projectcalico.org/podIP: 10.4.0.19/32
                            kubernetes.io/limit-ranger: LimitRanger plugin set: cpu request for container netperf-server-42010a80017f
    Status:                    Terminating (lasts <invalid>)
    Termination Grace Period:  30s
    IP:                        10.4.0.19
    IPs:                       <none>
    Controlled By:             Netperf/example
    Containers:
    netperf-server-42010a80017f:
        Container ID:   docker://a0850f5e5483b45b835027ac3230cec40a2b0b329135652503524b566429ce20
        Image:          tailoredcloud/netperf:v2.7
        Image ID:       docker-pullable://tailoredcloud/netperf@sha256:0361f1254cfea87ff17fc1bd8eda95f939f99429856f766db3340c8cdfed1cf1
        Port:           <none>
        Host Port:      <none>
        State:          Running
        Started:      Thu, 09 Apr 2020 00:26:41 +0300
        Ready:          True
        Restart Count:  0
        Requests:
        cpu:        100m
        Environment:  <none>
        Mounts:
        /var/run/secrets/kubernetes.io/serviceaccount from default-token-gk7rs (ro)
    Conditions:
    Type              Status
    Initialized       True 
    Ready             True 
    ContainersReady   True 
    PodScheduled      True 
    Volumes:
    default-token-gk7rs:
        Type:        Secret (a volume populated by a Secret)
        SecretName:  default-token-gk7rs
        Optional:    false
    QoS Class:       Burstable
    Node-Selectors:  <none>
    Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                    node.kubernetes.io/unreachable:NoExecute for 300s
    Events:
    Type    Reason     Age   From                                                 Message
    ----    ------     ----  ----                                                 -------
    Normal  Scheduled  22s   default-scheduler                                    Successfully assigned default/netperf-server-42010a80017f to gke-cluster-k8s-default-pool-1d89c05c-7q2c
    Normal  Pulled     21s   kubelet, gke-cluster-k8s-default-pool-1d89c05c-7q2c  Container image "tailoredcloud/netperf:v2.7" already present on machine
    Normal  Created    21s   kubelet, gke-cluster-k8s-default-pool-1d89c05c-7q2c  Created container netperf-server-42010a80017f
    Normal  Started    21s   kubelet, gke-cluster-k8s-default-pool-1d89c05c-7q2c  Started container netperf-server-42010a80017f
    Normal  Killing    8s    kubelet, gke-cluster-k8s-default-pool-1d89c05c-7q2c  Stopping container netperf-server-42010a80017f


    kubectl describe netperf.app.example.com/example
    Name:         example
    Namespace:    default
    Labels:       <none>
    Annotations:  API Version:  app.example.com/v1alpha1
    Kind:         Netperf
    Metadata:
    Creation Timestamp:  2020-04-08T21:26:40Z
    Generation:          4
    Resource Version:    32450
    Self Link:           /apis/app.example.com/v1alpha1/namespaces/default/netperfs/example
    UID:                 a2ec142f-79df-11ea-9f19-42010a80017f
    Spec:
    Client Node:  
    Server Node:  
    Status:
    Client Pod:          netperf-client-42010a80017f
    Server Pod:          netperf-server-42010a80017f
    Speed Bits Per Sec:  1902.56
    Status:              Done
    Events:                <none>
    ```

    * Поправьте манифест DaemonSet из репозитория, чтобы в логах отображались имена Podов, а не их IP-адреса.

    Добавим ещё одну переменню среды в контейнер `iptables-tailer` в `daemonSet.yml`:

    ```yaml
    - name: "POD_IDENTIFIER"
      value: "name"
    ```

[Назад к содержанию](../README.md)
