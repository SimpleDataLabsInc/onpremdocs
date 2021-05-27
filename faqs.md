# FAQs

## Manage
### How to update Prophecy setup to next version?
Please follow instructions in [Upgrade document](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/upgraderollback.md)

### How to rollback Prophecy setup to next version?
Please follow instructions in [Rollback document](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/upgraderollback.md)

### How to setup periodic backup of Prophecy Cluster?
Please follow instructions in [Backup document](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/backuprestore.md)

### How to take one time backup of Prophecy Cluster?
Please follow instructions in [Backup document](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/backuprestore.md)

### How to restore a Prophecy Cluster?
Please follow instructions in [Restore document](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/backuprestore.md)


## Monitor 
### Availability 
#### Using kubectl 
Please run below commands to list down all the services running in prophecy cluster. 
```
kubectl -n prophecy get pods 
```
A health state of cluster will look something like this:
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

The 'Status' column should show all the applications as 'Running' and 'Ready' column should show be in 'x/x' format. If any application is not doing good, they will not be in 'Running' state. There is a possibility that they are in consistent restart loop and in that case you will see an increase 'Restarts' count for that particular application.

#### Using Grafana 
Please follow instructions in [Monitoring document](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/monitoring.md) to deploy Prophecy grafana charts. 
A chart with name "Kubernetes Cluster Overview" has services' availability details under "Namespace" section. Please choose "prophecy" as namespace in top level dropdown.

### Performance 
#### Using kubectl 

#### Using Grafana 


### Capacity 
#### Using kubectl 

#### Using Grafana 

## Debug 
### How to check Prophecy Service logs?
Prophecy services logs are getting collected by node level log collection infra in Visa and you will be able to access any prophecy service log in the same way you access any other kubernetes application log in visa logging & monitoring system.
Alternatively you can use kubectl to check the log of a service. Please run below command to identify the service pod name:

```
kubectl -n prophecy get pods 
```
Please copy the name of the service from the 'Name' column and run below commands to get the logs of the service. 

```
kubectl -n prophecy logs  <podname>
```

### How to restart a particular Prophecy Service?
Identify the service by running below command:
```
kubectl -n prophecy get pods 
```

Please copy the name of the service from the 'Name' column and run below commands to delete the service. Prophecy operator will restart the service again.

```
kubectl -n prophecy delete pod  <podname>
```

### What to do if I am not able to login?


### What to do if I am facing slowness in my operations on Prophecy dashboard?


### How to change/update the prophecy kerberos keytab?


### How to increase resources of a particular service?

