# CKA
The point of this repo is to be a study guide to pass the CKA exam.

## Quick Commands

### Services

Expose a pod
```
kubectl expose pod <POD_NAME> --name=<SERVICE_NAME> --port=80 --type=ClusterIP
```

### Nodes

Schedule a Pod to a Node
```
kubectl label nodes <node-name> size=large

kubectl run my-pod --image=my-image --overrides='{
  "spec": {
    "nodeSelector": {
      "size": "large"
    }
  }
}'
```

Taints and Tolerations, then Affinities are two other ways you can assign pods to nodes, however, nodeSelector seems the most straight-forward. 


### General Commands

List all resorces that support get or describe (list)
```
kubectl api-resources --verbs=list,get
```


### Ingress Class

Ingress controllers usually come with ingress classes. You should not have to install one on CKA. You may need to use one.
```
kubectl get ingressClasses
```

List each ingress and the corresponding ingress class
```
kubectl get ingress -A
```

# ec2-userdata-ssh
This user data script allows you to setup ssh access between your containers

If you want to add containerd to this, go to https://github.com/CodeBlanco/containerd_install/tree/main

To use the terraform for cka:

Run `terraform init` to initialize the directory.  
Run `terraform apply` and provide the number of instances if you want to override the default, e.g., `terraform apply -var="instance_count=3"`.  
Run `terraform destroy` to destroy any resources created.

`sudo kubeadm init --pod-network-cidr=192.168.0.0/16`
