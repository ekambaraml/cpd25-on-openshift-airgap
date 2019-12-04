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
| Bastion| 1 | <ul><li>8 Core</li><li>16 GB Ram</li></ul>|<ul><li> 100 GB Root</li><li>/var/lib/docker 200+ GB to storge docker images </li><li>/repository 500+ GB for local repo/registry</li></ul>|Virtual Machine for installation; This machine will also act as a local RPM Yum repository and Docker registry for airgap environment|
| Master nodes|1 or 3 |<ul><li>8 Core</li><li>32 GB Ram</li></u>|<ul><li> 100 GB Root</li><li>/var/lib/docker 200+ GB for Docker storage </li></ul>|Virtual Machine running OpenShift Control plane|
| Worker nodes|3 or more| <ul><li>16 Core</li><li>64GB Ram</li></u>|<ul><li> 100 GB Root</li><li>/var/lib/docker 200+ GB for Docker storage</li><li>1 TB GB for persistance storage</li></ul>|Virtual Machine running Workload|
| Load Balancer|1 option| <ul><li>4 Core</li><li>8GB Ram</li>|<li> 100 GB Root</li></ul>|Virtual Machine local load balancer|

# Download Openshift Product
Openshift install requires RPM and access the redhat docker registry (registry.redhat.io). In the case of AirGap deployment, both need to be made available local to the environment.

# Prepare Cluster nodes
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


