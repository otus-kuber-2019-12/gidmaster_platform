# Домашнее задание 6

[Содержание](../README.md)

*NB: Использован дистрибутив `Ubuntu 18.04` с предустановленным с предустановленным `Docker` `minikube` и `VirtualBox` ПО.*

1. Custom Resource:

    Поднимем кластер `minikube`

    ```bash
    minikube start  
    ```

    Создадим Custom resource мафнифест `kubernetes-operators\deploy\cr.yml` и попробуем применить его:

    ```bash
    kubectl apply -f deploy/cr.yml

    error: unable to recognize "deploy/cr.yml": no matches for kind "MySQL" in version "otus.homework/v1"
    ```

    Ошибка связана с отсутсвием объектов типа MySQL в API kubernetes. Нам необходимо определить наш custom resorce. Для этого мы создадим Custom Resouce Definition (CRD).

2. Custom Resouce Definition:

    Создадим Custom resource definition мафнифест `kubernetes-operators\deploy\crd.yml` и попробуем применить его:

    ```bash
    kubectl apply -f deploy/crd.yml
    ```

3. Создаем CRD и CR:

    Теперь попробуем применить наш манифест с custom resource:

    ```bash
    kubectl apply -f deploy/cr.yml
    ```

    Успешно!

4. Взаимодействие с объектами CR CRD

    Посмотрим информацию о нём:

    ```bash
    kubectl get crd
    NAME                   CREATED AT
    mysqls.otus.homework   2020-01-29T20:02:07Z

    kubectl get mysqls.otus.homework
    NAME             AGE
    mysql-instance   88s

    kubectl describe mysqls.otus.homework mysql-instance
    Name:         mysql-instance
    Namespace:    default
    Labels:       <none>
    Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                    {"apiVersion":"otus.homework/v1","kind":"MySQL","metadata":{"annotations":{},"name":"mysql-instance","namespace":"default"},"spec":{"datab...
    API Version:  otus.homework/v1
    Kind:         MySQL
    Metadata:
    Creation Timestamp:  2020-01-29T20:03:17Z
    Generation:          1
    Resource Version:    2013
    Self Link:           /apis/otus.homework/v1/namespaces/default/mysqls/mysql-instance
    UID:                 6ed0da68-09d8-4a75-8f77-b5d5f16839ec
    Spec:
    Database:      otus-database
    Image:         mysql:5.7
    Password:      otuspassword
    storage_size:  1Gi
    usless_data:     useless info
    Events:          <none>
    ```

5. Validation:

    Добавим Validation в спецификацию CDR м попробуем опять применить манифесты crd.yml и cr.yml:

    ```bash
    kubectl delete mysqls.otus.homework mysql-instance
    kubectl apply -f deploy/crd.yml
    kubectl apply -f deploy/cr.yml
    ```

    Объявим "обязательне" поля в спецификации, добавив дерективу `spec.validation.spec.reqiored` в CRD. Удалим "обязателное" поле из манивеста и попробуем применить его:

    ```basj
    kubectl apply -f deploy/crd.yml
    customresourcedefinition.apiextensions.k8s.io/mysqls.otus.homework configured

    kubectl apply -f deploy/cr.yml
    The MySQL "mysql-instance" is invalid: spec.storage_size: Required value
    ```

    Отлично. Работает.

6. Операторы:

    Оператор включает в себя CRD и custom controller. CustomResourceDefinition у нас уже есть приступим к конроллеру. Полное описание кода есть в домашнем задании. Здесь я не буду приводить код. его можно поосмотреть в репозитории.

    *NB: Используемый фреймфорк `kopf` совместим с версией `python>=3.7`.*

    на первом этапе мы только сделаем [функцию](https://gist.githubusercontent.com/Evgenikk/581fa5bba6d924a3438be1e3d31aa468/raw/c7c0b8882550ab54d981a4941959276802fe0233/controller-1.py) для создания объекта `mqsql`. Попробуем его запустить.

    ```bash
    cd kubernetes-operators/build
    kopf run msql-operator.py
    ```

    Получим:

    ```bash
    [2020-02-01 22:55:03,165] kopf.reactor.activit [INFO    ] Initial authentication has been initiated.
    [2020-02-01 22:55:03,197] kopf.activities.auth [INFO    ] Handler 'login_via_pykube' succeeded.
    [2020-02-01 22:55:03,239] kopf.activities.auth [INFO    ] Handler 'login_via_client' succeeded.
    [2020-02-01 22:55:03,240] kopf.reactor.activit [INFO    ] Initial authentication has finished.
    [2020-02-01 22:55:03,296] kopf.engines.peering [WARNING ] Default peering object not found, falling back to the standalone mode.
    mysql-operator.py:9: YAMLLoadWarning: calling yaml.load() without Loader=... is deprecated, as the default Loader is unsafe. Please read https://msg.pyyaml.org/load for full details.
    json_manifest = yaml.load(yaml_manifest)
    [2020-02-01 22:55:03,827] kopf.objects         [INFO    ] [default/mysql-instance] Handler 'mysql_on_create' succeeded.
    [2020-02-01 22:55:03,828] kopf.objects         [INFO    ] [default/mysql-instance] All handlers succeeded for creation.
    [2020-02-01 23:18:46,940] kopf.reactor.running [INFO    ] Signal SIGINT is received. Operator is stopping.
    ```

    **Вопрос: почему объект создался, хотя мы создали CR, до того, как запустили контроллер?**
    Запись о CustomResource  попала в etcd и информация о ней может быть получена через kube-apiserver. Когда появляется новый ресурс, его обнаруживает контроллер mysql-operator, в задачи которого входит отслеживание изменений среди соответствующих записей пкесурсов (MySql). В нашем случае контроллер регистрирует специальный callback для событий создания через информатор. Этот обработчик будет вызван, когда mysql-operator впервые станет доступным, и начнёт свою работу с добавления объекта во внутреннюю очередь. К тому времени, когда он дойдёт до обработки этого объекта, контроллер проинспектирует и поймёт, что нет связанных с ним записей pv, pvc, service, deployment и подов. Эту информацию он получает, опрашивая kube-apiserver по label selectors. Важно заметить, что этот процесс синхронизации ничего не знает о состоянии (является state agnostic): он проверяет новые записи точно так же, как и уже существующие. А значит не важно когда контроллер был запущен, он запросит и обработает все записи о ресурсах, за кторые он отвечает и только для тех которые ещё "не обработаны" юужут созданы соответствующие ресурсы.

    Т.к. мы описали только логику создания ресурса, но не его удаления. комманда `kubectl delete mysqls.otus.homework mysql-instance` ничего не сделает. Удалим ресурасы в ручную:

    ```bash
    kubectl delete mysqls.otus.homework mysql-instance
    kubectl delete deployments.apps mysql-instance
    kubectl delete pvc mysql-instance-pvc
    kubectl delete pv mysql-instance-pv
    kubectl delete svc mysql-instance
    ```

    Добавим обработку удаления объектов в наш код. [пример](https://gist.githubusercontent.com/Evgenikk/581fa5bba6d924a3438be1e3d31aa468/raw/8308e18203e191d0318f2f6d4ec6459b27e1b56e/controller-2.py)

    Создадим наш ресурс заново, запустим контроллер у попробуем его удалить.

    ```bash
    kopf run mysql-operator.py
    ```

    ```bash
    kubectl apply -f deploy/cr.yml
    kubectl delete -f deploy/cr.yml
    kubectl get all
    kubectl get pvc
    kubectl get pv
    ```

    Реализуем создание и воссатновление из бекапов нашего ресурса. [пример](https://gist.github.com/Evgenikk/581fa5bba6d924a3438be1e3d31aa468/raw/8a3ef47ed87128867496fbb45ae4fd483b2549db/controller-4.py)

    *NB: в коде из примера не хватает строчки `kopf.append_owner_reference(restore_job, owner=body)`*

    Проверяем как это всё работает

    ```bash
    kopf run mysql-operator.py
    ```

    ```bash
    kubectl apply -f deploy/cr.yml
    kubectl get pvc
    export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")

    kubectl exec -it $MYSQLPOD -- mysql -u root -potuspassword -e "CREATE TABLE test ( id smallint unsigned not null auto_increment, name varchar(20) not null, constraint pk_example primary key (id) );" otus-database

    kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) VALUES ( null, 'some data' );" otus-database
    kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) VALUES ( null, 'some data-2' );" otus-database
    kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
    +----+-------------+
    | id | name        |
    +----+-------------+
    |  1 | some data   |
    |  2 | some data-2 |
    +----+-------------+
    ```

    Удалим mysql-instance:

    ```bash
    kubectl delete mysqls.otus.homework mysql-instance
    kubectl get pv
    kubectl get jobs.batch
    ```

    Создадим новцй копию нашего инстанса и проверим получилось ли восстановится из backup:

    ```bash
    kubectl apply -f deploy/cr.yml

    export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
    kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
    +----+-------------+
    | id | name        |
    +----+-------------+
    |  1 | some data   |
    |  2 | some data-2 |
    +----+-------------+
    ```

    Наш самописный контроллер работает! Теперь обернём его в Docker контейнер запушим в репозиторий.

    ```bash
    cd build
    docker build -t gidmaster/mysql-operator:v0.1 .
    docker push  gidmaster/mysql-operator:v0.1
    ```

    Создадим роль, sa и deployment и наконец загрузим наш контроллер в кластер:

    ```bash
    kubectl apply -f /deploy
    ```

    и выполним туже проверку, что мы сделали ранее:

    ```bash
    kubectl apply -f deploy/cr.yml
    kubectl get pvc
    export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")

    kubectl exec -it $MYSQLPOD -- mysql -u root -potuspassword -e "CREATE TABLE test ( id smallint unsigned not null auto_increment, name varchar(20) not null, constraint pk_example primary key (id) );" otus-database

    kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) VALUES ( null, 'some data' );" otus-database
    kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) VALUES ( null, 'some data-2' );" otus-database
    kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
    +----+-------------+
    | id | name        |
    +----+-------------+
    |  1 | some data   |
    |  2 | some data-2 |
    +----+-------------+
    ```

    Удалим mysql-instance:

    ```bash
    kubectl delete mysqls.otus.homework mysql-instance
    kubectl get pv
    kubectl get jobs.batch
    ```

    Создадим новцй копию нашего инстанса и проверим получилось ли восстановится из backup:

    ```bash
    kubectl apply -f deploy/cr.yml

    export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
    kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
    +----+-------------+
    | id | name        |
    +----+-------------+
    |  1 | some data   |
    |  2 | some data-2 |
    +----+-------------+
    ```

[Назад к содержанию](../README.md)
