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

