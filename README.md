# ec2-userdata-ssh
This user data script allows you to setup ssh access between your containers

If you want to add containerd to this, go to https://github.com/CodeBlanco/containerd_install/tree/main

To use the terraform for cka:

Run `terraform init` to initialize the directory.  
Run `terraform apply` and provide the number of instances if you want to override the default, e.g., `terraform apply -var="instance_count=3"`.  
Run `terraform destroy` to destroy any resources created.

`sudo kubeadm init --pod-network-cidr=192.168.0.0/16`
