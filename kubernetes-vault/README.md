# Домашнее задание 10

[Содержание](../README.md)

*NB: Использован дистрибутив `Ubuntu 18.04` с предустановленным `kind` и `VirtualBox` ПО.*

1. Поднимем кластер `kind`

    ```bash
    cd kubernetes-vault
    kind create cluster --config cluster.yml
    ```

2. Инсталляция hashicorp vault HA в k8s

    Клонируем репозиторий helm chart consul и запустим его:

    ```bash
    git clone https://github.com/hashicorp/consul-helm.git
    helm install consul consul-helm
    NAME: consul
    LAST DEPLOYED: Mon Feb 10 22:07:01 2020
    NAMESPACE: default
    STATUS: deployed
    REVISION: 1
    NOTES:
    Thank you for installing HashiCorp Consul!

    Now that you have deployed Consul, you should look over the docs on using
    Consul with Kubernetes available here:

    https://www.consul.io/docs/platform/k8s/index.html


    Your release is named consul. To learn more about the release, try:

    $ helm status consul
    $ helm get consul

    ```

    Клонируем репозиторий helm chart vault

    ```bash
    git clone https://github.com/hashicorp/vault-helm.git
    ```

    Зададим переменные в `kubernetes-vault/vault/values.yml` и примени чарт:

    ```bash
    helm install vault vault-helm -f kubernetes-vault/vault/values.yml
    NAME: vault
    LAST DEPLOYED: Mon Feb 10 22:25:01 2020
    NAMESPACE: default
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    Thank you for installing HashiCorp Vault!

    Now that you have deployed Vault, you should look over the docs on using
    Vault with Kubernetes available here:

    https://www.vaultproject.io/docs/


    Your release is named vault. To learn more about the release, try:

    $ helm status vault
    $ helm get vault

    ```

3. Проведём инициализацию нашего vault:

    ```bash
    kubectl exec -it vault-0 -- vault operator init --key-shares=1 --key-threshold=1
    Unseal Key 1: ZcjqlYKKvbnZk9JVYD+iRw59uOhZJqM6KFBDI1ZRJbA=

    Initial Root Token: s.Oldlfv9RSLeTesH9ciypFQHZ

    Vault initialized with 1 key shares and a key threshold of 1. Please securely
    distribute the key shares printed above. When the Vault is re-sealed,
    restarted, or stopped, you must supply at least 1 of these keys to unseal it
    before it can start servicing requests.

    Vault does not store the generated master key. Without at least 1 key to
    reconstruct the master key, Vault will remain permanently sealed!

    It is possible to generate new unseal keys, provided you have a quorum of
    existing unseal keys shares. See "vault operator rekey" for more information.
    ```

    **поэкспериментируйте с разными значениями `--key-shares` и `--key-threshold`**

    Когда сервер Vault запущен, он запускается в запечатанном состоянии. В этом состоянии Vault настроен на то, чтобы знать, где и как получить доступ к физическому хранилищу, но не знает, как его расшифровать.

    unseal - это процесс создания мастер-ключа, необходимого для считывания ключа дешифрования для дешифрования данных, позволяющего получить доступ к хранилищу.

    Данные, хранящиеся в Vault, хранятся в зашифрованном виде. Vault нужен ключ шифрования для расшифровки данных. Ключ шифрования также хранится вместе с данными, но шифруется другим ключом шифрования, известным как Master key, который нигде не хранится.

    Поэтому для расшифровки данных Vault должен расшифровать ключ шифрования, для которого требуется Master key. Unseal - это процесс восстановления этого мастер-ключа.

    Вместо того, чтобы распространять этот Master key в качестве единого ключа, Vault использует алгоритм, для разделения ключа на shardes. Для восстановления Master key требуется определенное количество шардов.

    `--key-shares` - количество шард `--key-threshold` - количество шард необходимых для восстанавления мастер ключа (читай распечатывания хранилища). Соответственно главное условие при "распечатывании" хранилица `key-shares>=key-threshold`

4. Выведем статус Vault:

    ```bash
    kubectl exec -it vault-0 -- vault status
    Key                Value
    ---                -----
    Seal Type          shamir
    Initialized        true
    Sealed             true
    Total Shares       1
    Threshold          1
    Unseal Progress    0/1
    Unseal Nonce       n/a
    Version            1.3.1
    HA Enabled         true
    ```

    Видим, что хранилице инициализировано.

5. Распечатаем хранилища:

    ```bash
    kubectl exec -it vault-0 -- vault operator unseal 'ZcjqlYKKvbnZk9JVYD+iRw59uOhZJqM6KFBDI1ZRJbA='
    Key                    Value
    ---                    -----
    Seal Type              shamir
    Initialized            true
    Sealed                 false
    Total Shares           1
    Threshold              1
    Version                1.3.1
    Cluster Name           vault-cluster-b235a4c2
    Cluster ID             721389d8-7aba-8644-d8d0-45f5da9f7c9a
    HA Enabled             true
    HA Cluster             n/a
    HA Mode                standby
    Active Node Address    <none>

    kubectl exec -it vault-1 -- vault operator unseal 'ZcjqlYKKvbnZk9JVYD+iRw59uOhZJqM6KFBDI1ZRJbA='
    Key                    Value
    ---                    -----
    Seal Type              shamir
    Initialized            true
    Sealed                 false
    Total Shares           1
    Threshold              1
    Version                1.3.1
    Cluster Name           vault-cluster-b235a4c2
    Cluster ID             721389d8-7aba-8644-d8d0-45f5da9f7c9a
    HA Enabled             true
    HA Cluster             https://10.244.3.4:8201
    HA Mode                standby
    Active Node Address    http://10.244.3.4:8200

    kubectl exec -it vault-2 -- vault operator unseal 'ZcjqlYKKvbnZk9JVYD+iRw59uOhZJqM6KFBDI1ZRJbA='
    Key                    Value
    ---                    -----
    Seal Type              shamir
    Initialized            true
    Sealed                 false
    Total Shares           1
    Threshold              1
    Version                1.3.1
    Cluster Name           vault-cluster-b235a4c2
    Cluster ID             721389d8-7aba-8644-d8d0-45f5da9f7c9a
    HA Enabled             true
    HA Cluster             https://10.244.3.4:8201
    HA Mode                standby
    Active Node Address    http://10.244.3.4:8200
    ```

6. Посмотрим список доступных авторизаций:

    ```bash
    kubectl exec -it vault-0 -- vault auth list
    Error listing enabled authentications: Error making API request.

    URL: GET http://127.0.0.1:8200/v1/sys/auth
    Code: 400. Errors:

    * missing client token
    command terminated with exit code 2
    ```

    Видим, что не можем добраться до списка из-за отсутствующего токена для доступа к API под пользователем vault, ибо мы не залогинены.

7. Залогинимся в vault (у нас есть root token)

    ```bash
    kubectl exec -it vault-0 -- vault login
    Token (will be hidden): 
    Success! You are now authenticated. The token information displayed below
    is already stored in the token helper. You do NOT need to run "vault login"
    again. Future Vault requests will automatically use this token.

    Key                  Value
    ---                  -----
    token                s.Oldlfv9RSLeTesH9ciypFQHZ
    token_accessor       p1Goswabcmdlvk9w9aDLRZ1M
    token_duration       ∞
    token_renewable      false
    token_policies       ["root"]
    identity_policies    []
    policies             ["root"]
    ```

    Повторно запросим список доступных авторизаций:

    ```bash
    kubectl exec -it vault-0 -- vault auth list
    Path      Type     Accessor               Description
    ----      ----     --------               -----------
    token/    token    auth_token_8fb86105    token based credentials
    ```

    Получилось.

8. Заведем секреты:

    ```bash
    kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
    kubectl exec -it vault-0 -- vault secrets list --detailed
    kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
    kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
    ```

    прочитаем их парой разных способов:

    ```bash
    kubectl exec -it vault-0 -- vault read otus/otus-ro/config
    Key                 Value
    ---                 -----
    refresh_interval    768h
    password            asajkjkahs
    username            otus
    ```

    ```bash
     kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config
    ====== Data ======
    Key         Value
    ---         -----
    password    asajkjkahs
    username    otus
    ```

9. Включим авторизацию черерз k8s

    ```bash
    kubectl exec -it vault-0 -- vault auth enable kubernetes
    ```

    Посмотрим, что есть доступна новый метод авторизации:

    ```bash
    kubectl exec -it vault-0 -- vault auth list
    Path           Type          Accessor                    Description
    ----           ----          --------                    -----------
    kubernetes/    kubernetes    auth_kubernetes_34c79702    n/a
    token/         token         auth_token_8fb86105         token based credentials
    ```

10. Создадим Service Account vault-auth и применим ClusterRoleBinding:

    ```bash
    kubectl create serviceaccount vault-auth
    kubectl apply --filename vault-auth-service-account.yml
    ```

11. Подготовим переменные для записи в конфиг кубер авторизации:

    ```bash
    export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
    export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
    export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
    export K8S_HOST=$(more ~/.kube/config | grep server |awk '/http/ {print $NF}')
    ```

    Фокус с sed:

    ```bash
    ### alternative way
    export K8S_HOST=$(kubectl cluster-info | grep 'Kubernetes master' | awk '/https/ {print $NF}' | sed 's/\x1b\[[0-9;]*m//g' )
    ```

    `sed 's/\x1b\[[0-9;]*m//g'` убирает цветовые коды.

    Так же стоит отметить, что при сборке на локальном кластере kind пришлось задать адрес API сервера, как ClusterIP:

    ```bash
    export K8S_HOST='https://10.96.0.1:443'
    ```

12. Запишем конфиг в vault:

    ```bash
    kubectl exec -it vault-0 -- vault write auth/kubernetes/config \
    token_reviewer_jwt="$SA_JWT_TOKEN" \
    kubernetes_host="$K8S_HOST" \
    kubernetes_ca_cert="$SA_CA_CRT"

    Success! Data written to: auth/kubernetes/config
    ```

13. Создадим политику и роль в vault:

    ```bash
    kubectl cp otus-policy.hcl vault-0:./vault
    kubectl exec -it vault-0 -- vault policy write otus-policy /vault/otus-policy.hcl
    kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
    bound_service_account_names=vault-auth \
    bound_service_account_namespaces=default policies=otus-policy ttl=24h
    ```

    *NB: В ДЗ указан путь для копирования в "/" но у нас нет прав записи в корень.*

14. Проверим как работает авторизация:

    Создадим под с привязанным сервис аккаунтом и установим туда curl и jq

    ```bash
    kubectl run --generator=run-pod/v1 tmp --rm -i --tty --serviceaccount=vault-auth --image alpine:3.7
    ```

    ```bash
    apk add curl jq
    ```

    Залогинимся и получим клиентский токен:

    ```bash
    VAULT_ADDR=http://vault:8200
    KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
    curl --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq
    TOKEN=$(curl -k -s --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{print $2}')
    ```

15. Прочитаем Прочитаем записанные ранее секреты и попробуем их обновить:

    Чтение:

    ```bash
    curl --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-ro/config
    curl --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config
    ```

    Запись:

    ```bash
    curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-ro/config
    curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config
    curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config1
    ```

16. Разберемся с ошибками при записи:

    - **Почему мы смогли записать otus-rw/config1 но не смогли otus-rw/config:**

        У нас есть `capabilities` "create", "read", "list". "Create" - позвооляет создавать но не обнавлять данные по существующему пути. Поэтому мы смогли записать (по новому пути `/v1/otus/otus-rw/config1`), но не добавить к сеществующим. Для этого необъходимо добавить `capabilities` "update". [документация](https://www.vaultproject.io/docs/concepts/policies/#inlinecode-update)

17. Use case использования авторизации через кубер

    Авторизуемся через vault-agent и получим клиентский токен.
    Через consul-template достанем секрет и положим его в nginx
    Итог - nginx получил секрет из волта, не зная ничего про волт

18. Заберем репозиторий с примерами:

    ```bash
    git clone https://github.com/hashicorp/vault-guides.git
    cd vault-guides/identity/vault-agent-k8s-demo
    ```

19. Потюним следующие файлы: `consul-template-config.hcl`, `vault-agent-config.hcl` и `example-k8s-spec.yml`. В них укажем правильные имена ролей, пути к секретам и адрес vault. Изменённые файлы находятся в каталоге `kubernetes-vault/vault-guides`.

20. Запустим пример, не забудем при этом перезаписать секреты после предыдущих эксперементов:

    ```bash
    kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
    kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
    # Create a ConfigMap, example-vault-agent-config
    kubectl create configmap example-vault-agent-config --from-file=./configs-k8s/
    # View the created ConfigMap
    kubectl get configmap example-vault-agent-config -o yaml
    # Finally, create vault-agent-example Pod
    kubectl apply -f example-k8s-spec.yml --record
    ```

21. Логинимся в nginx контейнер и достаём `index.html`. Файл нахотидся в том же кателоге, что и изменённые файлы примера `kubernetes-vault/vault-guides`.

    ```bash
    kubectl exec -ti vault-agent-example -- sh
    Defaulting container name to consul-template.
    Use 'kubectl describe pod/vault-agent-example -n default' to see all of the containers in this pod.
    / $ cat /etc/secrets/index.html
    <html>
    <body>
    <p>Some secrets:</p>
    <ul>
    <li><pre>username: otus</pre></li>
    <li><pre>password: asajkjkahs</pre></li>
    </ul>

    </body>
    </html>
    ```

22. Создадим CA на базе vault:

    ```bash
    kubectl exec -it vault-0 -- vault secrets enable pki
    Success! Enabled the pki secrets engine at: pki/

    kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
    Success! Tuned the secrets engine at: pki/

    kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal \
    common_name="example.com" \
    ttl=87600h > CA_cert.crt
    ```

23. Пропишем URL для CA и отозванных сертификатов:

    ```bash
    kubectl exec -it vault-0 -- vault write pki/config/urls \
    issuing_certificates="http://vault:8200/v1/pki/ca" \
    crl_distribution_points="http://vault:8200/v1/pki/crl"

    Success! Data written to: pki/config/urls
    ```

24. Создадим промежуточный сертификат:

    ```bash
    kubectl exec -it vault-0 -- vault secrets enable -path=pki_int pki
    Success! Enabled the pki secrets engine at: pki_int/

    kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=43800h pki_int
    Success! Tuned the secrets engine at: pki_int/

    kubectl exec -it vault-0 -- vault write -format=json pki_int/intermediate/generate/internal \
    common_name="example.com Intermediate Authority" \
    | jq -r '.data.csr' > pki_intermediate.csr
    ```

25. Пропишем промежуточный сертификат в vault:

    ```bash
    kubectl cp pki_intermediate.csr vault-0:vault
    kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate \
    csr=@vault/pki_intermediate.csr \
    format=pem_bundle ttl="43800h" \
    | jq -r '.data.certificate' > intermediate.cert.pem

    kubectl cp intermediate.cert.pem vault-0:vault
    kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed \
    certificate==@vault/intermediate.cert.pem
    ```

26. Создадим и отзовем новые сертификаты:

    Создадим роль для выдачи сертификатов:

    ```bash
    kubectl exec -it vault-0 -- vault write pki_int/roles/example-dot-com \
        allowed_domains="example.com" \
        allow_subdomains=true \
        max_ttl="24h"
    ```

    *NB. В ДЗ не указана аргумент `allow_subdomains=true`*

    Создадим и отзовем сертификат:

    ```bash
    kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-com common_name="test.example.com" ttl="24h"
    Key                 Value
    ---                 -----
    ca_chain            [-----BEGIN CERTIFICATE-----
    MIIDnjCCAoagAwIBAgIUEEqzbiOHx6Xucc0f6XOW9HKUU1AwDQYJKoZIhvcNAQEL
    BQAwFjEUMBIGA1UEAxMLZXhhbXBsZS5jb20wHhcNMjAwMjI3MjExNzI3WhcNMjUw
    MjI1MjExNzU3WjAtMSswKQYDVQQDEyJleGFtcGxlLmNvbSBJbnRlcm1lZGlhdGUg
    QXV0aG9yaXR5MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArEe2Ugt8
    6MKhVDLJFaIF0OBM4j+KILswar6s7aJ738elJV8TSGK65ZqMA2yG5RlUm30fqVqx
    I+wRgpelnmjJCEW3sE+ynJj6VWuDj9dnZzhEb/6mkbwUWBUb7/i8The3y9J3SYBP
    Gr6ceP+BPS+1iPuO1T/6SrAKCnBd/3CrUPvwe8KrYouqkge1slmo9lJUwRasmVTd
    nqzk3cAAJs3bTl/KQwfMTStvYsYzPGa4mejcdta5EXWWIlTXPdAQ4hLyEccPxETW
    Hy748RNfTnyCsGxcRHGVJZUxcCawOwmywA0wTNMhC4B5vvXEElJPYjPonKmnAv7R
    m/jM2PdMm3FcwwIDAQABo4HMMIHJMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8E
    BTADAQH/MB0GA1UdDgQWBBS+LuYkgSQqk7sWv0sYy5BCUbA89DAfBgNVHSMEGDAW
    gBRomVQqIZkaRihcIYXfWh3SecjQJDA3BggrBgEFBQcBAQQrMCkwJwYIKwYBBQUH
    MAKGG2h0dHA6Ly92YXVsdDo4MjAwL3YxL3BraS9jYTAtBgNVHR8EJjAkMCKgIKAe
    hhxodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY3JsMA0GCSqGSIb3DQEBCwUAA4IB
    AQA5xQQSfBrT25OhHAsM+AulBN+9ZwAWmhfdylzE8oj0Ap7VcFnM/4klz3aaplF2
    VKj06IALYNQjGTFo/fZ0+t+74LRyrba9DmJScG73+FU0T2tXmEgFP2Gcw1bi0NyT
    WRzyscueef0FsO/Dd/O/bfFLYBMkCCy9WFVRoC2kND1smO4mOgnYH2XEX19wyYKN
    rCblORs76gIzy8eGy+Ll0vHAlTPD8ZyopkBgeq4Q0amXtAWPx2zjYbzoNVVfC/GL
    LwRSQ02z9IeA0EQl1PuCPRib4KtB6RRa+uBrRYGj/b3e+tMh/nGOiAlOl+HT/DVd
    /TqeptUIdO2rSCjci3kW7su/
    -----END CERTIFICATE-----]
    certificate         -----BEGIN CERTIFICATE-----
    MIIDZjCCAk6gAwIBAgIUF+dANJyN11dFsVmCDsFAx29zMNowDQYJKoZIhvcNAQEL
    BQAwLTErMCkGA1UEAxMiZXhhbXBsZS5jb20gSW50ZXJtZWRpYXRlIEF1dGhvcml0
    eTAeFw0yMDAyMjcyMTIyMzlaFw0yMDAyMjgyMTIzMDhaMBsxGTAXBgNVBAMTEHRl
    c3QuZXhhbXBsZS5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDM
    Jp2zA/eiVIdmRI2MGXqyOvVUi2ya4UdZ5tQuK+jVxJW+D468xX4NqtUn5GYc1Sdt
    km7LnbLT8Jkj85NCptkGRnExg6YYHdqpbXY16SMh4tp89Z1S7YOdD7ZRM1tNTvko
    0zarDjD5Jr2cruGNbWDLHN3pS9u3/T4haohAiJJeYM36ezoXlF0PoZrRepTx1nDB
    iMwmx8z7bxqgMfAlgdi2K6KlgZCzxpZEC4uEHe32uv+dsHy8HLPzyOJh80sAcX3m
    SQmXwVqAJ31r73rgXkGbheAuoeIP6W/NN90KBUsetoKYRqDZ4ppWpx5GMULDzoMl
    sx0vJH2sp7yCvImmS02tAgMBAAGjgY8wgYwwDgYDVR0PAQH/BAQDAgOoMB0GA1Ud
    JQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNVHQ4EFgQUBSH1rISKfvfkxrAQ
    wx2uUi3ibt4wHwYDVR0jBBgwFoAUvi7mJIEkKpO7Fr9LGMuQQlGwPPQwGwYDVR0R
    BBQwEoIQdGVzdC5leGFtcGxlLmNvbTANBgkqhkiG9w0BAQsFAAOCAQEACqe0cDQ0
    Kglx5CyPGpiKZ27gbNEbMAgX8jPMkqHDC5gZXFyyDLtUIX65Y8tWSX5eg81DKauz
    yAe2C/FXxKIL/ghCMQcFj2X02zsOiogwR4XDCcDj7lyqgpwYyGth1N1PtFFp8x29
    n+eVjMXyr34EIhp/UATKpQlupHZEnSnmVSPBuak8U3HFVQsinuPCAlfbT8mETlOk
    Q0jv5Mpt7te1TSpAbWdG8eestnXyfs4W1kdshcubHzFpGgEy96vNVHfvLn2zYk1y
    9fhvfuHCW6eePocV3YV41zo8sZUTRxCIvUwlTdd59sRzs52SJpD668wD/hQi8xCt
    cOB5VRog4lC9Dg==
    -----END CERTIFICATE-----
    expiration          1582924988
    issuing_ca          -----BEGIN CERTIFICATE-----
    MIIDnjCCAoagAwIBAgIUEEqzbiOHx6Xucc0f6XOW9HKUU1AwDQYJKoZIhvcNAQEL
    BQAwFjEUMBIGA1UEAxMLZXhhbXBsZS5jb20wHhcNMjAwMjI3MjExNzI3WhcNMjUw
    MjI1MjExNzU3WjAtMSswKQYDVQQDEyJleGFtcGxlLmNvbSBJbnRlcm1lZGlhdGUg
    QXV0aG9yaXR5MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArEe2Ugt8
    6MKhVDLJFaIF0OBM4j+KILswar6s7aJ738elJV8TSGK65ZqMA2yG5RlUm30fqVqx
    I+wRgpelnmjJCEW3sE+ynJj6VWuDj9dnZzhEb/6mkbwUWBUb7/i8The3y9J3SYBP
    Gr6ceP+BPS+1iPuO1T/6SrAKCnBd/3CrUPvwe8KrYouqkge1slmo9lJUwRasmVTd
    nqzk3cAAJs3bTl/KQwfMTStvYsYzPGa4mejcdta5EXWWIlTXPdAQ4hLyEccPxETW
    Hy748RNfTnyCsGxcRHGVJZUxcCawOwmywA0wTNMhC4B5vvXEElJPYjPonKmnAv7R
    m/jM2PdMm3FcwwIDAQABo4HMMIHJMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8E
    BTADAQH/MB0GA1UdDgQWBBS+LuYkgSQqk7sWv0sYy5BCUbA89DAfBgNVHSMEGDAW
    gBRomVQqIZkaRihcIYXfWh3SecjQJDA3BggrBgEFBQcBAQQrMCkwJwYIKwYBBQUH
    MAKGG2h0dHA6Ly92YXVsdDo4MjAwL3YxL3BraS9jYTAtBgNVHR8EJjAkMCKgIKAe
    hhxodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY3JsMA0GCSqGSIb3DQEBCwUAA4IB
    AQA5xQQSfBrT25OhHAsM+AulBN+9ZwAWmhfdylzE8oj0Ap7VcFnM/4klz3aaplF2
    VKj06IALYNQjGTFo/fZ0+t+74LRyrba9DmJScG73+FU0T2tXmEgFP2Gcw1bi0NyT
    WRzyscueef0FsO/Dd/O/bfFLYBMkCCy9WFVRoC2kND1smO4mOgnYH2XEX19wyYKN
    rCblORs76gIzy8eGy+Ll0vHAlTPD8ZyopkBgeq4Q0amXtAWPx2zjYbzoNVVfC/GL
    LwRSQ02z9IeA0EQl1PuCPRib4KtB6RRa+uBrRYGj/b3e+tMh/nGOiAlOl+HT/DVd
    /TqeptUIdO2rSCjci3kW7su/
    -----END CERTIFICATE-----
    private_key         -----BEGIN RSA PRIVATE KEY-----
    MIIEpAIBAAKCAQEAzCadswP3olSHZkSNjBl6sjr1VItsmuFHWebULivo1cSVvg+O
    vMV+DarVJ+RmHNUnbZJuy52y0/CZI/OTQqbZBkZxMYOmGB3aqW12NekjIeLafPWd
    Uu2DnQ+2UTNbTU75KNM2qw4w+Sa9nK7hjW1gyxzd6Uvbt/0+IWqIQIiSXmDN+ns6
    F5RdD6Ga0XqU8dZwwYjMJsfM+28aoDHwJYHYtiuipYGQs8aWRAuLhB3t9rr/nbB8
    vByz88jiYfNLAHF95kkJl8FagCd9a+964F5Bm4XgLqHiD+lvzTfdCgVLHraCmEag
    2eKaVqceRjFCw86DJbMdLyR9rKe8gryJpktNrQIDAQABAoIBAQCP6XzrsBVGKp5U
    Omkp5OA4ehVtZufFep9owa67aZq17uG8XI07h2Dn05B1ka1mD+C+fiZ6hQ2GGCps
    TI13w9Rjdw7eX7abc5gsLYzSTinE/n0U77PavLI16tiT/0cShWRhIht8lAFz8Zpi
    tGkt4HgGVrAcgKw/1FaTCd1I2L2Npx6r3h2TK6WAchprMtB8V4grxBp2TQWPHvco
    W4HeLYluYICx1qid89SJhnDfpqyXRpLuSqsC30CIv0wIngpOMmFqBUn8BV1345hs
    R+MAICyLfIj4anup8vUnqwiIAPBIRL9UFRNLhroqSVI4HQ9Mibj/HiUiBc74jVs5
    bUciCL7hAoGBANHKUSsnU3fFPVCwKhm0EpprkEX1pjxfq+Lee13hG+j1XfP4PQel
    Y0prP1aWdX8QkLx+ywdGFzYmZ383fTcgEwHF8eolk2AhPcbzGaaHq+12JJNnJUhP
    KXqrhdm2/KgU/M2r8LRUbeOlQK2XkuaCT0XkVPdwcEq2/g9lt4y1wDaFAoGBAPke
    TO1NMhGxLEeHlRKcUK6JdWJBNB4kY+EOe8LIU9R1GtgB0GesH1ue7jpQXd0Ca0KF
    4fGqQHQcUmqH2PHpr4cZ77CekCNyVECpCAPVunFiLZ07nLHuukb2FbAT+MVMYYJL
    NH89NBflvXUDUKL24OUtmfJ59aQmDXyDJbvUCMcJAoGAMqNeIkd0y0Utvqs3Dks7
    7lAmW+ymeo4xRCqlpoxumzWWvwvdV1ohdFYczL62j7wk44rLYO8XLTfp5Xg0Xjj8
    vYHVGcqGHz8G1V3ahCrdYg0RWQ8dna2V+okqXtnfdIbUWqS1DiIPAFLkIMKkb8Vm
    cx1hMPTP9gjjnD3WJz27rq0CgYAs7w83Gl52nHt9J3J3GeTfpoGayGILMcsmNAOU
    vaeJQdomriUWHhDF6OPVdtuHWsFYDWgUu/3GM7mV54z1DY6QktgOBnu/OQcDZrnA
    X1Oy0d+iZbc8zO+ijw6YZPHRPJa19rSwYqy7xr+mlIN98YPdMp17BA6PniF+nPU4
    bOVsaQKBgQCZ7BGlaySfotgenDP9rYo2TJj4tUKmXaSJOpomi4BFDPOrIG6GI+/9
    58l8jPNHwdNzapLOrAX/pk7uyOPoKHY7ue7QPRTCR9sGlLgIQqAj9bDz79VRcLRH
    c7TDeoz6K7E3m3GYdl9SVOO9eDT0bM+g3eelOBgx83yiHeD0Da3D8A==
    -----END RSA PRIVATE KEY-----
    private_key_type    rsa
    serial_number       17:e7:40:34:9c:8d:d7:57:45:b1:59:82:0e:c1:40:c7:6f:73:30:da

    kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="17:e7:40:34:9c:8d:d7:57:45:b1:59:82:0e:c1:40:c7:6f:73:30:da"
    Key                        Value
    ---                        -----
    revocation_time            1582838788
    revocation_time_rfc3339    2020-02-27T21:26:28.248084501Z
    ```

27. включить TLS:
    Реализовать доступ к vault через https с CA из kubernetes

    Включаем подержку TLS:

    Измененный файл с настройками vault - `vault\vault-tls.yml`

    Генерируем сертификаты подписанные CA kubernetes (*NB: обратить внимание на `CN` и `alt_names`*) по которым vault  сможет общаться с "миром":

    ```bash
    cd certs
    openssl req -new -config tls.cnf -keyout tls.key -out tls.csr
    cat <<EOF | kubectl apply -f -
    apiVersion: certificates.k8s.io/v1beta1
    kind: CertificateSigningRequest
    metadata:
    name: vault-req
    spec:
    request: $(cat server.csr | base64 | tr -d '\n')
    usages:
    - digital signature
    - key encipherment
    - server auth
    EOF

    kubectl certificate approve vault-req
    kubectl get csr vault-req -o jsonpath='{.status.certificate}' | base64 --decode > tls.crt
    kubectl create secret generic vault-certs --from-file=.
    ```

    Перзапустим наш vault уже с новыми настройками:

    ```bash
    helmp delete vault
    helm upgrade --install vault vault-helm -f kubernetes-vault/vault/values-tls.yml
    ```

    Предоставить примеры работы cURL:
    Создадим под с привязанным сервис аккаунтом и установим туда curl и jq

    ```bash
    kubectl run --generator=run-pod/v1 tmp --rm -i --tty --serviceaccount=vault-auth --image alpine:3.7
    ```

    ```bash
    apk add curl jq
    ```

    Залогинимся и получим клиентский токен:

    ```bash
    VAULT_ADDR=https://vault:8200
    KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
    curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login
    {"request_id":"bac08d9d-9ff6-5a7e-d47e-92acb2fc1c8a","lease_id":"","renewable":false,"lease_duration":0,"data":null,"wrap_info":null,"warnings":null,"auth":{"client_token":"s.MJBgfB3mrLO4ZqKofV8Feo9L","accessor":"hBzp3hzggQE1kzLIAlfQvwBk","policies":["default","otus-policy"],"token_policies":["default","otus-policy"],"metadata":{"role":"otus","service_account_name":"vault-auth","service_account_namespace":"default","service_account_secret_name":"vault-auth-token-hfg2x","service_account_uid":"480a1370-adb4-4af6-9f1a-4d2d6ee1c92b"},"lease_duration":86400,"renewable":true,"entity_id":"980ba7c5-a436-f8d4-c6d2-454940160ef9","token_type":"service","orphan":true}}
    ```

28. Настроить автообновление сертификатов

    Запустить nginx
    Реализовать автообновление сертификатов для nginx c помощью consul-template или vault-inject
    В `Readme.md` приложить скриншоты сртификатов из браузера (2 штуки, для демонстрации рефреша)
    Конфиги для развертывания приложить в репозиторий

    Поправим конфигурацию Nginx из ДЗ "kubernets-monitoring" что бы использовать его вместе с SSL. Файлы положим в `kubernetes-vault\nginx`. Соберём новую версию docker image gidmaster/nginx:v0.3 и запушим её на DockerHub

    ```bash
    cd nginx
    docker build -t gidmaster/nginx:v0.3 .
    docker push gidmaster/nginx:v0.3
    ```

    Создадим политику для чтения `pki_int` и применим к уже существующему сервис-аккаунту:

    ```bash
    kubectl cp kubernetes-vault/nginx/cert-issuer.hcl vault-0:./vault

    kubectl exec -it vault-0 -- vault policy write cert-issuer /vault/cert-issuer.hcl
    kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
    bound_service_account_names=vault-auth \
    bound_service_account_namespaces=default policies=otus-policy,cert-issuer default_ttl=1m max_ttl=5m
    ```

    Запустим `deployment` с nginx и Vault Agent Injector в качестве овтообновления сертификатов:

    ```bash
    kubectl apply -f kubernetes-vault/nginx/deployment.yml
    ```

    Сделаем проброс портов:

    ```bash
    kubectl port-forward nginx-tls-559457556b-fcncs 8443:8443
    ```

    Подключимся браузером на `https:\\test.example.com:8443` (не забыв прописать при этом `127.0.0.1 test.example.com` в /etc/hosts)

    И посмотрим на сертификат:

    ![alt_text](cert_2020-03-06_11-28-28.png "1st Certificate")

    Затем через некотрое время перезагрзим страницу и посмотрим ещ раз:

    ![alt_text](cert_2020-03-06_11-34-50.png "1st Certificate")

[Назад к содержанию](../README.md)
