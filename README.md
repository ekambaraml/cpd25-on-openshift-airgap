# Deploying OpenShift 3.11 on AirGap environment

![alt text][logo]

[logo]: https://github.com/ekambaraml/openshift311-airgap/blob/master/VPN-Bastion.png "Deployment Architecture"

# Steps Required to deploy
* [ ] 1. Provision Infrastructure
* [ ] 2. Download the OpenShift RPMs and Docker images
* [ ] 3. Setup External DNS and include all nodes
* [ ] 4. Setup DNS wild card entry
* [ ] 5. Setup YUM RPM Repository for OpenShift 3.11
* [ ] 6. Setup Docker Registry with OpenShift 3.11
* [ ] 7. Update ansible playbook vars/global.yml
* [ ] 8. Update ansible.os25
* [ ] 9. Prepare cluster nodes
* [ ] 10. NFS Server setup
* [ ] 11. Deploy OpenShift
      Create inventory file
      Run prerequisites
      Run deploy_cluster
* [ ] 12. Access the Cluster URL


# Provision Infrastructure


| Host |Count |Configuration | Storage | Purpose |
|:------|------|:-------------|:------------|:----------|
| Bastion| 1 | <ul><li>8 Core</li><li>16 GB Ram</li></ul>|<ul><li> /ibm 100 GB install</li><li>/var/lib/docker 200+ GB to storge docker images </li><li>/repository 500+ GB for local repo/registry</li></ul>|Virtual Machine for installation; This machine will also act as a local RPM Yum repository and Docker registry for airgap environment|
| Master nodes|1 or 3 |<ul><li>8 Core</li><li>32 GB Ram</li></u>|<ul><li> 100 GB Root</li><li>/var/lib/docker 200+ GB for Docker storage </li></ul>|Virtual Machine running OpenShift Control plane|
| Worker nodes|3 or more| <ul><li>16 Core</li><li>64GB Ram</li></u>|<ul><li> 100 GB Root</li><li>/var/lib/docker 200+ GB for Docker storage</li><li>1 TB GB for persistance storage</li></ul>|Virtual Machine running Workload|
| Load Balancer|1 option| <ul><li>4 Core</li><li>8GB Ram</li>|<li> 100 GB Root</li></ul>|Virtual Machine local load balancer|

# Download Openshift Product
Openshift install requires RPM and access the redhat docker registry (registry.redhat.io). In the case of AirGap deployment, both need to be made available local to the environment.

# Prepare Cluster nodes
Ansible playbooks are created to automate the steps required to prepare the nodes and installing prerequisite packages and configuring the machines. The playbooks are stored in an external git repository for everyone to make use of it.  

* [ ] Bastion Host setup

Bastion node is a host in the same network as cluster nodes and have access to cluster nodes. This host will be used for installing OpenShift cluster and hosting the temporary local Yum repository and Docker registry for installation purpose.

### 1. Clone the git repository
```
	$ cd /ibm
	$ git clone https://github.com/ekambaraml/openshift311-airgap.git
	$ cd openshift311-airgap
```
	

### 2. Hostfile Creation
The playbooks requires hostfile listing machines. Here is an example hosts file format:

* Example: using SSH

```
	[cluster]
	172.300.159.178 private_ip=10.188.201.34 name=master-01 type=master 
	172.300.159.190 private_ip=10.188.201.39 name=master-02 type=master 
	172.300.159.184 private_ip=10.188.201.44 name=master-03 type=master 
	172.300.104.56  private_ip=10.188.201.6  name=worker-01 type=worker 
	172.300.104.48  private_ip=10.188.201.51 name=worker-02 type=worker
	172.300.104.46  private_ip=10.188.201.58 name=worker-03 type=worker
	[loadbalancer]
	172.300.104.59 private_ip=10.188.201.11 name=loadbalancer type=proxy 
```

* Example: using password

```
	[cluster]
	172.300.159.178 private_ip=10.188.201.34 name=master-01 type=master ansible_ssh_user=root ansible_ssh_pass=<password>
	172.300.159.190 private_ip=10.188.201.39 name=master-02 type=master ansible_ssh_user=root ansible_ssh_pass=<password>
	172.300.159.184 private_ip=10.188.201.44 name=master-03 type=master ansible_ssh_user=root ansible_ssh_pass=<password>
	172.300.104.56  private_ip=10.188.201.6  name=worker-01 type=worker ansible_ssh_user=root ansible_ssh_pass=<password>
	172.300.104.48  private_ip=10.188.201.51 name=worker-02 type=worker ansible_ssh_user=root ansible_ssh_pass=<password>
	172.300.104.46  private_ip=10.188.201.58 name=worker-03 type=worker ansible_ssh_user=root ansible_ssh_pass=<password>
	[loadbalancer]
	172.300.104.59 private_ip=10.188.201.11 name=loadbalancer type=proxy ansible_ssh_user=root ansible_ssh_pass=<password>
```

### 3. Setup local Yum repository for OpenShift 3.11 RPMs
  * [ ] Mount the disk to <b> /repository </b>. It requires about 200GB of storage
```
     $ cd /repository
     $ mkdir ocp311
     # <Transfer the downloaded openShift  RPMs under the /repository/ocp311 folder and untar the RPMs>
 ```
  * [ ] Install httpd for hosting the RPM repository
```
    yum install -y httpd
    cd /var/www/html
    ln -s /repository/ocp311 /var/www/html/repo
```
  * [ ] Ensure HTTP Server configuration file enables symlink with this option: `Options Indexes FollowSymLinks` for given directory
```   
    vi /etc/httpd/conf/httpd.conf
    yum install -y policycoreutils-python
    semanage fcontext -a -t httpd_sys_content_t "/repository/ocp311/ppa(/.*)?"
    restorecon -Rv /repository/ocp311/ppa
```
  * [ ] Open Firewall port

```
    systemctl unmask firewalld
    systemctl enable firewalld
    systemctl start firewalld
    firewall-cmd --zone=public --add-port=80/tcp --permanent
    firewall-cmd --reload
    systemctl enable httpd
    systemctl start httpd
```
  * [ ] Create /etc/yum.repos.d/ose.repo using the blow content. Note: Repo-server = Bastion node IP
```
    [rhel-7-server-rpms]
    name=rhel-7-server-rpms
    baseurl=http://<repo-server>/repo/rhel-7-server-rpms
    enabled=1
    gpgcheck=0

    [rhel-7-server-extras-rpms]
    name=rhel-7-server-extras-rpms
    baseurl=http://<repo-server>/repo/rhel-7-server-extras-rpms
    enabled=1
    gpgcheck=0

    [rhel-7-server-ansible-2.6-rpms]
    name=rhel-7-server-ansible-2.6-rpms
    baseurl=http://<repo-server>/repo/rhel-7-server-ansible-2.6-rpms
    enabled=1
    gpgcheck=0

    [rhel-7-server-ose-3.11-rpms]
    name=rhel-7-server-ose-3.11-rpms
    baseurl=http://<repo-server>/repo/rhel-7-server-ose-3.11-rpms
    enabled=1
    gpgcheck=0
```

  * [ ] disable all repository

```
	subscription-manager repos --disable="*"
```
  * [ ] Cleanup all cache

```
	rm -rf /var/cache/yum
```
   * [ ] Testing Yum Repository Setup. The following command should list only 4 repositories.

```
	yum repolist
```
  * [ ] Copy /etc/yum.repos.d/ose.repo to all master and worker nodes to ensure they all can access the OpenShift RPM repository

```
    scp /etc/yum.repos.d/ose.repo  <host>:/etc/yum.repos.d/ose.repo
```

### 4. Setup local Docker registry server
This server will host the RedHat OpenShift images from registry.redhat.io for installation purpose in an airgaped environment. We will be using a docker container "regisry:2" for running the registry server. <i>This docker registry image need to be downloaded from a internet facing machine and transfer to Bastion Host</i>.
* [ ] Downloading docker registry image and test busybox image
This step need to be done on a internet facing system.

```        
    docker pull  docker.io/library/registry:2
    docker pull  docker.io/library/busybox:latest
    docker save -o registry.tar \
            docker.io/library/registry:2 \
            docker.io/library/busybox:latest
```
* [ ] Load Registry
```
	docker load -i registry2.tar
```

* [ ] Update /etc/containers/registry.conf, update registry.conf file to use your image registry. 
```
	[registries.insecure]
	registries = ["registry.ibmcloudpack.com:5000"]
```
* [ ] Start the local registry

```
	docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

* [ ] Testing the registry setup
```
    docker images
    docker tag docker.io/busybox  <<registry.ibmcloudpack.com>>:5000/busybox
    docker push <<registry.ibmcloudpack.com>>:5000/busybox
```

Below are the sequences of steps needed to prepare the nodes before starting the openshift install. All these commands will be run from bastion Host.

* [ ] 1. Password less ssh between Bastion and all nodes

* [ ] 2. Clocksync on all nodes
  - $ ansible-playbook -i ansible.os25 playbooks/clocksync.yml

* [ ] 3. Ipv4 forward
  - $ ansible-playbook -i ansible.os25 playbooks/ipforward.yml 

* [ ] 4. SELINUX enforced
  - $ ansible-playbook -i ansible.os25 playbooks/seenforce.yml 

* [ ] 5. Enable NetworkManager
  - $ ansible-playbook -i ansible.os25 playbooks/network-manager.yml 

* [ ] 6. Partition and Mount docker disk on /var/lib/docker
  - $ ansible-playbook -i ansible.os25 playbooks/docker-storage-mount.yml
  
  Here is a step to manually partition disk and mount to the file system.
  Create <b>partition_disk.sh</b>
  ```
      #!/bin/bash
	if [[ $# -ne 2 ]]; then
	    echo "Requires a disk name and mounted path name"
	    echo "$(basename $0) <disk> <path>"
	    exit 1
	fi
	set -e
	parted ${1} --script mklabel gpt
	parted ${1} --script mkpart primary '0%' '100%'
	mkfs.xfs -f -n ftype=1 ${1}1
	mkdir -p ${2}
	echo "${1}1       ${2}              xfs     defaults,noatime    1 2" >> /etc/fstab
	mount ${2}
	exit 0
   ```
   Then run the command for each partition on every nodes.
 
   ```
   sh partition_disk.sh /dev/<deviceName>	/<fileSystemName>

   example:
   sh partition_disk.sh /dev/sdb /var/lib/docker
   ```
  
* [ ] 7. Subscribe to RedHat license (non-airgap only )
  - $ ansible-playbook -i hosts playbooks/redhat-register-machines.yml 

* [ ] 8. Disable all RPM repos
  - $ ansible-playbook -i hosts playbooks/disable-redhat-repos.yml 
  
* [ ] 9. enable OpenShift RPM repos (non-airgap only)
  - $ ansible-playbook -i hosts playbooks/enable-ocp-repos.yml

* [ ] 10. Copy ose.repo to all nodes (airgap only)
  - $ ansible-playbook -i hosts playbooks/yum-ose-repo.yml 

* [ ] 11. Install preinstall packages
  - $ ansible-playbook -i hosts playbooks/preinstallpackages.yml

* [ ] 12. Reboot all cluster nodes
  - $ ansible-playbook -i hosts playbooks/reboot-cluster.yml   

* [ ] 13. Only on Bastion Host: Install ansible-Openshift
  - $ yum -y install openshift-ansible-3.11.141-1.git.0.a7e91cd.el7
  
# Setup NFS Server (persistent storage)
On a node with NFS disk
```$ yum install nfs-utils
edit /etc/exports
$ cat /etc/exports
/data *(rw,sync,no_root_squash)
$ systemctl restart nfs-server
$ systemctl enable nfs-server

# Firewall setup
$ firewall-cmd --permanent --add-service=nfs
$ firewall-cmd --permanent --add-service=mountd
$ firewall-cmd --permanent --add-service=rpc-bind
$ firewall-cmd –reload

Testing NFS disk mount on client machine (worker 1)
$ showmount -e <nfs-server-machine>
$ mkdir /tmp/x
$ mount <nfs-server-machine>:/data /tmp/x

unmount the test directory
$ umount /root/x
```

# Create Inventory file

# Deploy OpenShift 3.11
On Bastion host, run the following commands to deploy openshift 3.11 
- $ ansible-playbook -i  inventory /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml
- $ ansible-playbook -i  inventory /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

# Accessing OpenShift console
$ oc get routes -n openshift-console | grep console
console   console.apps.examples.com             console    https     reencrypt/Redirect   None

Access the url https://console.apps.examples. com


