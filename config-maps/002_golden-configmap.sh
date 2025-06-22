helm install "cluster-prep" cyberark/conjur-config-cluster-prep  -n "cyberark-conjur-jwt" \
      --create-namespace \
      --set conjur.account="conjur" \
      --set conjur.applianceUrl="https://<subdomain>.secretsmgr.cyberark.cloud/api" \
      --set conjur.certificateBase64=$(cat <CA_FILE_PATH> | base64) \
      --set authnK8s.authenticatorID="<AUTHN_JWT_SERVICE_ID>" \
      --set authnK8s.clusterRole.create=false \
      --set authnK8s.serviceAccount.create=false