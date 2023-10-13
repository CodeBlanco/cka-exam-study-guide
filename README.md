# What is this?
This repository was created to aid passing the CKA exam. It utilizes many technologies
- Terraform
- AWS
- Linux
- Kubeadm
- kubelet
- containerd
- Github Actions


Basically, there is a Github Action Pipeline that can apply/plan/destroy AWS instances. The instances all have containerd, kubeadm, and some network configs. The automation intentionally stops here because this is similar to the CKA exam environment. 

So after the pipeline creates the instances, you SSH in, create a cluster, join some nodes, practice some kubernetes, pass the CKA exam. 

The yaml files in the `templates` directory are examples meant to be practiced for the exam. Below are some handy commands.



## Quick Commands

### Services

Expose a pod
```
kubectl expose pod <POD_NAME> --name=<SERVICE_NAME> --port=80 --target-port=8080 --type=ClusterIP
# target port is the container app port
# You can use NodePort for type etc
```

Using a named port
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: my-container
    image: my-image
    ports:
    - name: http
      containerPort: 8080
---

kubectl expose pod <POD_NAME> --name=<SERVICE_NAME> --port=80 --target-port=http --type=ClusterIP
```

### Nodes

Schedule a Pod to a Node
```
kubectl label nodes <node-name> size=large

kubectl run my-pod --image=my-image --port=80 --overrides='{
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

### Ingress

Create a template
```
kubectl create ingress simple-ingress --rule="myapp.example.com/=my-service:http-port" --dry-run=client -o yaml > simple-ingress.yaml
```

If a service names a port, an ingress can use its name. Note that the targetPort requires the pod to have the port named.
```
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
  ports:
  - name: http-port
    port: 80
    targetPort: http-port

---

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-ingress
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              name: http-port

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
