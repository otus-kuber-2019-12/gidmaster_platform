# Домашнее задание 6

[Содержание](../README.md)

*NB: Использован дистрибутив `Ubuntu 18.04` с предустановленным `gcloud/gsutils`. А так же зарарнее созданным и сконфигурированным Kubernetes кластером в `GKE`, и собственным доменом*

1. Создадим GKE кластер:

    ```bash
    cd terraform
    terraform apply
    ```

2. Скачиваем и устанавливаем `helm`:

    ```bash
    wget https://get.helm.sh/helm-v3.0.2-linux-amd64.tar.gz
    tar xvzf helm-v3.0.2-linux-amd64.tar.gz
    cd linux-amd64
    sudo cp helm /usr/local/sbin/

    helm version
    version.BuildInfo{Version:"v3.0.2", GitCommit:"19e47ee3283ae98139d98460de796c1be1e3975f", GitTreeState:"clean", GoVersion:"go1.13.5"}
    ```

3. Установим `nginx-ingress` из готовых helm charts:

    Добавим новый репозиторий в котором мы сможем найти `nginx-ingress` chart:

    ```bash
    helm repo add stable https://kubernetes-charts.storage.googleapis.com

    helm repo list
    NAME URL
    stable https://kubernetes-charts.storage.googleapis.com
    ```

    Создадим namespace и release nginx-ingress:

    ```bash
    kubectl create ns nginx-ingress

    helm upgrade --install nginx-ingress stable/nginx-ingress --wait \
    --namespace=nginx-ingress \
    --version=1.11.1
    ```

4. Установим `cert-mamanger`:

    Добавим ещё один репозиторий helm charts который содержит cert-manager:

    ```bash
    helm repo add jetstack https://charts.jetstack.io
    ```

    Cогласно [документации](https://github.com/jetstack/cert-manager/tree/master/deploy/charts/cert-manager) устанавливаем cert-manager

    ```bash
    kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml
    kubectl create ns cert-manager
    kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true"

    helm upgrade --install cert-manager jetstack/cert-manager --wait \
    --namespace=cert-manager \
    --version=0.9.0
    ```

    Согласно [документации](https://github.com/jetstack/cert-manager/tree/master/deploy/charts/cert-manager) нам так же понадобится `Issuer` или `ClusterIssurer` ресурс. Восспользуемся `ClusterIssuer` с использованием "Let's Encrypt" в качестве CA. Используем [базовую конфигурацию](https://cert-manager.io/docs/configuration/acme/#creating-a-basic-acme-issuer). Применим манифесты

    ```bash
    kubectl apply -f kubernetes-templating/cert-manager/ -n cert-manager
    ```

5. Установим `chartmuseum`

    Узнаем адрес нашего nginx-ingress:

    ```bash
        kubectl get svc -n nginx-ingress
    NAME                            TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
    nginx-ingress-controller        LoadBalancer   10.27.246.111   35.227.143.15   80:30388/TCP,443:30040/TCP   80m
    nginx-ingress-default-backend   ClusterIP      10.27.240.180   <none>          80/TCP                       80m
    ```

    Создадим файл `values.yaml` и переопределим конфигурацию nginx-ingress использовав TLS и hosts, А за тем установим chartmeuseum с внесёнными изменениями.

    ```bash
    kubectl create ns chartmuseum
    helm upgrade --install chartmuseum stable/chartmuseum --wait \
    --namespace=chartmuseum \
    --version=2.3.2 \
    -f kubernetes-templating/chartmuseum/values.yaml
    ```

    Проверим, что у нас теперь есть chartmuseum в kubernetes:

    ```bash
    helm ls -n chartmuseum
    ```

    Проверим что мы получили валидный SSL сертификат:

    ```bash
    curl --insecure -v https://chartmuseum.gidmaster.dev  2>&1 | awk 'BEGIN { cert=0 } /^\* Server certificate:/ { cert=1 } /^\*/ { if (cert) print }'
    ```

6. Задание со *:

    Чуть-чуть посмотрим на работу с chartmeuseum:

    * Добавим в chartmuseum как helm репозиторий:

    ```bash
    helm repo add chartmuseum https://chartmuseum.gidmaster.dev
    helm repo update
    ```

    * Найдём и склонируем себе како-нибудь git репозиторий с helm чартом:

    ```bash
    git clone git@github.com:stakater/chart-mysql.git
    cd chart-mysql/mysql
    ```

    * Проверим chart командой helm lint и убедимся что чарт не содержит ошибок:

    ```bash
    helm lint
    ==> Linting .
    [INFO] Chart.yaml: icon is recommended

    1 chart(s) linted, 0 chart(s) failed
    ```

    * Запустим `helm package .` что бы упаковать чарт в архив. Имя пакета будет `mysql-1.0.3.tgz`, где `mysql` имя чарта, а `1.0.3` его версия.

    ```bash
    helm package .
    Successfully packaged chart and saved it to: chart-mysql/mysql/mysql-1.0.3.tgz
    ```

    * Загрузим наш чарт:

    ```bash
    curl  --data-binary "@mysql-1.0.3.tgz" https://chartmuseum.gidmaster.dev/api/charts
    ```

    Теперь с этим чартом можно работать так же как мы уже работали с nginx-ingress, cert-mamager etc.

7. Установим `harbor`:

    Создадим файл `values.yaml` и переопределим конфигурацию nginx-ingress использовав TLS и hosts, так же отключим сервис `notary` и установим `harbor`

    ```bash
    helm repo add harbor https://helm.goharbor.io
    kubectl create ns harbor
    helm upgrade --install harbor harbor/harbor --wait \
    --namespace=harbor \
    --version=1.1.2 \
    -f kubernetes-templating/harbor/values.yaml
    ```

    Проверим что мы получили валидный SSL сертификат:

    ```bash
    curl --insecure -v https://harbor.gidmaster.dev  2>&1 | awk 'BEGIN { cert=0 } /^\* Server certificate:/ { cert=1 } /^\*/ { if (cert) print }'
    ```

8. Задание со *:

    Создадим `helmfile.yaml` согласно требований.
    Удалим старый кластер и создадим его заново. А затем запустим helmfile

    ```bash
    cd terraform
    terraform destroy
    terrrform apply
    cd ../helmfile
    helmfile -b helm3 apply
    ```

9. Создадим свой helm chart:

    Создадим типичную структуру:

    ```bash
    helm create kubernetes-templating/hipster-shop
    ```

    Т.к. мы будем создавать чарт с нуля - удалим values.yaml и содержимое папки templates и скопируем [файл](https://github.com/express42/otus-platform-snippets/blob/master/Module-04/05-Templating/manifests/all-hipster-shop.yaml) в папку templates

    Запустим и установим наш `hipster-shop`

    ```bash
    kubectl create ns hipster-shop
    helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop
    ```

    Разнесём мега файл `all-hipster-shop.yaml` на соотетстврующие коипоненты начнём с frontend.

    Создадим заготовку не забудем удалить values.yaml и содержимое папки templates:

    ```bash
    helm create kubernetes-templating/frontend
    ```

    Вынесем deployment и service `frontend` в kubernetes-templating/frontend, а там же добавим ingress. Затем повторно применим chart all-hipster-shop.yaml, а после новый чарт frontend.

    ```bash
    helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop
    helm upgrade --install frontend kubernetes-templating/frontend --namespace hipster-shop
    ```

    Шаблонизируем чарт `frontend`. Для этого добавим `values.yaml` и в несём в него несколько параметров. При этом заменив конкретные значения в `deployment.yaml` и `service.yaml` на переменные.

    Добавим в `Chart.yaml` в `all-hipster-shop` в качестве зависимости чарт `frontend`. и запустим обновления ещё раз.

    ```bash
    helm delete frontend -n hipster-shop
    helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop
    ```

10. Задание со *:

    Добавить в зависимости redis из coomunity charts. См. kubernetes-templating/hipster-shop/Chart.yaml

    Важно помнить, что после добавления зависимостей, нужно сделать `helm dependency update`.

11. Не обязательное задание работа с helm-secrets: **не сделано**

12. Kubecfg:

    Вынесем по аналогии с `frontend` сервисы `paymentservice` и `shippingservce` в директорию `kubernetes-templating\kubecfg`.

    Устаговим `kubecfg`:

    ```bash
    wget https://github.com/bitnami/kubecfg/releases/download/v0.14.0/kubecfg-linux-amd64
    sudo mv ~/Downloads/kubecfg-linux-amd64 /usr/local/sbin/kubecfg
    sudo chmod +x /usr/local/sbin/kubecfg

    kubecfg version
    kubecfg version: v0.14.0
    jsonnet version: v0.14.0
    client-go version: v0.0.0-master+$Format:%h$
    ```

    Пишем общий шаблон `service.jsonnet` для сервисов, включающий описание service и deployment для shippingservice и deploymentservice.

    Проверим, что манифесты генерируются корректно:

    ```bash
    kubecfg show services.jsonnet
    ```

    И установим их:

    ```bash
    kubecfg update services.jsonnet --namespace hipster-shop
    ```

13. Задание со *:  **не сделано**

    Выберите еще один микросервис из состава hipster-shop и попробуйте использовать другое решение на основе jsonnet, например `Kapitan` или `qbec`.
    Приложите артефакты их использования в директорию kubernetes-templating/jsonnet и опишите проделанную работу и порядок установки.

14. Kustomize:

    Установим kustomize ([документация](https://kubernetes.io/blog/2018/05/29/introducing-kustomize-template-free-configuration-customization-for-kubernetes/) и [ещё документация](https://github.com/kubernetes-sigs/kustomize)):

    ```bash
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
    ```

    Возьмём сервис `recommendationservice`. Уберём его описание из `all-hipster-shop.yaml` и перенесём его в директорию `kubernetes-templating/kustomize/base`.

    Проверим что YAML с манифестами генерируется валидным:

    ```bash
    kustomize build kubernetes-templating/kustomize/base/
    ```

    Создадим дирректории `kubernetes-templating/kustomize/overriddes/hipster-shop[-prod]`  и добавим туда файлы с кастомизацией, которые переписывают переменные (такие как labels) для наших манифестов в зависимости от среды  применим их:

    ```bash
    kubectl apply -k kubernetes-templating/kustomize/overrides/hispter-shop/
    kubectl apply -k kubernetes-templating/kustomize/overrides/hispter-shop-prod/
    ```

[Назад к содержанию](../README.md)
