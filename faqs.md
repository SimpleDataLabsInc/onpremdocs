# FAQs

## Manage
### How to update Prophecy setup to the next version?
Please follow instructions in [Upgrade document](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/upgraderollback.md)

### How to rollback Prophecy setup to the next version?
Please follow instructions in [Rollback document](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/upgraderollback.md)

### How to set up periodic backup of Prophecy Cluster?
Please follow instructions in [Backup document](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/backuprestore.md)

### How to take one time backup of Prophecy Cluster?
Please follow instructions in [Backup document](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/backuprestore.md#ondemand-backups)

### How to restore a Prophecy Cluster?
Please follow instructions in [Restore document](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/backuprestore.md#deployment-process-for-restore-pod)



## Monitor 
### How to monitor Availability?
#### Using kubectl 
Please run below commands to list down all the services running in the Prophecy cluster. 
```
kubectl -n prophecy get pods 
```
A healthy state of cluster will look something like this:
```
NAME                                                      READY   STATUS             RESTARTS   AGE
app-prophecy-78579cb95d-fzlx2                             1/1     Running            0          5h2m
bootup-prophecy-7787558965-rqdgm                          1/1     Running            0          150d
bootupdp-prophecy-679cfbbff6-cs8nm                        1/1     Running            0          149d
cgweb-prophecy-55949d865-jczn5                            1/1     Running            0          5h2m
execution-prophecy-764b69766-7rqqk                        1/1     Running            0          5h2m
gitserver-prophecy-56b7f6b78d-226dm                       1/1     Running            0          8d
lineage-prophecy-7db86d565-cd7cs                          1/1     Running            0          5h2m
metadataui-prophecy-65cb6d969b-wzbdt                      1/1     Running            0          8d
metagraph-prophecy-5dfc584ffd-nz2nh                       2/2     Running            0          5h1m
openidfederator-8f4bb56dd-mtknc                           1/1     Running            0          8d
pkg-manager-prophecy-5fb4885fb7-lbwxd                     1/1     Running            0          2d11h
pkg-managerdp-prophecy-5dc459dd54-nt48q                   1/1     Running            0          55d
postgres-prophecy-7fb6555466-4gp4q                        1/1     Running            0          8d
prophecy-dataplane-operator-644d46944c-hlb6k              1/1     Running            0          5h3m
prophecy-operator-7ddb9874b-wpjg8                         1/1     Running            0          5h2m
sparkedge-prophecy-58dd567f75-p8fd8                       1/1     Running            0          8d
utweb-prophecy-fcd4585b6-bsjwx                            1/1     Running            0          5h2m
```

The 'Status' column should show all the applications as 'Running', and 'Ready' column should be shown in 'x/x' format. If any application is not doing good, they will be in some state other than 'Running'. 
There is a possibility that they a service is in restart loop and in that case you will see an increased 'Restarts' count for that particular service.

#### Using Grafana 
Please follow instructions in [Monitoring document](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/monitoring.md) to deploy Prophecy grafana charts. 
A chart with the name [Kubernetes Cluster Overview](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/yamls/grafana-charts/k8sclusteroverview.json) has services' availability details under the "Namespace" section. Please choose "prophecy" as the namespace in the top level dropdown.

### How to monitor Performance?
#### Using kubectl 
Please run below command to identify the service pod name:

```
kubectl -n prophecy get pods 
```
Please copy the name of the service from the 'Name' column and run below commands to get the cpu & ram usage of a Prophecy service.

```
kubectl -n prophecy top  pod <podname>
```
'top pod' does not support --watch option, so please use 'watch' command of your local machine if you want to keep monitoring the usage for a longer period.

#### Using Grafana 
Please follow instructions in [Monitoring document](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/monitoring.md) to deploy Prophecy grafana charts. 
A chart with the name [Pod level details](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/yamls/grafana-charts/podusage.json) has services level performance details, as well as entire 'prophecy' namespace resource usage details. 
Please choose "prophecy" as the namespace in the top level dropdown and appropriate service/container name.


### How to monitor Capacity? 
#### Using kubectl 
There is no direct way of checking the usage of a persistent volume using kubectl. You can get inside the container and check the usage by running 'df -h' command.
Please run below command to identify the service pod name:

```
kubectl -n prophecy get pods 
```
Please copy the name of the service from the 'Name' column and run below commands to get inside the service container.

```
kubectl -n prophecy exec -it <podname> bash
```

#### Using Grafana 
Please follow instructions in [Monitoring document](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/monitoring.md) to deploy Prophecy grafana charts. 
A chart with the name [PVC level details](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/yamls/grafana-charts/storageusageandprediction.json) has all capacity related monitoring details. Please choose "prophecy" as namespace in the top level dropdown.



## Debug 
### How to check Prophecy Service logs?
Prophecy services logs are getting collected by node level log collection infra in Visa and you will be able to access any prophecy service log in the same way you access any other kubernetes application log in visa logging & monitoring system.

Alternatively you can use kubectl to check the logs of a service. Please run below command to identify the service pod name:

```
kubectl -n prophecy get pods 
```
Please copy the name of the service from the 'Name' column and run below command to get the logs of the service. 

```
kubectl -n prophecy logs  <podname>
```

### How to restart a particular Prophecy Service?
Identify the service by running below command:
```
kubectl -n prophecy get pods 
```

Please copy the name of the service from the 'Name' column and run below command to delete the service. Prophecy operator will restart the service again.

```
kubectl -n prophecy delete pod  <podname>
```

### What to do if I am facing slowness in my operations on the Prophecy dashboard?
Please check the [How to monitor Performance?](#how-to-monitor-performance) section above to check the resource utilization by different services.
Also it will be helpful to monitor the 'Availability' as well, so that we are sure services are not in an intermittent crash loop. 
Please check the [How to monitor Availability?](#how-to-monitor-availability) section above to check the availability of different services.

If a service requires more resources, please follow instructions in [How to increase resources of a particular service?](#how-to-increase-resources-of-a-particular-service) to increase cpu/ram resources of a particular service.

### How to increase resources of a particular service?
Prophecy services are divided in two different components, ControlPlane and DataPlane. We have two different operators managing these two components using kubernetes 'Custom Resources' named 'ProphecyCluster' and 'ProphecyDataPlane' respectively. 
These are the list of services for ControlPlane component in visa cluster:
* app
* metagraph
* cgweb
* gitserver
* lineage
* utweb
* metadataui
* edweb (0.7.x+ release)
* webui(0.7.x+ release)

These are the list of services for DataPlane component in visa cluster:
* execution

Identify the name of the service which requires changes. In the below example, we are considering 'metagraph' as an example. Please run below command to open the Prophecy ControlPlane custom resource yaml in edit mode.

```
kubectl -n prophecy edit ProphecyCluster
```
Once you are in edit mode, look for the service name, e.g. "metagraph:" and identify the "resource" section for this service. Increase/Decrease the resource in this section and save the file. 

If the service is in the DataPlane, please use below command to open the custom resource yaml in edit mode:
```
kubectl -n prophecy edit ProphecyDataPlane
```

### How to change/update the prophecy kerberos keytab?
* Generate a new keytab.
* Delete the existing configmap for kerberos keytab using command:
```
kubectl -n prophecy delete cm kerberos-keytab
```
* Create the new configmap for kerberos keytab using command: 
```
kubectl -n prophecy create configmap kerberos-keytab --from-file <path of new keytab>
```
* Restart execution pod by following instructions in: [How to restart a particular Prophecy Service?](#how-to-restart-a-particular-prophecy-service)
