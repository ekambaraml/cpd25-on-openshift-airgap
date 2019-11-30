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


| Host | Configuration | Count | Purpose |
|:------------|:-------------|:------------|:----------|
| Bastion| <ul><li>4 Core</li><li>8GB Ram</li><li> 100 GB Roo</li><li>500 GB for local repo/registry</li></ul>|1|Virtual Machine for installation||
| Master nodes| <ul><li>8 Core</li><li>32 GB Ram</li><li> 100 GB Roo</li><li>200 GB for Docker storage </li></ul>|3| Virtual Machine running OpenShift Control plane|
| Worker nodes| <ul><li>16 Core</li><li>64GB Ram</li><li> 100 GB Roo</li><li>200 GB for Docker storage</li><li>1 TB GB for persistance storage</li></ul>|3| Virtual Machine running Workload|
| Load Balancer| <ul><li>4 Core</li><li>8GB Ram</li><li> 100 GB Root</li></ul>|1| Virtual Machine local load balancer|


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

* [ ] 6. Mount docker disk on /var/lib/docker
  - $ ansible-playbook -i ansible.os25 playbooks/docker-storage-mount.yml
  
* [ ] 7. Subscribe to RedHat license (non-airgap only )
  - $ ansible-playbook -i ansible.os25 playbooks/redhat-register-machines.yml 

* [ ] 8. Disable all RPM repos
  - $ ansible-playbook -i ansible.os25 playbooks/disable-redhat-repos.yml 
  
* [ ] 9. enable OpenShift RPM repos (non-airgap only)
  - $ ansible-playbook -i ansible.os25 playbooks/enable-ocp-repos.yml

* [ ] 10. Copy ose.repo to all nodes (airgap only)
  - $ ansible-playbook -i ansible.os25 playbooks/yum-ose-repo.yml 

* [ ] 11. Install preinstall packages
  - $ ansible-playbook -i ansible.os25 playbooks/preinstallpackages.yml

* [ ] 12. Reboot all cluster nodes
  - $ ansible-playbook -i ansible.os25 playbooks/reboot-cluster.yml   

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


