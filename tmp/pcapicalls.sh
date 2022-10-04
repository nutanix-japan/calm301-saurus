curl -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d "{
  \"kind\": \"cluster\",
  \"sort_attribute\": \"string\",
  \"filter\": \"string\",
  \"length\": 0,
  \"sort_order\": \"string\",
  \"offset\": 0
}" "https://10.38.9.137:9440/api/nutanix/v3/clusters/list"


curl -X 'GET' \
  'https://10.38.18.201:9440/api/nutanix/v3/clusters/0005e93a-3b29-fa1a-6b84-ac1f6b6922d1' \
  -H 'accept: application/json' \
  -H 'X-Nutanix-Client-Type: ui'
https://10.38.18.201:9440/api/nutanix/v3/clusters/0005e93a-3b29-fa1a-6b84-ac1f6b6922d1

curl -X GET --header "Accept: application/json" "https://10.38.9.137:9440/api/nutanix/v3/clusters/0005e946-32ea-4cdb-56c3-ac1f6b6e5334"

curl -O https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-install-linux.tar.gz
curl -O https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz 
tar xvf openshift-install-linux.tar.gz
tar xvf openshift-client-linux.tar.gz 

cp kubectl /usr/local/bin
cp oc /usr/local/bin
cp openshift-install /usr/local/bin

acli net.add_to_ip_blacklist Primary ip_list=


RELEASE_IMAGE=$(openshift-install version | awk '/release image/ {print $3}')
CCO_IMAGE=$(oc adm release info --image-for='cloud-credential-operator' $RELEASE_IMAGE)
oc image extract $CCO_IMAGE --file="/usr/bin/ccoctl" -a pull_secret.json
chmod o+x ccoctl
chmod g+x ccoctl
chmod u+x ccoctl && cp ccoctl /usr/local/bin/

mkdir creds

cat << EOF > creds/pc_credentials.yaml
credentials:
- type: basic_auth
  data:
    prismCentral:
      username: "admin"
      password: "techX2020!"
EOF

oc adm release extract --credentials-requests --cloud=nutanix --to=credreqs -a pull_secret.json $RELEASE_IMAGE
ccoctl nutanix create-shared-secrets --credentials-requests-dir=credreqs --output-dir=. --credentials-source-filepath=creds/pc_credentials.yaml

openshift-install create install-config

# cert generation 

openssl genrsa -out pc.key 4096

openssl req -new -sha256  -key pc.key -config ./pc.conf -out pc.csr

openssl req -noout -text -in pc.csr | grep DNS

echo "subjectAltName = DNS:<dns_name1>, DNS:<dns_name2>, IP:<ip1>" >> pctext

openssl x509 -req -in server.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out pc.crt -days 1024 -sha256 -extfile pctext


