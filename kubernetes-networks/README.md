# Домашнее задание 4

[Содержание](../README.md)

*NB: Использован дистрибутив `Ubuntu 18.04` с предустановленным `Docker` `minikube` и `VirtualBox` ПО.*

1. Запустим `minikube` кластер:

    ```bash
    minikube start
    ```

2. Добавим в сеществующий манифест `web-pod.yaml` описание readiness probe:

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
    name: web
    labels:
      app: web
    spec:
    #--- Ommited output ---
    containers:
      - name: web
      image: gidmaster/otus-k8s-nginx
      #--- ReadinessProbe ---
      readinessProbe:
        httpGet:
          path: /index.html
          port: 80
        #--- End of ReadinessProbe ---
    #--- Ommited output---
    ```

    Запустим `Pod` и убедимся что он перешёл в статус `Running`, но не перешёл в состояние `Ready`:

    ```bash
    kubectl apply -f web-pod.yaml

    pod/web created

    kubectl get pods
    NAME   READY   STATUS    RESTARTS   AGE
    web    0/1     Running   0          9s
    ```

    `Pod` не перешёл в состояние Ready по причине провала проверки готовности. Т.к. мы указали неверный `port` - 80 вместо 8000.

3. Добавим провеку "живости" к нашему `Pod` сразу после проверки готовности и обновим `Pod` с использованием ключа `--force` т.к.:

    ```yaml
      livenessProbe:
        tcpSocket:
          {port: 8080}
    ```

4. Начнём создавать манифест для `Deployment` согласно [документации](http://example.com) перенеся `spec` секцию из `kuberneted-intro\web-pod.yaml`. Попутно поправив `ReadinessProbe` и задав количество реплик равное 3.

5. Применим созданный манифест `web-deployment.yaml`:

    ```bash
    cd kubernetes-networks
    kubectl apply -f web-deploy.yaml
    ```

6. Посмотрим описание созданного `Deployment`:

    ```bash
    kubectl describe deploy/web
    Name:                   web
    Namespace:              default
    CreationTimestamp:      Sun, 12 Jan 2020 16:35:49 +0300
    Labels:                 <none>
    Annotations:            deployment.kubernetes.io/revision: 1
                            kubectl.kubernetes.io/last-applied-configuration:
                            {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"name":"web","namespace":"default"},"spec":{"replicas":3,"selecto...
    Selector:               app=web
    Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
    StrategyType:           RollingUpdate
    MinReadySeconds:        0
    RollingUpdateStrategy:  25% max unavailable, 25% max surge
    Pod Template:
    Labels:  app=web
    Init Containers:
    html-gen:
        Image:      busybox:musl
        Port:       <none>
        Host Port:  <none>
        Command:
        sh
        -c
        wget -O- https://bit.ly/otus-k8s-index-gen | sh
        Environment:  <none>
        Mounts:
        /app from app (rw)
    Containers:
    web:
        Image:        gidmaster/web:v1
        Port:         <none>
        Host Port:    <none>
        Liveness:     tcp-socket :8000 delay=0s timeout=1s period=10s #success=1 #failure=3
        Readiness:    http-get http://:8000/index.html delay=0s timeout=1s period=10s #success=1 #failure=3
        Environment:  <none>
        Mounts:
        /app from app (rw)
    Volumes:
    app:
        Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
        Medium:
        SizeLimit:  <unset>
    Conditions:
    Type           Status  Reason
    ----           ------  ------
    Available      True    MinimumReplicasAvailable
    Progressing    True    NewReplicaSetAvailable
    OldReplicaSets:  <none>
    NewReplicaSet:   web-588d77f78 (3/3 replicas created)
    Events:
    Type    Reason             Age   From                   Message
    ----    ------             ----  ----                   -------
    Normal  ScalingReplicaSet  22m   deployment-controller  Scaled up replica set web-588d77f78 to 3
    ```

    Обратим внимание на `Condifitions` и отметим, что `Deployment` - `Available and Progressing`

7. Добавим стратегию развёртывания в наш манифест:

    ```yaml
    #--- Ommited output ---
    spec:
    replicas: 3
    selector:
        matchLabels:
        app: web
    strategy:
        type: RollingUpdate
        rollingUpdate:
        maxUnavailable: 0
        maxSurge: 100%
    template:
    #--- Ommited output ---
    ```

    Если попробовать различные вариации значений `maxUnavailable` и `maxSurge` можно получить различные стратегии обновления подов.

    **_Например:_**

    Это deployment с "простоем" - мы сначала удаляем все `pods` и только потом создаём новые.

    ```yaml
    maxUnavailable: 100%
    maxSurge: 0
    ```

    Это Blue-Green deployment когда мы имеем две версии приложения одновременно.

    ```yaml
    maxUnavailable: 0
    maxSurge: 100%
    ```

    Это Canary deployment. Когда мы постепенно заменяем pods со старой версией на новые

    ```yaml
    maxUnavailable: 1
    maxSurge: 0
    ```

    Не допустимая комбиинация, т.к. не позволит выполнить `Deployment`

    ```yaml
    maxUnavailable: 0
    maxSurge: 0
    ```

    Вариант "Как пойдёт" - мы позволяем удалять и создавать `pods` в случайном порядке.

    ```yaml
    maxUnavailable: 100%
    maxSurge: 100%
    ```

8. Создадим манифест создающий `Service` с типом `ClusterIP`, применим его и выясним ClusterIP для созданного `Service web-svc-cip`:

    ```bash
    kubectl apply -f web-svc-cip.yaml

    service/web-svc-cip created

    kubectl get service
    NAME          TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
    kubernetes    ClusterIP   10.96.0.1     <none>        443/TCP   5h55m
    web-svc-cip   ClusterIP   10.96.253.9   <none>        80/TCP    7m41s
    ```

9. Посмотрим можем ли мы получить доступ к ClusterIP. Заметим, что ClusterIP это virtual IP address и имеет смысл, только в связке с портом, что будет видно в ip tables:

    ```bash
    minikube ssh
    curl http://10.96.253.9/index.html
    ping 10.96.253.9
    arp -an
    ip addr show
    sudo iptables --list -nv -t nat
    ```

10. Модифицируем `minikube` что бы использовать `IPVS` вместо `iptables` согласно нструкции из домашнего задания.

11. Установим `MetalLB`

    ```bash
    kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.0/manifests/metallb.yaml
    ```

    Проверим, что все необъходимые сущности были созданы:

    ```bash
    kubectl --namespace metallb-system get all
    NAME                              READY   STATUS    RESTARTS   AGE
    pod/controller-7845b997db-rxv46   1/1     Running   0          7m43s
    pod/speaker-5d6vj                 1/1     Running   0          7m43s

    NAME                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
    daemonset.apps/speaker   1         1         1       1            1           beta.kubernetes.io/os=linux   7m44s

    NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/controller   1/1     1            1           7m43s

    NAME                                    DESIRED   CURRENT   READY   AGE
    replicaset.apps/controller-7845b997db   1         1         1       7m43s
    ```

12. Настроим `MetalLB` с помощью `ConfigMap` использовав манифест `metallb-config.yaml`

    ```bash
    kubectl apply -f metallb-config.yaml

    configmap/config created
    ```

13. Создаим новый `Service` используйющий `MetalLB` в качетве LoadBalancer

    ```bash
    kubectl apply -f web-svc-lb.yaml

    service/web-svc-lb created

    kubectl --namespace metallb-system logs pod/controller-7845b997db-rxv46

    #--- Ommited output
    {"caller":"main.go:49","event":"startUpdate","msg":"start of service update","service":"default/web-svc-lb","ts":"2020-01-12T19:35:20.161414658Z"}
    {"caller":"service.go:98","event":"ipAllocated","ip":"172.17.255.1","msg":"IP address assigned by controller","service":"default/web-svc-lb","ts":"2020-01-12T19:35:20.163184861Z"}
    {"caller":"main.go:96","event":"serviceUpdated","msg":"updated service object","service":"default/web-svc-lb","ts":"2020-01-12T19:35:20.198257016Z"}
    {"caller":"main.go:98","event":"endUpdate","msg":"end of service update","service":"default/web-svc-lb","ts":"2020-01-12T19:35:20.198350795Z"}
    {"caller":"main.go:49","event":"startUpdate","msg":"start of service update","service":"default/web-svc-lb","ts":"2020-01-12T19:35:20.207649196Z"}
    {"caller":"main.go:75","event":"noChange","msg":"service converged, no change","service":"default/web-svc-lb","ts":"2020-01-12T19:35:20.209363858Z"}
    {"caller":"main.go:76","event":"endUpdate","msg":"end of service update","service":"default/web-svc-lb","ts":"2020-01-12T19:35:20.209479346Z"}
    ```

    В выводе можно увидеть, что IP 172.17.255.1 назначен нашему сервису `web-svc-lb`.

14. Убедимся, что это так:

    ```bash
    kubectl describe svc web-svc-lb
    Name:                     web-svc-lb
    Namespace:                default
    Labels:                   <none>
    Annotations:              kubectl.kubernetes.io/last-applied-configuration:
                                {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"name":"web-svc-lb","namespace":"default"},"spec":{"ports":[{"port":80,"p...
    Selector:                 app=web
    Type:                     LoadBalancer
    IP:                       10.96.217.31
    LoadBalancer Ingress:     172.17.255.1
    Port:                     <unset>  80/TCP
    TargetPort:               8000/TCP
    NodePort:                 <unset>  32453/TCP
    Endpoints:                172.17.0.7:8000,172.17.0.8:8000,172.17.0.9:8000
    Session Affinity:         None
    External Traffic Policy:  Cluster
    Events:
    Type    Reason       Age    From                Message
    ----    ------       ----   ----                -------
    Normal  IPAllocated  7m52s  metallb-controller  Assigned IP "172.17.255.1"
    ```

15. Прокинем маршрут из ВМ minikube на хостовую машину

    ```bash
    minikube ip

    192.168.99.104

    sudo ip route 172.17.255.0/24 via 192.168.99.104
    ```

    Проверим доступ к LB с зостовой машины:

    ```bash
    curl http://172.17.255.1/index.html
    ````

16. Задание со *:

    Сделайте сервис LoadBalancer, который откроет доступ к CoreDNS снаружи кластера. Поскольку DNS работает по TCP и UDP протоколам - учтите это в конфигурации. Оба протокола должны работать по одному и тому же IP-адресу балансировщика.

    Проблема заключается в том, что LoadBalancer не может работать одновременно с несколькими IP протоколами. Поэтому нам необходимо создать 2 сервиса - один для TCP и один для UDP. Но тогда возникает проблема использования общего IP адреса, для двух сервисов.

    Решение проблемы указано в [Hint](https://metallb.universe.tf/usage/#ip-address-sharing) - это добавление аннотации `metallb.universe.tf/allow-shared-ip` и указания одного и того же `ClusterIP` в обоих сервисах (TCP/UDP).

    Применим созданне сервисы и сделаем проверку - запустим nslookup с хостовой машины и попробуем найти наш `web-svc-lb` сервис созданный ренее.

    ```bash
    kubectl apply -f coredns/coredns-svc-udp-lb.yaml

    service/coredns-svc-udp-lb created

    kubectl apply -f coredns/coredns-svc-tcp-lb.yaml

    service/coredns-svc-tcp-lb created

    kubectl get svc -n kube-system

    NAME                 TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)                  AGE
    coredns-svc-tcp-lb   LoadBalancer   10.96.227.86   172.17.255.2   53:31284/TCP             4s
    coredns-svc-udp-lb   LoadBalancer   10.96.70.196   172.17.255.2   53:31158/UDP             10s
    kube-dns             ClusterIP      10.96.0.10     <none>         53/UDP,53/TCP,9153/TCP   31h

    kubectl describe svc -n kube-system coredns-svc-udp-lb
    Name:                     coredns-svc-udp-lb
    Namespace:                kube-system
    Labels:                   <none>
    Annotations:              kubectl.kubernetes.io/last-applied-configuration:
                                {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{"metallb.universe.tf/allow-shared-ip":"shared_key"},"name":"coredns-svc-udp...
                            metallb.universe.tf/allow-shared-ip: shared_key
    Selector:                 k8s-app=kube-dns
    Type:                     LoadBalancer
    IP:                       10.96.70.196
    IP:                       172.17.255.2
    LoadBalancer Ingress:     172.17.255.2
    Port:                     dns-udp  53/UDP
    TargetPort:               53/UDP
    NodePort:                 dns-udp  31158/UDP
    Endpoints:                172.17.0.5:53,172.17.0.6:53
    Session Affinity:         None
    External Traffic Policy:  Cluster
    Events:
    Type    Reason       Age   From                Message
    ----    ------       ----  ----                -------
    Normal  IPAllocated  44s   metallb-controller  Assigned IP "172.17.255.2"

    kubectl describe svc -n kube-system coredns-svc-tcp-lb

    Name:                     coredns-svc-tcp-lb
    Namespace:                kube-system
    Labels:                   <none>
    Annotations:              kubectl.kubernetes.io/last-applied-configuration:
                                {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{"metallb.universe.tf/allow-shared-ip":"shared_key"},"name":"coredns-svc-tcp...
                            metallb.universe.tf/allow-shared-ip: shared_key
    Selector:                 k8s-app=kube-dns
    Type:                     LoadBalancer
    IP:                       10.96.227.86
    IP:                       172.17.255.2
    LoadBalancer Ingress:     172.17.255.2
    Port:                     dns-tcp  53/TCP
    TargetPort:               53/TCP
    NodePort:                 dns-tcp  31284/TCP
    Endpoints:                172.17.0.5:53,172.17.0.6:53
    Session Affinity:         None
    External Traffic Policy:  Cluster
    Events:
    Type    Reason       Age   From                Message
    ----    ------       ----  ----                -------
    Normal  IPAllocated  43s   metallb-controller  Assigned IP "172.17.255.2"

    nslookup web-svc-lb.default.svc.cluster.local 172.17.255.2
    Server:         172.17.255.2
    Address:        172.17.255.2#53

    Name:   web-svc-lb.default.svc.cluster.local
    Address: 10.96.217.31
    ```

17. Создание `Ingress`

    Применим "осносновной" манифест:

    ```bash
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
    ```

    Создадим манифест `nginx-lb.yaml` с конфигурацией балансировщика нагрузки и примени его. После узнаем полученный IP адрес и попробуем обратится к нему через `curl`:

    ```bash
    kubectl apply -f nginx-lb.yaml

    service/ingress-nginx created

    kubectl get svc -n ingress-nginx
    NAME            TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                      AGE
    ingress-nginx   LoadBalancer   10.96.115.124   172.17.255.3   80:31891/TCP,443:31149/TCP   2m10s

    curl http://172.17.255.3
    <html>
    <head><title>404 Not Found</title></head>
    <body>
    <center><h1>404 Not Found</h1></center>
    <hr><center>nginx/1.17.7</center>
    </body>
    </html>
    ```

    Наш Ingress-контроллер не требует ClusterIP для балансировки трафика, поэтому мы можем использовать headless-сервис для нашего веб-приложения. Создадим и применим манифест `web-svc-headless.yaml`

    ```bash
    kubectl apply -f web-svc-headless.yaml
    ```

    Наконец, добавим манифест `web-ingress.yaml` применим его и проверим доступность:

    ```bash
    kubectl describe ingress/web
    Name:             web
    Namespace:        default
    Address:          172.17.255.3
    Default backend:  default-http-backend:80 (<none>)
    Rules:
    Host  Path  Backends
    ----  ----  --------
    *
            /web   web-svc:8000 (172.17.0.7:8000,172.17.0.8:8000,172.17.0.9:8000)
    Annotations:
    kubectl.kubernetes.io/last-applied-configuration:  {"apiVersion":"networking.k8s.io/v1beta1","kind":"Ingress","metadata":{"annotations":{"nginx.ingress.kubernetes.io/rewrite-target":"/"},"name":"web","namespace":"default"},"spec":{"rules":[{"http":{"paths":[{"backend":{"serviceName":"web-svc","servicePort":8000},"path":"/web"}]}}]}}

    nginx.ingress.kubernetes.io/rewrite-target:  /
    Events:
    Type    Reason  Age                   From                      Message
    ----    ------  ----                  ----                      -------
    Normal  CREATE  25m                   nginx-ingress-controller  Ingress default/web
    Normal  CREATE  25m                   nginx-ingress-controller  Ingress default/web
    Normal  UPDATE  4m33s (x41 over 24m)  nginx-ingress-controller  Ingress default/web
    Normal  UPDATE  4m33s (x41 over 24m)  nginx-ingress-controller  Ingress default/web
    gidmaster@gidmaster-HP-ProBook-655-G1:/media/gidmaster/38A298C4D8F9D47B/testr/Projects/gidmaster_platform/kubernetes-networks$ curl http://172.17.255.3
    ```

18. Задание со *:

    Добавьте доступ к kubernetes-dashboard через наш Ingressпрокси. Cервис должен быть доступен через префикс /dashboard). Kubernetes Dashboard должен быть развернут из официального манифеста.

    Задача выполняется по анологии с `web-ingress.yaml` с указанием правильных selector и namespace. Сам манифест представлен в `.kubernetes-networls/dashboard/dashboard-ingress.yaml`

19. Задание с **:

    Реализуйте канареечное развертывание с помощью ingressnginx. Перенаправление части трафика на выделенную группу подов должно происходить по HTTP-заголовку.

    не выполнено.

[Назад к содержанию](../README.md)
