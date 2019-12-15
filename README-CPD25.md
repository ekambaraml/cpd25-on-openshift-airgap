# Deploying Cloud Pak for Data on AirGap environment


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
  
  3. If the directory is not exist, create it, Then run the link
  
    # cd /etc/docker/certs.d/docker-registry-default.<apps.example.com/>
    # ln -s /etc/rhsm/ca/registry.crt redhat-ca.crt
    
  4. docker login -u $(oc whoami)  -p $(oc whoami -t)  docker-registry-default.<apps.example.com>
  ```
 
 ## 3. Setup NFS client provisioner
 
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
 cpd-linux preloadImages --action push --load-from=/data/wsl/  --transfer-image-to=docker-registry-default.apps.os311-rel25-master1.demo.ibmcloudpack.com/cpd  --target-registry-username=$(oc whoami) --target-registry-password=$(oc whoami -t) -a wsl -v 2.1.0
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
  
 ### Installing the WSL
 
 ```
 cpd-linux -a wsl -n cpd -c  managed-nfs-storage --load-from=/data/wsl  --cluster-pull-prefix=docker-registry.default.svc:5000/cpd --cluster-pull-username=$(oc whoami) --cluster-pull-password=$(oc whoami -t) -v 2.1.0
 ```
 
