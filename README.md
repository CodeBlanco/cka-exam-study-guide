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

The yaml files in the `templates` directory are examples meant to be practiced for the exam. Below are some handy commands. It is not enough to cover everything on the exam, it is mostly fixated on the topics I want to re-encforce for my personal success at the exam. 

- In the end, setting up k8s from scratch was successfull but these example below work better on minikube.


## Config

Get the current context.
```
kubectl config current-context
```

Get a list of users
```
kubectl config view -o jsonpath='{.users[*].name}'
```

## Troubleshoot

List all resorces that support get or describe (list)
```
kubectl api-resources --verbs=list,get
```

Below is a quickstart of simple commands
```
kubectl get nodes
kubectl get <pods, svc, deployments, ....> -A -o wide
kubectl describe <pod,node,deployment> -n ns # look for conditions to see why it did not start
kubectl logs <pod> -n ns
systemctl status kubelet
journalctl -u kubelet
systemctl status containerd # or whatever container run time
journalctl -u containerd 
```

Logs on deployments
```
kubectl logs deploy/my-deployment                         # dump Pod logs for a Deployment (single-container case)
kubectl logs deploy/my-deployment -c my-container         # dump Pod logs for a Deployment (multi-container case)
```

Create a pod, have it do one thing, then go away...
In this case it does nslookup on a pod name.
```
kubectl run -it --rm --restart=Never busybox --image=busybox -- nslookup kubernetes.default
```

In case you need shell, use this to make a pod in a loop.
```
k run tester --image=busybox -- sh -c "while true; do echo 'running..'; sleep 10; done;"
```

Events tell you what happened.
```
# List Events sorted by timestamp
kubectl get events --sort-by=.metadata.creationTimestamp
# List all warning events
kubectl events --types=Warning
```


### Top
Top is a classic command
```
kubectl top nodes
kubectl top pods -n ns
```

```
kubectl top pods --sort-by=cpu
kubectl top nodes --sort-by=memory
```

Check networkpolicies
```
kubectl get networkpolicies -n ns
```

Logs, remember to specify container if two exists.
```
kubectl logs <pod-name> -c <init-container-name> -n ns
```

Exec commands in a container
```
kubectl exec -it <pod-name> -n ns -- wget -O- svcname # or ip
```

Do not forget to check on your storage options!
```
kubectl get pvc -A
```

It is always good to look at config files and secret configurations
```
kubectl get configmaps, secrets -n ns
```

### Labels and Select

```
# Show labels for all pods (or any other Kubernetes object that supports labelling)
kubectl get pods --show-labels
# Select by a label
kubectl get pods -l app=myapp
```

```
# Get the version label of all pods with label app=cassandra
kubectl get pods --selector=app=cassandra -o \
  jsonpath='{.items[*].metadata.labels.version}'
```

To add and remove labels
```
kubectl label <resource-type> <resource-name> key1=value1 key2=value2
kubectl label pod testpod key1-
```

## Services

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

- Nodeport can be accessed by the provisioned service ip from any node on the cluster (just get the node port).

## Nodes

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

See the hardware specs for a node (conditions are checks for Ready status)
```
kubectl describe nodes | grep -A5 Allocatable # "Conditions" is another good search term+
# you can also use "Taint" as search term
```

Engaging with Nodes
```
kubectl cordon my-node                                                # Mark my-node as unschedulable
kubectl drain my-node                                                 # Drain my-node in preparation for maintenance
kubectl uncordon my-node                                              # Mark my-node as schedulable
kubectl top node my-node                                              # Show metrics for a given node
kubectl cluster-info                                                  # Display addresses of the master and services
kubectl cluster-info dump                                             # Dump current cluster state to stdout
```
## Ingress

Create a template
```
kubectl create ingress simple-ingress --rule="myapp.example.com/=my-service:http-port" --dry-run=client -o yaml > simple-ingress.yaml
```

If a service names a port, an ingress can use its name. Note that the targetPort requires the pod to have the port named.
```yaml
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

## ConfigMap

This creates a config map
```
kubectl apply -f - << EOF
apiVersion: v1
kind: ConfigMap
data:
  index.html: |+
    <!DOCTYPE html>
    <html>
    <head>
        <title>Hello World</title>
    </head>
    <body>
        <h1>Hello from Kubernetes!</h1>
    </body>
    </html>
metadata:
  name: web-content
  namespace: default
EOF
```

Now use it in a pod (notice it mounts on just like any volume would)
```
kubctl apply -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.17.10
    ports:
    - containerPort: 80
    volumeMounts:
    - name: web-content-volume
      mountPath: /usr/share/nginx/html
  volumes:
  - name: web-content-volume
    configMap:
      name: web-content
EOF
```

Make it a service and try it out (node port)
```
k expose pod nginx-pod --type=NodePort --port=80
k get nodes -owide # get the node ip
k get svc # get the port
curl <NODE_IP>:<NODE_PORT> # you can see the web page
```

## RBAC

### New User

This was done with minikube for the purpose of practiving RBAC
```
mkdir -p /home/ec2-user/user2
cd /home/ec2-user/user2

# Create private key
openssl genpkey -algorithm RSA -out user2.key

# CN is username and O is group
# Createa a Cert Signature Request (.csr) that contains your public key and user info
openssl req -new -key user2.key -out user2.csr -subj "/CN=user2/O=group2"

# Sign the request with the minikube private key and certificate. This will produce a new cert (user2.crt)
# note these are default locations for minikube keys
openssl x509 -req -in user2.csr -CA ~/.minikube/ca.crt -CAkey ~/.minikube/ca.key -CAcreateserial -out user2.crt -days 365

# Configure kubectl for the new user
kubectl config set-credentials user2 --client-certificate=/home/ec2-user/user2/user2.crt --client-key=/home/ec2-user/user2/user2.key

# Configure context
kubectl config set-context user2-context --cluster=minikube --user=user2

# Switch to new user (commands below wont work as this user, you will have to switch back to minikube user)
kubectl config use-context user2-context
```

### Role + Role Binding

```
kubectl create namespace public
```

```
kubectl create role pod-reader-writer --namespace=public \
  --verb=get,list,watch,create,delete,update,patch \
  --resource=pods
```

```
kubectl create rolebinding read-write-public-pods --namespace=public \
  --role=pod-reader-writer \
  --user=user2
```

### ClusterRole + Cluster Role Binding

```
kubectl create clusterrole pod-reader --verb=get,list,watch --resource=pods
```

```
kubectl create clusterrolebinding read-all-pods --clusterrole=pod-reader --user=user2
```

### RBAC



