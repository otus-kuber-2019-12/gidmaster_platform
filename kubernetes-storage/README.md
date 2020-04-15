# Домашнее задание 13

[Содержание](../README.md)

1. Развернём `minikube`:

    ```bash
    minikube start
    ```

2. Попробуем поставить CSI HostPath Driver:

    [Документация](https://github.com/kubernetes-csi/csi-driver-host-path/blob/master/docs/deploy-1.17-and-later.md)

    Задеплоим CDR для поддержки Snapshoots в кластер, согласно [офф.док](https://kubernetes.io/blog/2019/12/09/kubernetes-1-17-feature-cis-volume-snapshot-beta/):

    ```bash
    # Change to the latest supported snapshotter version
    SNAPSHOTTER_VERSION=v2.0.1

    # Apply VolumeSnapshot CRDs
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml

    # Create snapshot controller
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
    ```

    Проверим, что всё задеплоилось верно:

    ```bash
    kubectl get volumesnapshotclasses.snapshot.storage.k8s.io
    kubectl get volumesnapshots.snapshot.storage.k8s.io
    kubectl get volumesnapshotcontents.snapshot.storage.k8s.io
    ```

    Не видем ошибок `error: the server doesn't have a resource type "volumesnapshotclasses"` - всё отлично.

    Задеплоим CSI HostPath Driver:

    ```bash
    git clone git@github.com:kubernetes-csi/csi-driver-host-path.git
    cd csi-driver-host-path
    deploy/kubernetes-latest/deploy-hostpath.sh
    ```

    Провалидируем деплоймент:

    ```bash
    kubectl get pods
    NAME                         READY   STATUS    RESTARTS   AGE
    csi-hostpath-attacher-0      1/1     Running   0          4m24s
    csi-hostpath-provisioner-0   1/1     Running   0          4m21s
    csi-hostpath-resizer-0       1/1     Running   0          4m20s
    csi-hostpath-snapshotter-0   1/1     Running   0          4m19s
    csi-hostpath-socat-0         1/1     Running   0          4m18s
    csi-hostpathplugin-0         3/3     Running   0          4m22s
    snapshot-controller-0        1/1     Running   0          18m
    ```

    Запустим пример:

    ```bash
    for i in ./examples/csi-storageclass.yaml ./examples/csi-pvc.yaml ./examples/csi-app.yaml; do kubectl apply -f $i; done
    storageclass.storage.k8s.io/csi-hostpath-sc created
    persistentvolumeclaim/csi-pvc created
    pod/my-csi-app created
    ```

    Проверим как это работает:

    ```bash
    kubectl get pv
    NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS      REASON   AGE
    pvc-829fad3b-ef60-4640-865f-dd02dbbaffda   1Gi        RWO            Delete           Bound    default/csi-pvc   csi-hostpath-sc            78s
    ```

    ```bash
    kubectl get pvc
    NAME      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
    csi-pvc   Bound    pvc-829fad3b-ef60-4640-865f-dd02dbbaffda   1Gi        RWO            csi-hostpath-sc   2m18s
    ```

    ```bash
    kubectl describe pods/my-csi-app
    Name:         my-csi-app
    Namespace:    default
    Priority:     0
    Node:         minikube/192.168.99.114
    Start Time:   Fri, 10 Apr 2020 22:41:39 +0300
    Labels:       <none>
    Annotations:  Status:  Running
    IP:           172.17.0.14
    IPs:
    IP:  172.17.0.14
    Containers:
    my-frontend:
        Container ID:  docker://0aa7acf3dfe3ac82d2f4f790db34294f9cd66fbfe0368233110054f90b5aafca
        Image:         busybox
        Image ID:      docker-pullable://busybox@sha256:b26cd013274a657b86e706210ddd5cc1f82f50155791199d29b9e86e935ce135
        Port:          <none>
        Host Port:     <none>
        Command:
        sleep
        1000000
        State:          Running
        Started:      Fri, 10 Apr 2020 22:41:50 +0300
        Ready:          True
        Restart Count:  0
        Environment:    <none>
        Mounts:
        /data from my-csi-volume (rw)
        /var/run/secrets/kubernetes.io/serviceaccount from default-token-5l9s7 (ro)
    Conditions:
    Type              Status
    Initialized       True 
    Ready             True 
    ContainersReady   True 
    PodScheduled      True 
    Volumes:
    my-csi-volume:
        Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
        ClaimName:  csi-pvc
        ReadOnly:   false
    default-token-5l9s7:
        Type:        Secret (a volume populated by a Secret)
        SecretName:  default-token-5l9s7
        Optional:    false
    QoS Class:       BestEffort
    Node-Selectors:  <none>
    Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                    node.kubernetes.io/unreachable:NoExecute for 300s
    Events:
    Type    Reason                  Age    From                     Message
    ----    ------                  ----   ----                     -------
    Normal  Scheduled               5m8s   default-scheduler        Successfully assigned default/my-csi-app to minikube
    Normal  SuccessfulAttachVolume  5m8s   attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-829fad3b-ef60-4640-865f-dd02dbbaffda"
    Normal  Pulling                 5m2s   kubelet, minikube        Pulling image "busybox"
    Normal  Pulled                  4m57s  kubelet, minikube        Successfully pulled image "busybox"
    Normal  Created                 4m57s  kubelet, minikube        Created container my-frontend
    Normal  Started                 4m57s  kubelet, minikube        Started container my-frontend
    ```

    Нас интересуют секции:

    * `Containers.my-frontend.Mounts` - в контейнер замонтирован volume my-csi-volume в директорию /data.
    * `Volunes` - my-csi-volume это персистентное хранилице мозданое по заявке csi-pvc
    * `Events` - в ивентах можно увидеть, что volume успешно приатачен.

    Проверим как работает HostPath driver:

    Создадим файл в /data директории внутри конейнера в поде my-csi-app:

    ```bash
    kubectl exec -it my-csi-app -- /bin/sh

    touch /data/hello-world
    ls -la /data
    total 4
    drwxr-xr-x    2 root     root            60 Apr 10 20:03 .
    drwxr-xr-x    1 root     root          4096 Apr 10 19:41 ..
    -rw-r--r--    1 root     root             0 Apr 10 20:03 hello-world
    exit
    ```

    Проверим, что файлик появился в нашем HostPath контейнере:

    ```bash
    kubectl exec -it $(kubectl get pods --selector app=csi-hostpathplugin -o jsonpath='{.items[*].metadata.name}') -c hostpath -- /bin/sh

    find / -name hello-world
    /var/lib/kubelet/pods/2f145fe2-6c87-451f-a105-9d1911b21adf/volumes/kubernetes.io~csi/pvc-829fad3b-ef60-4640-865f-dd02dbbaffda/mount/hello-world
    /csi-data-dir/4bf4d2b9-7b63-11ea-81fd-0242ac110008/hello-world
    exit
    ```

    или из minikube:

    ```bash
    minikube ssh

    sudo find / -name hello-world
    /var/lib/csi-hostpath-data/4bf4d2b9-7b63-11ea-81fd-0242ac110008/hello-world
    /var/lib/kubelet/pods/2f145fe2-6c87-451f-a105-9d1911b21adf/volumes/kubernetes.io~csi/pvc-829fad3b-ef60-4640-865f-dd02dbbaffda/mount/hello-world
    /mnt/sda1/var/lib/kubelet/pods/2f145fe2-6c87-451f-a105-9d1911b21adf/volumes/kubernetes.io~csi/pvc-829fad3b-ef60-4640-865f-dd02dbbaffda/mount/hello-world
    ```

    Мы готовы к выполнению ДЗ.

    ```bash
    cd ../kubernetes-storage
    ```

3. Задание:

    * Создать StorageClass для CSI Host Path Driver
    * Создать объект PVC c именем `storage-pvc`
    * Создать объект Pod c именем `storage-pod`
    * Хранилище нужно смонтировать в `/data`

    Все манифесты для создания находятся в директориии `hw`. Задеплоим:

    ```bash
    for i in ./hw/storageClass.yaml ./hw/pvc.yaml ./hw/pod.yaml; do kubectl apply -f $i; done
    ```

    Сделаем теже проверки, что и для тестового приложения:

    ```bash
    kubectl get pv
    NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS      REASON   AGE
    pvc-3393f4eb-edb6-4284-af14-0625b61ea040   1Gi        RWO            Delete           Bound    default/storage-pvc   otus-sc                    45s
    pvc-829fad3b-ef60-4640-865f-dd02dbbaffda   1Gi        RWO            Delete           Bound    default/csi-pvc       csi-hostpath-sc            59m

    kubectl get pvc
    NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
    csi-pvc       Bound    pvc-829fad3b-ef60-4640-865f-dd02dbbaffda   1Gi        RWO            csi-hostpath-sc   59m
    storage-pvc   Bound    pvc-3393f4eb-edb6-4284-af14-0625b61ea040   1Gi        RWO            otus-sc           56s

    kubectl describe pods/storage-pod
    Name:         storage-pod
    Namespace:    default
    Priority:     0
    Node:         minikube/192.168.99.114
    Start Time:   Fri, 10 Apr 2020 23:40:08 +0300
    Labels:       <none>
    Annotations:  Status:  Running
    IP:           172.17.0.15
    IPs:
    IP:  172.17.0.15
    Containers:
    app:
        Container ID:  docker://4dd787c54a2ebfad8614cf20f1ea80525da1dd556b1b558fe859936885e79c54
        Image:         busybox
        Image ID:      docker-pullable://busybox@sha256:b26cd013274a657b86e706210ddd5cc1f82f50155791199d29b9e86e935ce135
        Port:          <none>
        Host Port:     <none>
        Command:
        sleep
        1000000
        State:          Running
        Started:      Fri, 10 Apr 2020 23:40:20 +0300
        Ready:          True
        Restart Count:  0
        Environment:    <none>
        Mounts:
        /data from data-volume (rw)
        /var/run/secrets/kubernetes.io/serviceaccount from default-token-5l9s7 (ro)
    Conditions:
    Type              Status
    Initialized       True 
    Ready             True 
    ContainersReady   True 
    PodScheduled      True 
    Volumes:
    data-volume:
        Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
        ClaimName:  storage-pvc
        ReadOnly:   false
    default-token-5l9s7:
        Type:        Secret (a volume populated by a Secret)
        SecretName:  default-token-5l9s7
        Optional:    false
    QoS Class:       BestEffort
    Node-Selectors:  <none>
    Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                    node.kubernetes.io/unreachable:NoExecute for 300s
    Events:
    Type    Reason                  Age   From                     Message
    ----    ------                  ----  ----                     -------
    Normal  Scheduled               70s   default-scheduler        Successfully assigned default/storage-pod to minikube
    Normal  SuccessfulAttachVolume  70s   attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-3393f4eb-edb6-4284-af14-0625b61ea040"
    Normal  Pulling                 61s   kubelet, minikube        Pulling image "busybox"
    Normal  Pulled                  58s   kubelet, minikube        Successfully pulled image "busybox"
    Normal  Created                 58s   kubelet, minikube        Created container app
    Normal  Started                 58s   kubelet, minikube        Started container app
    ```

    Работает!

4. Протестируем функционал снапшотов:

    Для начала добавим `VolumeSnapshotClass`:

    ```bash
    kubectl apply -f ./hw/volumeSnapshotClass.yaml
    ```

    Сгенирируем даных для снапшота:

    ```bash
    kubectl exec -it storage-pod -- /bin/sh/

    touch /data/hello-world
    touch /data/test
    touch /data/test2
    exit
    ```

    Сделаем снапшот:

    ```bash
    kubectl apply -f ./hw/snapshotVolume.yaml
    ```

    Посмотрим, что получилось:

    ```bash
    kubectl describe volumesnapshot
    Name:         test-snapshot
    Namespace:    default
    Labels:       <none>
    Annotations:  API Version:  snapshot.storage.k8s.io/v1beta1
    Kind:         VolumeSnapshot
    Metadata:
    Creation Timestamp:  2020-04-10T21:31:51Z
    Finalizers:
        snapshot.storage.kubernetes.io/volumesnapshot-as-source-protection
        snapshot.storage.kubernetes.io/volumesnapshot-bound-protection
    Generation:        1
    Resource Version:  27846
    Self Link:         /apis/snapshot.storage.k8s.io/v1beta1/namespaces/default/volumesnapshots/test-snapshot
    UID:               5d55bf95-8965-4e99-9789-b4a7ede03e9b
    Spec:
    Source:
        Persistent Volume Claim Name:  storage-pvc
    Volume Snapshot Class Name:      test-snapclass
    Status:
    Bound Volume Snapshot Content Name:  snapcontent-5d55bf95-8965-4e99-9789-b4a7ede03e9b
    Creation Time:                       2020-04-10T21:31:51Z
    Ready To Use:                        true
    Restore Size:                        1Gi
    Events:                                <none>
    ```

    Отлично - у нас есть Snapshot.

    Сгенерируем ещё данных в контейнере, уже после создания snapshot'a, чтобы позже сравнить:

    ```bash
    kubectl exec -it storage-pod -- /bin/sh

    ls -na /data
    total 4
    drwxr-xr-x    2 0        0              100 Apr 10 21:25 .
    drwxr-xr-x    1 0        0             4096 Apr 10 20:40 ..
    -rw-r--r--    1 0        0                0 Apr 10 21:25 hello-world
    -rw-r--r--    1 0        0                0 Apr 10 21:25 test
    -rw-r--r--    1 0        0                0 Apr 10 21:25 test2
    touch /data/after-snapshot
    ls -na /data
    total 4
    drwxr-xr-x    2 0        0              120 Apr 10 21:38 .
    drwxr-xr-x    1 0        0             4096 Apr 10 20:40 ..
    -rw-r--r--    1 0        0                0 Apr 10 21:38 after-snapshot
    -rw-r--r--    1 0        0                0 Apr 10 21:25 hello-world
    -rw-r--r--    1 0        0                0 Apr 10 21:25 test
    -rw-r--r--    1 0        0                0 Apr 10 21:25 test2
    exit
    ```

    Создадим PVC из снапшота:

    ```bash
    kubectl apply -f ./hw/pvcFromSnapshot.yaml
    ```

    Проверим, что у нас есть новые persdidtentVolume:

    ```bash
    kubectl get pvc
    NAME                  STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
    csi-pvc               Bound    pvc-829fad3b-ef60-4640-865f-dd02dbbaffda   1Gi        RWO            csi-hostpath-sc   122m
    storage-pvc           Bound    pvc-3393f4eb-edb6-4284-af14-0625b61ea040   1Gi        RWO            otus-sc           63m
    storage-pvc-resored   Bound    pvc-e12f6140-3ad2-41dc-820d-7b92335c72a4   1Gi        RWO            otus-sc           11s

    kubectl get pv
    NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                         STORAGECLASS      REASON   AGE
    pvc-3393f4eb-edb6-4284-af14-0625b61ea040   1Gi        RWO            Delete           Bound    default/storage-pvc           otus-sc                    63m
    pvc-829fad3b-ef60-4640-865f-dd02dbbaffda   1Gi        RWO            Delete           Bound    default/csi-pvc               csi-hostpath-sc            122m
    pvc-e12f6140-3ad2-41dc-820d-7b92335c72a4   1Gi        RWO            Delete           Bound    default/storage-pvc-resored   otus-sc
    ```

    Приятно видеть!

    развернём под c востановленым из снапшота volume:

    ```bash
    kubectl apply -f ./hw/podFromSnapshot.yaml
    ```

    Посмотрим, что внутри:

    ```bash
    kubectl exec -it storage-pod-restored -- /bin/sh

    ls -na /data
    total 4
    drwxr-xr-x    2 0        0              100 Apr 10 21:43 .
    drwxr-xr-x    1 0        0             4096 Apr 10 21:48 ..
    -rw-r--r--    1 0        0                0 Apr 10 21:25 hello-world
    -rw-r--r--    1 0        0                0 Apr 10 21:25 test
    -rw-r--r--    1 0        0                0 Apr 10 21:25 test2
    ```

    Прекрасно - Магия работает!

[Назад к содержанию](../README.md)
