# Домашнее задание 2

[Содержание](../README.md)

*NB: Использован дистрибутив `Ubuntu 18.04` с предустановленным `Docker` и `VirtualBox` ПО.*

1. Установим `kind`. Воспользуемся готовыми бинарниками ([документация](https://kind.sigs.k8s.io/docs/user/quick-start/)):

    ```bash
    curl -Lo ./kind https://github.com/kubernetes-sigs/kind/releases/download/v0.6.1/kind-$(uname)-amd64
    chmod +x ./kind
    mv ./kind /usr/local/bin/kind
    ```

2. Создадим файл конфигурации кластера `kind-config.yaml`:

    ```yaml
    kind: Cluster
    apiVersion: kind.sigs.k8s.io/v1alpha3
    nodes:
    - role: control-plane
    - role: control-plane
    - role: control-plane
    - role: worker
    - role: worker
    - role: worker
    ```

3. Запустим `kind` кластер и проверим его состояние:

    ```bash
    kind create cluster --config kind-config.yaml

    Creating cluster "kind" ...
    ✓ Ensuring node image (kindest/node:v1.16.3) 🖼
    ✓ Preparing nodes 📦
    ✓ Configuring the external load balancer ⚖️
    ✓ Writing configuration 📜
    ✓ Starting control-plane 🕹️
    ✓ Installing CNI 🔌
    ✓ Installing StorageClass 💾
    ✓ Joining more control-plane nodes 🎮
    ✓ Joining worker nodes 🚜
    Set kubectl context to "kind-kind"
    You can now use your cluster with:

    kubectl cluster-info --context kind-kind

    Have a nice day! 👋

    kubectl get nodes

    NAME                  STATUS   ROLES    AGE   VERSION
    kind-control-plane    Ready    master   21h   v1.16.3
    kind-control-plane2   Ready    master   21h   v1.16.3
    kind-control-plane3   Ready    master   21h   v1.16.3
    kind-worker           Ready    <none>   21h   v1.16.3
    kind-worker2          Ready    <none>   21h   v1.16.3
    kind-worker3          Ready    <none>   21h   v1.16.3
    ```

4. Создадим манифест `frontend-replicaset.yaml` для ReplicaSet согласно описанию, и попытаемся его запустить. Получим ошибку валидации:

    ```bash
    kubectl apply -f kubernetes-controllers/frontend-replicaset.yaml

    error: error validating "kubernetes-controllers/frontend-replicaset.yaml": error validating data: ValidationError(ReplicaSet.spec): missing required field "selector" in io.k8s.api.apps.v1.ReplicaSetSpec; if you choose to ignore these errors, turn validation off with --validate=false
    ```

5. Становится понятно, что отсутствует поле `selector`. Добавим поле в манифест и запустим снова:

    ```bash
    kubectl apply -f kubernetes-controllers/frontend-replicaset.yaml

    replicaset.apps/frontend created

    kubectl get pods

    NAME             READY   STATUS    RESTARTS   AGE
    frontend-6kp6k   1/1     Running   0          11s
    ```

6. Увеличим количество реплик до 3х:

    ```bash
    kubectl scale replicaset frontend --replicas=3

    kubectl get rs frontend

    NAME       DESIRED   CURRENT   READY   AGE
    frontend   3         3         3       11m
    ```

7. Проверим, что `ReplicaSet Controller` автоматически восстанавиливает поды:

    ```bash
    kubectl delete pods -l app=frontend | kubectl get pods -l app=frontend -w

    NAME             READY   STATUS    RESTARTS   AGE
    frontend-56bvg   1/1     Running   0          2m31s
    frontend-6kp6k   1/1     Running   0          12m
    frontend-c2t7w   1/1     Running   0          2m31s
    frontend-56bvg   1/1     Terminating   0          2m31s
    frontend-6xrp2   0/1     Pending       0          0s
    frontend-6kp6k   1/1     Terminating   0          12m
    frontend-6xrp2   0/1     Pending       0          0s
    frontend-pk4xc   0/1     Pending       0          0s
    frontend-6xrp2   0/1     ContainerCreating   0          1s
    frontend-c2t7w   1/1     Terminating         0          2m32s
    frontend-pk4xc   0/1     Pending             0          1s
    frontend-pk4xc   0/1     ContainerCreating   0          1s
    frontend-r9865   0/1     Pending             0          0s
    frontend-r9865   0/1     Pending             0          0s
    frontend-r9865   0/1     ContainerCreating   0          0s
    frontend-c2t7w   0/1     Terminating         0          2m33s
    frontend-r9865   1/1     Running             0          1s
    frontend-6kp6k   0/1     Terminating         0          12m
    frontend-pk4xc   1/1     Running             0          2s
    frontend-56bvg   0/1     Terminating         0          2m33s
    frontend-6xrp2   1/1     Running             0          2s
    frontend-c2t7w   0/1     Terminating         0          2m44s
    frontend-c2t7w   0/1     Terminating         0          2m44s
    frontend-56bvg   0/1     Terminating         0          2m44s
    frontend-6kp6k   0/1     Terminating         0          12m
    frontend-56bvg   0/1     Terminating         0          2m44s
    frontend-6kp6k   0/1     Terminating         0          12m

    kubectl get pods

    NAME             READY   STATUS    RESTARTS   AGE
    frontend-6xrp2   1/1     Running   0          14m
    frontend-pk4xc   1/1     Running   0          14m
    frontend-r9865   1/1     Running   0          14m
    ```

8. Повторно пременим манифест и убедимся, что количество реплик уменьшилось до 1. Затем модифицируем манифест увеличив количество реплик до трёх и применим манифест снова:

    ```bash
    kubectl apply -f kubernetes-controllers/frontend-replicaset.yaml
    kubectl get rs frontend

    NAME       DESIRED   CURRENT   READY   AGE
    frontend   1         1         1       31m

    vim kubernetes-controllers/frontend-replicaset.yaml
    kubectl apply -f kubernetes-controllers/frontend-replicaset.yaml
    kubectl get rs frontend

    NAME       DESIRED   CURRENT   READY   AGE
    frontend   3         3         3       39m
    ```

9. Симулируем деплой новой версии приложения.
    Создадим новый образ нашего фронтенд приложения: gidmaster/hipster-frontend:v0.0.2

    *NB: Все действия с Docker образами мы совершаем в другом репозитории*

    ```bash
    sudo docker build -t gidmaster/hipster-frontend:v0.0.2 .
    sudo docker push gidmaster/hipster-frontend:v0.0.2
    ```

    Поменяем имя образа в манифесте `frontend-replicaset.yaml` и применим `ReplicaSet`:

    ```bash
    kubectl apply -f frontend-replicaset.yaml | kubectl get pods -l app=frontend -w


    NAME             READY   STATUS    RESTARTS   AGE
    frontend-8d4w4   1/1     Running   0          39h
    frontend-pk4xc   1/1     Running   0          40h
    frontend-qwjct   1/1     Running   0          39h
    ```

    Ни каких изменений. Проверим версию образа в манифесте и ReplicaSet:

    ```bash
    kubectl get replicaset frontend -o=jsonpath='{.spec.template.spec.containers[0].image}'

    gidmaster/hipster-frontend:v0.0.2

    kubectl get pods -l app=frontend -o=jsonpath='{.items[0:3].spec.containers[0].image}'

    gidmaster/hipster-frontend:v0.0.1
    gidmaster/hipster-frontend:v0.0.1
    gidmaster/hipster-frontend:v0.0.1
    ```

    Так и есть ReplicaSet не изменился, версия приложения `v0.0.0.1`. то с вязано с тем что ReplicaSet не контролирует pods на соответствие шаблонов, А количество pods у нас в ReplicaSet сопадает.

    Пересоздадим ReplicaSet (удалим и создадим) из манифеста ещё раз.

    ```bash
    kubectl delete replicasets.apps frontend

    replicaset.apps "frontend" deleted

    kubectl apply -f kubernetes-controllers/frontend-replicaset.yaml | kubectl get pods -l app=frontend -w

    NAME             READY   STATUS    RESTARTS   AGE
    frontend-xn7tp   0/1     Pending   0          0s
    frontend-xn7tp   0/1     Pending   0          0s
    frontend-lc7m4   0/1     Pending   0          0s
    frontend-5n9cr   0/1     Pending   0          0s
    frontend-5n9cr   0/1     Pending   0          0s
    frontend-lc7m4   0/1     Pending   0          0s
    frontend-xn7tp   0/1     ContainerCreating   0          0s
    frontend-5n9cr   0/1     ContainerCreating   0          0s
    frontend-lc7m4   0/1     ContainerCreating   0          0s
    frontend-5n9cr   1/1     Running             0          1s
    frontend-xn7tp   1/1     Running             0          2s
    frontend-lc7m4   1/1     Running             0          2s

    kubectl get pods -l app=frontend -o=jsonpath='{.items[0:3].spec.containers[0].image}'
    gidmaster/hipster-frontend:v0.0.2
    gidmaster/hipster-frontend:v0.0.2
    gidmaster/hipster-frontend:v0.0.2
    ```

    Отлично. ReplicaSet запущен с новой версий ПО.

10. Начнём работу над созданием `Deployment` манифеста.
    Создадим образ приложения `paymentservice`  с метками "`v0.0.1`" и "`v0.0.2`". Затем поместим его в наш Docker Registry:

    ```bash
    sudo docker build -t gidmaster/hipster-paymentservice:v0.0.1 .
    sudo docker build -t gidmaster/hipster-paymentservice:v0.0.2 .
    sudo docker push gidmaster/hipster-paymentservice:v0.0.1
    sudo docker push gidmaster/hipster-paymentservice:v0.0.2
    ```

    Создадим ReplicaSet манифест для paymentservice ([документация](https://github.com/GoogleCloudPlatform/microservices-demo/blob/master/kubernetes-manifests/paymentservice.yaml)):

    ```yaml
    apiVersion: apps/v1
    kind: ReplicaSet
    metadata:
    name: paymentservice
    labels:
        app: paymentservice
    spec:
    replicas: 3
    selector:
        matchLabels:
        app: paymentservice
    template:
        metadata:
        labels:
            app: paymentservice
        spec:
        containers:
        - name: server
            image: gidmaster/hipster-paymentservice:v0.0.2
            ports:
            - containerPort: 50051
            env:
            - name: PORT
            value: "50051"
            resources:
            requests:
                cpu: 100m
                m kubectl rollout undo deployment paymentservice --to-revision=1 | kubectl get rs -l app=paymantwervice -wemory: 64Mi
            limits:
                cpu: 200m
                memory: 128Mi
    ```

    Создадим `Deployment` манифест, скопировав `ReplicaSet` манифест и поменяв поле `kind` с `ReplicaSet` на `Deployment`. запустим его и проверим, что  созданы `Deployment`, `ReplicaSet` привязанный к `Deployment`, а так же все 3 pod.

    ```bash
    kubectl apply -f kubernetes-controllers/paymentservice-deployment.yaml

    deployment.apps/paymentservice created

    kubectl get deployments.apps

    NAME             READY   UP-TO-DATE   AVAILABLE   AGE
    paymentservice   1/3     3            1           35s

    kubectl get rs

    NAME                        DESIRED   CURRENT   READY   AGE
    frontend                    3         3         3       68m
    paymentservice-855959b6f8   3         3         0       30s

    kubectl get pods

    NAME                              READY   STATUS    RESTARTS   AGE
    frontend-5n9cr                    1/1     Running   0          68m
    frontend-lc7m4                    1/1     Running   0          68m
    frontend-xn7tp                    1/1     Running   0          68m
    paymentservice-855959b6f8-bnz42   1/1     Running   0          41s
    paymentservice-855959b6f8-kfhxw   1/1     Running   0          41s
    paymentservice-855959b6f8-xhpxx   1/1     Running   0          41s
    ```

11. Изменим версию Docker образа на "`v0.0.2`" обновим Deploy из манифеста, а затем сделаем откат к предыдущей ревизии:

    ```bash
    kubectl apply -f kubernetes-controllers/paymentservice-deployment.yaml | kubectl get pods -l app=paymentservice
    NAME                              READY   STATUS        RESTARTS   AGE
    paymentservice-578c7589ff-dflqs   1/1     Terminating   0          16m
    paymentservice-578c7589ff-ggwvs   1/1     Terminating   0          16m
    paymentservice-578c7589ff-kzj5g   1/1     Terminating   0          16m
    paymentservice-855959b6f8-6qgl5   1/1     Running       0          11s
    paymentservice-855959b6f8-76zw6   1/1     Running       0          13s
    paymentservice-855959b6f8-k6hr9   1/1     Running       0          10s
    ```

    ```bash
    kubectl rollout undo deployment paymentservice --to-revision=1
    ```

12. Задание со *:

    С использованием параметров `maxSurge` и `maxUnavailable` реализуем blue-green и canary deployment сценарии развертывания.

    Основываясь на материалах лекции:
    * blue-green deployment можно реализовать указав параметры `maxSurge=100%` и `maxUnavailable=0`. Смысл будет в том, что `maxSurge=100%` позволит создать ReplicaSet с тем же количеством реплик. И тем самым, если вовермя поставить на паузу, мы получим две версии приложения в работе.
    * canary deployment можно реализовать указав параметры `maxSurge=1` и `maxUnavailable=0`. Классический канреечный релиз, мы последовательно поднимаем 1 d с новой версией, удаляем со старой и так далее, пока все podsне будут заменены новой версией.

13. Работаем с Probe:

    Создадим `frontend-deployment.yaml` по анолоигии с п.10 данного ДЗ. Затем добавим `ReadinessProbe` из [документации](https://github.com/GoogleCloudPlatform/microservices-demo/blob/master/kubernetes-manifests/frontend.yaml). И запустим `Deployment`.

    ```bash
    kubectl apply -f kubernetes-controllers/frontend-deployment.yaml

    deployment.apps/frontend created

    kubectl get deployments.apps

    NAME       READY   UP-TO-DATE   AVAILABLE   AGE
    frontend   3/3     3            3           48s
    ```

    Убедимся что ReadinessProbe присутствует в описении pod:

    ```bash
    kubectl get pods

    NAME                        READY   STATUS    RESTARTS   AGE
    frontend-6496f68cd5-4bpsg   1/1     Running   0          5m46s
    frontend-6496f68cd5-k94pl   1/1     Running   0          5m28s
    frontend-6496f68cd5-s7hqh   1/1     Running   0          5m7s

    kubectl describe pod frontend-6496f68cd5-s7hqh

    Name:         frontend-6496f68cd5-s7hqh
    Namespace:    default
    Priority:     0
    Node:         kind-worker2/172.17.0.6
    Start Time:   Sat, 21 Dec 2019 19:15:21 +0300
    Labels:       app=frontend
                pod-template-hash=6496f68cd5
    Annotations:  <none>
    Status:       Running
    IP:           10.244.5.15
    IPs:
    IP:           10.244.5.15
    Controlled By:  ReplicaSet/frontend-6496f68cd5
    Containers:
    server:
        Container ID:   containerd://3dc53836636037b665c03e522f0aa8b4e605c8fa73b80e58fd4ddc54550ce648
        Image:          gidmaster/hipster-frontend:v0.0.1
        Image ID:       docker.io/gidmaster/hipster-frontend@sha256:817a5862a1833b14f392a13adbc08d48f142b713476738e7bcef9f91f3e76090
        Port:           <none>
        Host Port:      <none>
        State:          Running
        Started:      Sat, 21 Dec 2019 19:15:22 +0300
        Ready:          True
        Restart Count:  0
        Limits:
        cpu:     200m
        memory:  128Mi
        Requests:
        cpu:      100m
        memory:   64Mi
        Readiness:  http-get http://:8080/_healthz delay=10s timeout=1s period=10s #success=1 #failure=3
        Environment:
        PORT:                          8080
        PRODUCT_CATALOG_SERVICE_ADDR:  productcatalogservice:3550
        CURRENCY_SERVICE_ADDR:         currencyservice:7000
        CART_SERVICE_ADDR:             cartservice:7070
        RECOMMENDATION_SERVICE_ADDR:   recommendationservice:8080
        SHIPPING_SERVICE_ADDR:         shippingservice:50051
        CHECKOUT_SERVICE_ADDR:         checkoutservice:5050
        AD_SERVICE_ADDR:               adservice:9555
        Mounts:
        /var/run/secrets/kubernetes.io/serviceaccount from default-token-9w9rj (ro)
    Conditions:
    Type              Status
    Initialized       True
    Ready             True
    ContainersReady   True
    PodScheduled      True
    Volumes:
    default-token-9w9rj:
        Type:        Secret (a volume populated by a Secret)
        SecretName:  default-token-9w9rj
        Optional:    false
    QoS Class:       Burstable
    Node-Selectors:  <none>
    Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                    node.kubernetes.io/unreachable:NoExecute for 300s
    Events:
    Type    Reason     Age        From                   Message
    ----    ------     ----       ----                   -------
    Normal  Scheduled  <unknown>  default-scheduler      Successfully assigned default/frontend-6496f68cd5-s7hqh to kind-worker2
    Normal  Pulled     5m32s      kubelet, kind-worker2  Container image "gidmaster/hipster-frontend:v0.0.1" already present on machine
    Normal  Created    5m32s      kubelet, kind-worker2  Created container server
    Normal  Started    5m31s      kubelet, kind-worker2  Started container server
    ```

    Сымитируем поведение пода, если probe будет провелена. Заменим поле `spec.template.spec.containers.readinessProbe.httpGet.path` на не валидное и запустим деплой.

    ```bash
    kubectl apply -f kubernetes-controllers/frontend-deployment.yaml
    deployment.apps/frontend configured

    kubectl get deployments.apps
    NAME       READY   UP-TO-DATE   AVAILABLE   AGE
    frontend   3/3     1            3           17h

    kubectl get pods
    NAME                        READY   STATUS    RESTARTS   AGE
    frontend-6496f68cd5-4bpsg   1/1     Running   0          17h
    frontend-6496f68cd5-k94pl   1/1     Running   0          17h
    frontend-6496f68cd5-s7hqh   1/1     Running   0          17h
    frontend-7b5b45dd56-vd76j   0/1     Running   0          2m12s

    kubectl describe pod frontend-7b5b45dd56-vd76j

    #---Ommited output---

    Events:
    Type     Reason     Age                  From                  Message
    ----     ------     ----                 ----                  -------
    Normal   Scheduled  <unknown>            default-scheduler     Successfully assigned default/frontend-7b5b45dd56-vd76j to kind-worker
    Normal   Pulled     2m44s                kubelet, kind-worker  Container image "gidmaster/hipster-frontend:v0.0.2" already present on machine
    Normal   Created    2m44s                kubelet, kind-worker  Created container server
    Normal   Started    2m44s                kubelet, kind-worker  Started container server
    Warning  Unhealthy  5s (x15 over 2m25s)  kubelet, kind-worker  Readiness probe failed: HTTP probe failed with statuscode: 404

    kubectl rollout status deployment/frontend
    Waiting for deployment "frontend" rollout to finish: 1 out of 3 new replicas have been updated...
    error: deployment "frontend" exceeded its progress deadline
    ```

14. Зададние со *:
    Рассмотрим и развернём `DeamonSet` с использованием `Node Exporter` Docker образа. Что бы запустить DeamonSet на мастер нодахх используем секцию `template.tolerations` указав ключ `node-role.kubernetes.io/master`.

    ```yaml
    apiVersion: apps/v1
    kind: DaemonSet
    metadata:
    name: node-exporter
    labels:
        app: node-exporter
    spec:
    selector:
        matchLabels:
        app: node-exporter
    template:
        metadata:
        labels:
            app: node-exporter
        spec:
        tolerations:
            - key: node-role.kubernetes.io/master
            effect: NoSchedule
        containers:
            - name: node-exporter
            image: quay.io/prometheus/node-exporter
    ```

    Запустим его и затем проверим сбор метрик:

    ``bash
    kubectl apply -f kubernetes-controllers/node-exporter-daemonset.yaml

    kubectl get pods

    NAME                       READY   STATUS    RESTARTS   AGE
    frontend-8d5d549c4-82vw9   1/1     Running   0          44m
    frontend-8d5d549c4-c4ht6   1/1     Running   0          44m
    frontend-8d5d549c4-lvfmc   1/1     Running   0          44m
    node-exporter-8qxk6        1/1     Running   0          25s
    node-exporter-ggzjp        1/1     Running   0          25s
    node-exporter-gm8wd        1/1     Running   0          25s
    node-exporter-hrhpz        1/1     Running   0          25s
    node-exporter-v4ssl        1/1     Running   0          25s
    node-exporter-whlxq        1/1     Running   0          25s

    kubectl port-forward node-exporter-8qxk6 9100:9100

    Forwarding from 127.0.0.1:9100 -> 9100
    Forwarding from [::1]:9100 -> 9100
    Handling connection for 9100

    curl localhost:9100/metrics

    # HELP go_gc_duration_seconds A summary of the GC invocation durations.
    # TYPE go_gc_duration_seconds summary
    go_gc_duration_seconds{quantile="0"} 0
    go_gc_duration_seconds{quantile="0.25"} 0
    go_gc_duration_seconds{quantile="0.5"} 0
    go_gc_duration_seconds{quantile="0.75"} 0
    go_gc_duration_seconds{quantile="1"} 0
    go_gc_duration_seconds_sum 0
    go_gc_duration_seconds_count 0
    #---Ommiterd output---
    ```


[Назад к содержанию](../README.md)
