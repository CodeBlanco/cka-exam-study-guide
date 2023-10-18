Pods in admin ns can access any pod in zoo

Only feeder pods in zoo can access the zoo-web pods, but they can not access the private-zoo pods.

Test can not access any.

In teams customers can not access any service in zoo. 

The feeders in teams connect to the zoo-web pod and write to an emptydir file, which a sidecar reads and writes to a local file (with hostpath). The sidecar also connects to a service and writes to a different hostpath file that was not made with a persistent volume. 

I would like to add a config map for the nginx settings. 
