# Scaling a prophecy cluster

Prophecy supports both vertical scaling and horizontal scaling of all the apps in a prophecy cluster.

## Vertical Scaling
Prophecy operators support vertical scaling with help of Kubernetes Quality of Service functionality. 
Custom resource yaml expects the format of supplied resources in the same format as they get configured for Kubernetes QoS. Please see more details here: https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/

One of the below QoS can be assigned to any of our app via custom resource yaml supplied to our operators.

### Guaranteed
For an app to be given a QoS class of Guaranteed:
* Memory limit and a memory request must be the same.
* CPU limit and a CPU request must be the same.

### Burstable
For an app to be given a QoS class of Burstable:

* The Pod does not meet the criteria for QoS class Guaranteed.
* Either a memory or CPU, or both request is assigned in custom resource yaml

### BestEffort
For an app to be given a QoS class of BestEffort, there should be no memory or CPU limit request in custom resource yaml.


### Scaling app in controlplane namespace
Please run below command to scale an app in controlplane namespace of prophecy cluster:

```
kubectl -n <controlplanenamespace> edit ProphecyCluster
```

Identify the section for a particular app and add resource requests for the same. e.g. If we want to vertically scale up 'app', after editing 'ProphecyCluster' with the above command, it will look like this:

```
app:
	image: '<image-registry-path>/app:latest'
	resources:
		limits:
			cpu: 4000m
			memory: 12000Mi
		requests:
			cpu: 4000m
			memory: 12000Mi
```

Above example assigns a `guaranteed` qos to `app` with CPU as 4 virtual cores and memory as 12GB.

### Scaling app in dataplane namespace
Please run below command to scale an app in dataplane namespace of prophecy cluster:

```
kubectl -n <dataplanenamespace> edit ProphecyDataPlane
```

Identify the section for a particular app and add resource requests for the same. e.g. If we want to vertically scale up 'execution', after editing 'ProphecyCluster' with the above command, it will look like this:

```
execution:
	image: '<image-registry-path>/execution:latest'
	resources:
		limits:
			cpu: 2000m
			memory: 8000Mi
		requests:
			cpu: 2000m
			memory: 8000Mi
```

Above example assigns a `guaranteed` qos to `execution` with CPU as 2 virtual cores and memory as 8GB.

## Horizontal Scaling
Prophecy operators support horizontal scaling of our apps with the help of Kubernetes Horizontal Pod Autoscaler. https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/

Prophecy Operator assigns different applications provided metrics to horizontal pod autoscaler to horizontally scale prophecy apps by adding more replicas. Prophecy operator contains the intelligence of knowing the nature of all the applications within prophecy cluster and designs a customized scalability plan for each of our apps. 
