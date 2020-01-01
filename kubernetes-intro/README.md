# Домашнее задание 1

[Содержание](../README.md)

*NB: Использован дистрибутив `Ubuntu 18.04` с предустановленным `Docker` и `VirtualBox` ПО.*

1. Устанавливаем утилиту kubectl:

    Используем менеджер пакетов ([документация](https://kubernetes.io/docs/tasks/tools/install-kubectl/)):

    ```bash
    sudo apt-get update && sudo apt-get install -y apt-transport-https
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubectl
    ```

    Настраиваем Автодополнение ([документация](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#kubectl-autocomplete)):

    ```bash
    source <(kubectl completion bash)
    echo "source <(kubectl completion bash)" >> ~/.bashrc
    ```

2. Устанавливаем и запускаем minikube ([документация](https://kubernetes.io/docs/tasks/tools/install-minikube/)):

    ```bash
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
    && chmod +x minikube
    sudo mkdir -p /usr/local/bin/
    sudo install minikube /usr/local/bin/
    minikube start --vm-driver=virtualbox
    ```

3. Проверяем подключение к запущеному кластеру:

    ```bash
    kubectl cluster-info
    ```

    Вывод команды:

    ```bash
    Kubernetes master is running at https://192.168.99.100:8443
    KubeDNS is running at https://192.168.99.100:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

    To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
    ```

4. Устанавливаем Addon Dashboard ([документация](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)):

    ```bash
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
    ```

    Получаем доступ к Web UI и проверяем его работу:

    ```bash
    kubectl proxy
    ```

    Проверяем доступность Дашборда по [адресу](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/):

    При запросе авторизации вводим токен и вывода следующей команды:

    ```bash
    kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
    ```

5. Тестируем устойчивость кластера minikube:

    Заходим внутрь виртуальной машины и смотрим запущенные Docker контейнеры, а затем пробуем их удалить и видим, что они восстанавились:

    ```bash
    minikube ssh
    docker ps
    docker rm -f $(docker ps -a -q)
    docker ps
    ```

    Попробуем сделать тоже самое используя kubectl и удалив все ноды:

    ```bash
    kubectl get pods -n kube-system
    NAME                               READY   STATUS    RESTARTS   AGE
    coredns-6955765f44-h4bvs           1/1     Running   0          2d6h
    coredns-6955765f44-h9pqw           1/1     Running   0          2d6h
    etcd-minikube                      1/1     Running   0          2d6h
    kube-addon-manager-minikube        1/1     Running   0          2d6h
    kube-apiserver-minikube            1/1     Running   0          2d6h
    kube-controller-manager-minikube   1/1     Running   0          2d6h
    kube-proxy-pg9j8                   1/1     Running   0          2d6h
    kube-scheduler-minikube            1/1     Running   0          2d6h
    storage-provisioner                1/1     Running   1          2d6h
    kubectl delete pod --all -n kube-system
    kubectl get componentstatuses
    NAME                 STATUS    MESSAGE             ERROR
    controller-manager   Healthy   ok
    scheduler            Healthy   ok
    etcd-0               Healthy   {"health":"true"}  
    kubectl get pods -n kube-system
    NAME                               READY   STATUS    RESTARTS   AGE
    coredns-6955765f44-h4bvs           1/1     Running   0          2d6h
    coredns-6955765f44-h9pqw           1/1     Running   0          2d6h
    etcd-minikube                      1/1     Running   0          2d6h
    kube-addon-manager-minikube        1/1     Running   0          2d6h
    kube-apiserver-minikube            1/1     Running   0          2d6h
    kube-controller-manager-minikube   1/1     Running   0          2d6h
    kube-proxy-pg9j8                   1/1     Running   0          2d6h
    kube-scheduler-minikube            1/1     Running   0          2d6h
    storage-provisioner                1/1     Running   1          2d6h
    ```

6. Подготовим `Dockerfile` удовлетворяющий следующим требованиям:
    * web-сервер на порту 8000 (можно использовать любой способ)
    * Отдающий содержимое директории /app внутри контейнера (например, если в директории /app лежит файл homework.html, то при запуске контейнера данный файл должен быть доступен по [URL](http://localhost:8000/homework.html)
    * Работающий с UID 1001

7. Соберём из него `Docker image` и поместим его в `DockerHub Container Registry`:

    ```bash
    sudo docker build -t gidmaster/otus-k8s-nginx .
    sudo docker push gidmaster/otus-k8s-nginx
    ```

8. Создадим манифест согласно шаблону используя созданый на пердыдущем шаге образ и применим его:

    ```bash
    kubectl apply -f web-pod.yaml
    ```

    Убедимся что в кластере в namespace default появился запущенный pod web

    ```bash
    kubectl get pods
    NAME READY STATUS  RESTARTS AGE
    web  1/1   Running 0        42s
    ```

9. Получим манифест существующего pod'а командой:

    ```bash
    kubectl get pod web -o yaml
    ```

    для того что бы получить описание pod'а используем:

    ```bash
    kubectl describe pod web
    ```

10. Добавим в манифест `init container` и `volumes` огласно описанию.
11. Перезапустим pod с новым манифестом удалив старый и запустив заново:

    ```bash
    kubectl delete pod web
    kubectl apply -f web-pod.yaml && kubectl get pods -w

    pod/web created
    NAME READY STATUS          RESTARTS AGE
    web  0/1   Init:0/1        0        0s
    web  0/1   Init:0/1        0        1s
    web  0/1   PodInitializing 0        2s
    web  1/1   Running         0        3s
    ```

12. Проверяем работоспосбность приложения по [ссылке](http://localhost:8000/index.html) используя `kubectl port-forwarding`:

    ```bash
    kubectl port-forward --address 0.0.0.0 pod/web 8000:8000
    ```

13. Далее в домашних заданиях мы будем использовать микросервисное приложение Hipster Shop. Клонируем [репозиторий](https://github.com/GoogleCloudPlatform/microservices-demo), собираем `Docker image` приложения `frontend` и пушим  `DockerHub ContainerRegistry`:

    ```bash
    git clone https://github.com/GoogleCloudPlatform/microservices-demo
    cd microservices-demo/src/frontend
    sudo docker build -t gidmaster/otus-frontend .
    sudo docker push  gidmaster/otus-frontend
    ```

14. Попробуем различные способы запуска frontend pod:

    ```bash
    kubectl run frontend --image  gidmaster/otus-frontend --restart=Never
    kubectl run frontend --image gidmaster/otus-frontend  -restart=Never --dryrun -o yaml > frontend-pod.yaml
    ```

15. Задание со *:

    в логах приложения видим, что нехватает объявленных переменных среды:

    ```bash
    kubectl logs frontend
    panic: environment variable "PRODUCT_CATALOG_SERVICE_ADDR" not set

    goroutine 1 [running]:
    main.mustMapEnv(0xc00027ec60, 0xb03c4a, 0x1c)
        /go/src/github.com/GoogleCloudPlatform/microservices-demo/src/frontendmain.go:248 +0x10e
    main.main()
        /go/src/github.com/GoogleCloudPlatform/microservices-demo/src/frontend/main.go:106 +0x3e9
    ```

    Идём в [документацию](https://github.com/GoogleCloudPlatform/microservices-demo/blob/master/kubernetes-manifests/frontend.yaml) и видим, что необходимо добавить несколько ENV переменных. Копируем frontend-pod.yaml в frontend-pod-healthy.yaml дополняем манифест переменными среды, удаляем старый pod и запускаем новый из манифеста frontend-pod-healthy.yaml:

    ```bash
    cp kubernetes-intro/frontend-pod.yaml kubernetes-intro/frontend-pod-healthy.yaml
    vim kubernetes-intro/frontend-pod-healthy.yaml
    kubectl delete pods frontend
    kubectl apply -f kubernetes-intro/frontend-podhealthy.yaml
    kubectl get pods
    NAME       READY   STATUS    RESTARTS   AGE
    frontend   1/1     Running   0          9s
    web        1/1     Running   0          25h
    ```

[Назад к содержанию](../README.md)
