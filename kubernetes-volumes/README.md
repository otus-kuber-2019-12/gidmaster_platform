# Домашнее задание 5

[Содержание](../README.md)

*NB: Использован дистрибутив `Ubuntu 18.04` с предустановленным `kind` и `VirtualBox` ПО.*

1. Развернём `kind`кластер.

    ```bash
    kind create cluster
    ```

2. Развернём `MinIO` - локальные S3 хранилищем.

    Создадим манифест `minio-stateful.yaml` и скопируем содержание от[сюда](https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Kuberenetes-volumes/minio-statefulset.yaml).

    Применим конфигурацию:

    ```bash
    kubectl apply -f kubernetes-volumes/minio-stateful.yaml
    ```

    Создадим манифест `minio-headlessservice.yaml` и скопируем содержание от[сюда](https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Kuberenetes-volumes/minio-headless-service.yaml).

    Применим конфигурацию:

    ```bash
    kubectl apply -f kubernetes-volumes/minio-headlessservice.yaml
    ```

    В результате применения конфигурации должно произойти следующее:
    * Запуститься под с MinIO
    * Создаться PVC
    * Динамически создаться PV на этом PVC с помощью дефолотного
    * StorageClass

    Проверим что было сделано:

    ```bash
    kubectl get statefulsets

    NAME    READY   AGE
    minio   1/1     15m

    kubectl get pods

    NAME      READY   STATUS    RESTARTS   AGE
    minio-0   1/1     Running   0          8m20s

    kubectl get pvc

    NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    data-minio-0   Bound    pvc-9c660aba-402a-4a01-9641-e3279b76d948   10Gi       RWO            standard       16m

    kubectl get pv

    NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS   REASON   AGE
    pvc-9c660aba-402a-4a01-9641-e3279b76d948   10Gi       RWO            Delete           Bound    default/data-minio-0   standard                17m

    kubectl describe <resource> <resource_name>
    ```

3. Задание со *:

    Согласно описанию [secrets](https://kubernetes.io/docs/concepts/configuration/secret/) мы должны создать отдельный манифест с секратами, при этом "зашифровать" секреты в Base64. и модифицировать манифест `StatefulSet` для использования volume типа secret.

[Назад к содержанию](../README.md)
