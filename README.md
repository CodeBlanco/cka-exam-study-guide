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


## Config

Get the current context.
```
kubectl config current-context
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

Events tell you what happened.

```
kubectl get events -n ns
```

See the hardware specs for a node (conditions are checks for Ready status)
```
kubectl describe nodes | grep -A5 Allocatable # "Conditions" is another good search term
```

Top is a classic command
```
kubectl top nodes
kubectl top pods -n ns
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

