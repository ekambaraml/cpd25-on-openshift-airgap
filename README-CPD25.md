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
 
 ## 3. Download the cpd-linux and repo.yaml files
 
 ## 4. Download the CP4D Assemblies
 
 ## 5. Install the CP4D Assemblies
