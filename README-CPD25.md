# Deploying Cloud Pak for Data on AirGap environment

## 0. Downloadables

* [ ] 1. Installer
```
      cpd-linux.  - Cloud Pak for Data installer
      repo.yaml  - YAML with container entitlement key (customers should get the entitle key from http://myibm.ibm.com)
```
      These two files are downloaded from the passport advantage site

* [ ] 2. Cloud Pak for Data Assemblies Download
```   
      Cloud Pak for Data platform(lite)
      Watson Studio Local(wsl)
      Watson Machine Learning
      Watson Knowledge Catalog
      SPSS modeler
      Decision Optimization
```

* [ ] 3. Extra support downloads

```
      Portworx
      NFS provisioner
      Registry2 for Airgap)
```


## 1. User with cluster-admin role

Run the following command on Master1 node of the cluster. Master1 node usually installed with "oc" openshift client tool.

```oc adm policy add-cluster-role-to-user cluster-admin ocadmin```


## 2. Expose the Docker registry to be accessed outside of the cluster nodes
   References : 
   
* [ ]    http://v1.uncontained.io/playbooks/operationalizing/expose_docker_registry.html
* [ ]    https://access.redhat.com/solutions/3654811
```
  1. Extract certificate:

    oc extract -n default secrets/registry-certificates --keys=registry.crt
   
  2.  scp registry.crt  <Client Hostname>:/etc/rhsm/ca/
  
  3. If the directory  "docker-registry-default.<apps.example.com>" is not exist, create it, Then run the link
  
    # cd /etc/docker/certs.d/docker-registry-default.<apps.example.com/>
    # ln -s /etc/rhsm/ca/registry.crt redhat-ca.crt
    
  4. docker login -u $(oc whoami)  -p $(oc whoami -t)  docker-registry-default.<apps.example.com>
  ```
 
 ## 3. Setup NFS client provisioner
 
NFS client provisioner is an openSource image need to be downloaded from internet facing machine.  This is required for Cloud Pak for Data.  (https://medium.com/faun/openshift-dynamic-nfs-persistent-volume-using-nfs-client-provisioner-fcbb8c9344e )

 
       1. oc project default
       2. cd nfs-client; oc create -f deploy/rbac.yaml
       3. oc adm policy add-scc-to-user hostmount-anyuid system:serviceaccount:default:nfs-client-provisioner
       4. oc create -f deploy/class.yaml
       5. oc create -f deploy/deployment.yaml
       6. oc get pods
       7. oc create -f deploy/test-claim.yaml
       
 ## 4. Setup Portworx
 


 
 ## 3. Download the cpd-linux and repo.yaml files
 
 ## 4. Download the CP4D Assemblies
 
 ### Apply permission
 ```
 cpd-linux  adm -a wsl -v 2.1.0 -n cpd --apply --load-from=/data/wsl
 ```
 
 ### Download images
 ```
 cpd-linux preloadImages -a wsl --action download -r repo.yml --download-path=/data/wsl
 ```
 
 ## 5. Install the CP4D Assemblies
 
 ### Apply permissions
 ```
  cpd-linux preloadImages -a wsl --action download -r repo.yml --download-path=/data/wsl
 ```
 ### Preload the image 
  ```
  cpd-linux preloadImages --action push --load-from=/data/wsl/  --transfer-image-to=docker-registry-default.apps.os311-rel25-master1.demo.ibmcloudpack.com/cpd  --target-registry-username=$(oc whoami) --target-registry-password=$(oc whoami -t) -a wsl -v 2.1.0
  ```
  
 ### If PORTWORX storage class is used, please ensure to increase the storage to 10GB at least for cpd-install-operator-pvc
 $ oc edit pvc cpd-install-operator-pvc
 
 ### Installing the WSL
 
 ```
 cpd-linux -a wsl -n cpd -c  managed-nfs-storage --load-from=/data/wsl  --cluster-pull-prefix=docker-registry.default.svc:5000/cpd --cluster-pull-username=$(oc whoami) --cluster-pull-password=$(oc whoami -t) -v 2.1.0
 ```
 
<hr>
# Installation using repo.yaml and directly download and install

[ ] download cpd-linux, repo.yaml

[ ] expose external routes to docker registry


1. Login to cluster
   
oc login -u ocadmin -p ocadmin <url>

2. Find the ocadmin token, which is required during the install

oc whoami -t

3. Login to docker registry

docker login -u ocadmin -p $(oc whoami -t) <registry url>
      
4. Now you are ready to install the Cloud Pak for Data

a. Generate and apply SA secrets

./cpd-linux  adm --repo repo.yaml --assembly lite --namespace <namespace>
      
b. Install the Lite

./cpd-linux  --repo repo.yaml --assembly lite --namespace <namespace>  --storageclass managed-nfs-storage --transfer-image-to docker-registry-default.apps.kcanalytica-dev5-bastion.fyre.ibm.com/<namespace> --cluster-pull-prefix docker-registry.default.svc:5000/<namespace> --ask-push-registry-credentials
      
When prompted, enter the userid and tocken to start the installation
