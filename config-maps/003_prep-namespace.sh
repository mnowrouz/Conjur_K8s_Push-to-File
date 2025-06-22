#creates namespaced configmap and creates service account

#remove --create-namespace line if namespace already exists

helm install namespace-prep cyberark/conjur-config-namespace-prep \
--create-namespace  \
--namespace test-app-namespace \
--set conjurConfigMap.authnMethod="authn-jwt" \
--set authnK8s.goldenConfigMap="conjur-configmap" \
--set authnK8s.namespace="cyberark-conjur-jwt" \
--set authnRoleBinding.create="false"

echo "Helm chart deployed"

kubectl create serviceaccount test-app-sa -n test-app-namespace

