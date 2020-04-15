# Домашнее задание 3

[Содержание](../README.md)

*NB: Использован дистрибутив `Ubuntu 18.04` с предустановленным `Docker` и `VirtualBox` ПО.*

1. Развернём `kind`кластер воспользовавшись конфигурацией из предыдущего задания.

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

    Запустим кластер:

    ```bash
    kind create cluster --config kind-config.yaml
    ```

2. Задача 1:
    * Создать Service Account bob, дать ему роль admin в рамках всего кластера
    Мы реализуем данную задачу в 2 шага:
        1. Создадим объект `ServiceAccount` `bob`, который будет использоваться для аутентификации$
        2. Создадим объект `ClusterRoleBinding` в котором привяжем `ServiceAccount bob` к кластерной роли `admin`, что позволит нам получить доступ к кластеру, с правами администраратора.
    * Создать Service Account dave без доступа к кластеру
        1. Создадим объект `ServiceAccount` `dave`, который будет использоваться для аутентификации.

3. Выполнения задачи 1:
    Применим созданные манифесты:

    ```bash
    kubectl apply -f kubernetes-security/task01/01-sa-bob.yaml
    serviceaccount/bob created

    kubectl apply -f kubernetes-security/task01/02-cluster-role-binding-bob.yaml
    clusterrolebinding.rbac.authorization.k8s.io/bob-admin created

    kubectl apply -f kubernetes-security/task01/03-sa-dave.yaml
    serviceaccount/dave created
    ```

    Проверим, что `ServiceAccount` `bob` имеет привелегии администратора, а `dave` - нет. Используем для этого утилиту `rakkes`:

    ```bash
    rakkess --sa default:bob
    NAME                                                          LIST  CREATE  UPDATE  DELETE
    apiservices.apiregistration.k8s.io                            ✖     ✖       ✖       ✖
    bindings                                                            ✖
    certificatesigningrequests.certificates.k8s.io                ✖     ✖       ✖       ✖
    clusterrolebindings.rbac.authorization.k8s.io                 ✖     ✖       ✖       ✖
    clusterroles.rbac.authorization.k8s.io                        ✖     ✖       ✖       ✖
    componentstatuses                                             ✖
    configmaps                                                    ✔     ✔       ✔       ✔
    controllerrevisions.apps                                      ✔     ✖       ✖       ✖
    cronjobs.batch                                                ✔     ✔       ✔       ✔
    csidrivers.storage.k8s.io                                     ✖     ✖       ✖       ✖
    csinodes.storage.k8s.io                                       ✖     ✖       ✖       ✖
    customresourcedefinitions.apiextensions.k8s.io                ✖     ✖       ✖       ✖
    daemonsets.apps                                               ✔     ✔       ✔       ✔
    deployments.apps                                              ✔     ✔       ✔       ✔
    endpoints                                                     ✔     ✔       ✔       ✔
    events                                                        ✔     ✖       ✖       ✖
    events.events.k8s.io                                          ✖     ✖       ✖       ✖
    horizontalpodautoscalers.autoscaling                          ✔     ✔       ✔       ✔
    ingresses.extensions                                          ✔     ✔       ✔       ✔
    ingresses.networking.k8s.io                                   ✔     ✔       ✔       ✔
    jobs.batch                                                    ✔     ✔       ✔       ✔
    leases.coordination.k8s.io                                    ✖     ✖       ✖       ✖
    limitranges                                                   ✔     ✖       ✖       ✖
    localsubjectaccessreviews.authorization.k8s.io                      ✔
    mutatingwebhookconfigurations.admissionregistration.k8s.io    ✖     ✖       ✖       ✖
    namespaces                                                    ✔     ✖       ✖       ✖
    networkpolicies.networking.k8s.io                             ✔     ✔       ✔       ✔
    nodes                                                         ✖     ✖       ✖       ✖
    persistentvolumeclaims                                        ✔     ✔       ✔       ✔
    persistentvolumes                                             ✖     ✖       ✖       ✖
    poddisruptionbudgets.policy                                   ✔     ✔       ✔       ✔
    pods                                                          ✔     ✔       ✔       ✔
    podsecuritypolicies.policy                                    ✖     ✖       ✖       ✖
    podtemplates                                                  ✖     ✖       ✖       ✖
    priorityclasses.scheduling.k8s.io                             ✖     ✖       ✖       ✖
    replicasets.apps                                              ✔     ✔       ✔       ✔
    replicationcontrollers                                        ✔     ✔       ✔       ✔
    resourcequotas                                                ✔     ✖       ✖       ✖
    rolebindings.rbac.authorization.k8s.io                        ✔     ✔       ✔       ✔
    roles.rbac.authorization.k8s.io                               ✔     ✔       ✔       ✔
    runtimeclasses.node.k8s.io                                    ✖     ✖       ✖       ✖
    secrets                                                       ✔     ✔       ✔       ✔
    selfsubjectaccessreviews.authorization.k8s.io                       ✔
    selfsubjectrulesreviews.authorization.k8s.io                        ✔
    serviceaccounts                                               ✔     ✔       ✔       ✔
    services                                                      ✔     ✔       ✔       ✔
    statefulsets.apps                                             ✔     ✔       ✔       ✔
    storageclasses.storage.k8s.io                                 ✖     ✖       ✖       ✖
    subjectaccessreviews.authorization.k8s.io                           ✖
    tokenreviews.authentication.k8s.io                                  ✖
    validatingwebhookconfigurations.admissionregistration.k8s.io  ✖     ✖       ✖       ✖
    volumeattachments.storage.k8s.io                              ✖     ✖       ✖       ✖
    No namespace given, this implies cluster scope (try -n if this is not intended)

    rakkess --sa default:dave
    NAME                                                          LIST  CREATE  UPDATE  DELETE
    apiservices.apiregistration.k8s.io                            ✖     ✖       ✖       ✖
    bindings                                                            ✖
    certificatesigningrequests.certificates.k8s.io                ✖     ✖       ✖       ✖
    clusterrolebindings.rbac.authorization.k8s.io                 ✖     ✖       ✖       ✖
    clusterroles.rbac.authorization.k8s.io                        ✖     ✖       ✖       ✖
    componentstatuses                                             ✖
    configmaps                                                    ✖     ✖       ✖       ✖
    controllerrevisions.apps                                      ✖     ✖       ✖       ✖
    cronjobs.batch                                                ✖     ✖       ✖       ✖
    csidrivers.storage.k8s.io                                     ✖     ✖       ✖       ✖
    csinodes.storage.k8s.io                                       ✖     ✖       ✖       ✖
    customresourcedefinitions.apiextensions.k8s.io                ✖     ✖       ✖       ✖
    daemonsets.apps                                               ✖     ✖       ✖       ✖
    deployments.apps                                              ✖     ✖       ✖       ✖
    endpoints                                                     ✖     ✖       ✖       ✖
    events                                                        ✖     ✖       ✖       ✖
    events.events.k8s.io                                          ✖     ✖       ✖       ✖
    horizontalpodautoscalers.autoscaling                          ✖     ✖       ✖       ✖
    ingresses.extensions                                          ✖     ✖       ✖       ✖
    ingresses.networking.k8s.io                                   ✖     ✖       ✖       ✖
    jobs.batch                                                    ✖     ✖       ✖       ✖
    leases.coordination.k8s.io                                    ✖     ✖       ✖       ✖
    limitranges                                                   ✖     ✖       ✖       ✖
    localsubjectaccessreviews.authorization.k8s.io                      ✖
    mutatingwebhookconfigurations.admissionregistration.k8s.io    ✖     ✖       ✖       ✖
    namespaces                                                    ✖     ✖       ✖       ✖
    networkpolicies.networking.k8s.io                             ✖     ✖       ✖       ✖
    nodes                                                         ✖     ✖       ✖       ✖
    persistentvolumeclaims                                        ✖     ✖       ✖       ✖
    persistentvolumes                                             ✖     ✖       ✖       ✖
    poddisruptionbudgets.policy                                   ✖     ✖       ✖       ✖
    pods                                                          ✖     ✖       ✖       ✖
    podsecuritypolicies.policy                                    ✖     ✖       ✖       ✖
    podtemplates                                                  ✖     ✖       ✖       ✖
    priorityclasses.scheduling.k8s.io                             ✖     ✖       ✖       ✖
    replicasets.apps                                              ✖     ✖       ✖       ✖
    replicationcontrollers                                        ✖     ✖       ✖       ✖
    resourcequotas                                                ✖     ✖       ✖       ✖
    rolebindings.rbac.authorization.k8s.io                        ✖     ✖       ✖       ✖
    roles.rbac.authorization.k8s.io                               ✖     ✖       ✖       ✖
    runtimeclasses.node.k8s.io                                    ✖     ✖       ✖       ✖
    secrets                                                       ✖     ✖       ✖       ✖
    selfsubjectaccessreviews.authorization.k8s.io                       ✔
    selfsubjectrulesreviews.authorization.k8s.io                        ✔
    serviceaccounts                                               ✖     ✖       ✖       ✖
    services                                                      ✖     ✖       ✖       ✖
    statefulsets.apps                                             ✖     ✖       ✖       ✖
    storageclasses.storage.k8s.io                                 ✖     ✖       ✖       ✖
    subjectaccessreviews.authorization.k8s.io                           ✖
    tokenreviews.authentication.k8s.io                                  ✖
    validatingwebhookconfigurations.admissionregistration.k8s.io  ✖     ✖       ✖       ✖
    volumeattachments.storage.k8s.io                              ✖     ✖       ✖       ✖
    No namespace given, this implies cluster scope (try -n if this is not intended)
    ```

    Видно, что права для сервис-аккаунта `dave` не позволяют ему сделать что-либо.

4. Задача 2.

    * Создать Namespace prometheus
    Мы используем манифест для создания `Namespace` `prometheus`
    * Создать Service Account carol в этом Namespace
    Мы используем манифест для создания сервис аккаунта `carol` указав при этом имя `Namespace` `prometheus`
    * Дать всем Service Account в Namespace prometheus возможность делать `get`, `list`, `watch` в отношении Pods всего кластера
    Создадим два манифеста: один для создания `ClusterRole`, и один для `ClusterRoleBinding`

5. Выполнения задачи 2:

    Применим созданные манифесты:

    ```bash
    kubectl apply -f kubernetes-security/task02/01-namespace-prometheus.yaml
    namespace/prometheus created

    kubectl apply -f kubernetes-security/task02/02-sa-carol.yaml
    serviceaccount/carol created

    kubectl apply -f kubernetes-security/task02/03-cluster-role-pod-view.yaml
    clusterrole.rbac.authorization.k8s.io/pod-view created

    kubectl apply -f kubernetes-security/task02/04-cluster-role-binding-carol.yaml
    clusterrolebinding.rbac.authorization.k8s.io/pod-view created
    ```

    Проверим что аккаунт `carol` имеет доступ к `pods` внутри всего кластера:

    ```bash
    kubectl auth can-i list pods --as system:serviceaccount:prometheus:carol
    yes
    ```

6. Задача 3:

    * Создать Namespace `dev`
    * Создать Service Account `jane` в Namespace `dev`
    * Дать `jane` роль `admin` в рамках Namespace `dev`
    * Создать Service Account `ken` в Namespace `dev`
    * Дать `ken` роль `view` в рамках Namespace `dev`

    Создадим и используем манифесты для выполнения задачи.

7. Выполнение задачи 3:

    Применим созданные манифесты:

    ```bash
    kubectl apply -f kubernetes-security/task03/
    namespace/dev created
    serviceaccount/jane created
    serviceaccount/ken created
    rolebinding.rbac.authorization.k8s.io/dev-admin created
    rolebinding.rbac.authorization.k8s.io/dev-view created
    ```

    Проверим что может каждый из аккаунтов, например так:

    ```bash
    kubectl auth can-i create deployments --as system:serviceaccount:dev:jane -n dev
    yes
    kubectl auth can-i get deployments --as system:serviceaccount:dev:ken -n dev
    yes
    ```

[Назад к содержанию](../README.md)
