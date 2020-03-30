
helm install vault vault-helm -f gidmaster_platform/kubernetes-vault/vault/values.yml


kubectl exec -it vault-0 -- vault operator init --key-shares=1 --key-threshold=1
Unseal Key 1: Emhvz46URkZ5N9YkzGECN46lDozw8HW2azDFJWNbbno=

Initial Root Token: s.spY8Tbv9a2PokoByP0gc4Usa





kubectl exec -it vault-0 -- vault operator unseal 'Emhvz46URkZ5N9YkzGECN46lDozw8HW2azDFJWNbbno='
kubectl exec -it vault-1 -- vault operator unseal 'Emhvz46URkZ5N9YkzGECN46lDozw8HW2azDFJWNbbno='
kubectl exec -it vault-2 -- vault operator unseal 'Emhvz46URkZ5N9YkzGECN46lDozw8HW2azDFJWNbbno='

kubectl exec -it vault-0 -- vault login

kubectl exec -it vault-0 -- vault auth enable kubernetes
kubectl create serviceaccount vault-auth
kubectl apply --filename gidmaster_platform/kubernetes-vault/vault-guides/vault-auth-service-account.yml

export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8S_HOST='https://10.96.0.1:443'

kubectl exec -it vault-0 -- vault write auth/kubernetes/config \
token_reviewer_jwt="$SA_JWT_TOKEN" \
kubernetes_host="$K8S_HOST" \
kubernetes_ca_cert="$SA_CA_CRT"

kubectl cp gidmaster_platform/kubernetes-vault/otus-policy.hcl vault-0:./vault
kubectl exec -it vault-0 -- vault policy write otus-policy /vault/otus-policy.hcl
kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
bound_service_account_names=vault-auth \
bound_service_account_namespaces=default policies=otus-policy ttl=24h


kubectl exec -it vault-0 -- vault secrets enable pki

kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki


kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal common_name="example.com" ttl=87600h > CA_cert.crt

kubectl exec -it vault-0 -- vault write pki/config/urls issuing_certificates="http://vault:8200/v1/pki/ca" crl_distribution_points="http://vault:8200/v1/pki/crl"

kubectl exec -it vault-0 -- vault secrets enable -path=pki_int pki
kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=43800h pki_int

kubectl exec -it vault-0 -- vault write -format=json pki_int/intermediate/generate/internal common_name="example.com Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr


kubectl cp pki_intermediate.csr vault-0:vault

kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate csr=@vault/pki_intermediate.csr format=pem_bundle ttl="43800h"     | jq -r '.data.certificate' > intermediate.cert.pem

kubectl cp intermediate.cert.pem vault-0:vault
kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed certificate==@vault/intermediate.cert.pem






kubectl cp gidmaster_platform/kubernetes-vault/nginx/cert-issuer.hcl vault-0:./vault

kubectl exec -it vault-0 -- vault policy write cert-issuer /vault/cert-issuer.hcl
kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
bound_service_account_names=vault-auth \
bound_service_account_namespaces=default policies=otus-policy,cert-issuer default_ttl=1m max_ttl=5m


    kubectl exec -it vault-0 -- vault write pki_int/roles/example-dot-com \
        allowed_domains="example.com" \
        allow_subdomains=true \
        max_ttl="5m" default_ttl="1m" 

kubectl apply -f gidmaster_platform/kubernetes-vault/nginx/deployment.yml