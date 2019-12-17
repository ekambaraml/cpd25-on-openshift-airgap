

### Helm v2.14.3 setup for CP4D

```
wget https://get.helm.sh/helm-v2.14.3-linux-amd64.tar.gz

tar xvf ../helm-v2.14.3-linux-amd64.tar.gz 
cd linux-amd64/
cp helm /usr/local/bin
chmod 755 /usr/local/bin/helm
oc login
export TILLER_NAMESPACE=cpd
oc get secret helm-secret -n $TILLER_NAMESPACE -o yaml|grep -A3 '^data:'|tail -3 | awk -F: '{system("echo "$2" |base64 --decode > "$1)}'
export HELM_TLS_CA_CERT=$PWD/ca.cert.pem
export HELM_TLS_CERT=$PWD/helm.cert.pem
export HELM_TLS_KEY=$PWD/helm.key.pem
```


helm version  --tls

```
Client: &version.Version{SemVer:"v2.14.3", GitCommit:"0e7f3b6637f7af8fcfddb3d2941fcc7cbebb0085", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.12.2", GitCommit:"7d2b0c73d734f6586ed222a567c5d103fed435be", GitTreeState:"clean"}
```
