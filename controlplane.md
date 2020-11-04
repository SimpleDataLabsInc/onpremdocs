# 2. Controlplane Deployment

Deployment of controlplane requires installing bunch of global resources followed by namespace scoped resources as listed below -
* Global Resources
    1. Deploy Persistent Volumes
    2. Install Custom Resource Definition(CRD) for kind ProphecyCluster. Note that this resource is managed by Prophecy Controlplane Operator.

* Namespace Scoped Resources
    1. Set up roles and permissions for Prophecy Controlplane Operator to spin up new pods and services in the dedicated namespace.
    2. Deploy a secret to access the Docker image registry.
    2. Deploy Prophecy Controlplane Operator in the same namespace.
    3. Deploy the ingress resource for services that need to be exposed outside the kubernetes cluster.
    4. Deploy the custom resource(CR) ProphecyCluster in the same namespace.
    
The above steps have been listed under the following assumptions:
* The underlying kubernetes cluster has an nginx-controller running to manage ingress deployments.
* The k8s cluster has external-dns or something equivalent deployed to create DNS entries for ingress hosts in some DNS zone
* The k8s cluster has cert-manager deployed to automate issuance or renewal of certificates for services being deployed.
* There is an NFS server setup which will be used by Persistent Volumes for storage. Also, few paths are expected to be 
exported on this server - 
    * One for a persistent volume shared by all Prophecy services in controlplane.
    * One for gitserver logs
    * One for postgres logs
* There is a dedicated namespace created for controlplane deployment.
* There is a docker image registry setup which has docker images for all Prophecy services.

Rest of the sections in this document focus on each of the yamls that need to be deployed to get the Prophecy controlplane 
setup on your cluster. Also, the given yamls assume the deployment name to be `cp`. This can be changed as per need.


## Global Resources
This section contains the yaml files for the global resources needed for deployment.

### Persistent Volumes
The yamls for Persistent Volumes creation are provided below. `<nfs-server-ip>` needs to be populated for them to work.
Also, as mentioned above, it is assumed that the deployment name is `cp`. 

<details><summary>Persistent Volumes YAML Files</summary>
<p>

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-init-pv-cp
  labels:
    prophecy.io/cluster: cp
    prophecy.io/component: nfs
spec:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 128Gi
  mountOptions:
    - hard
  nfs:
    path: <exported path on nfs server>
    server: <nfs-server-ip>
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs
  volumeMode: Filesystem

---

apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-log-volume-cp
spec:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 10Gi
  mountOptions:
    - hard
  persistentVolumeReclaimPolicy: Retain
  nfs:
    path: <exported path on nfs server>
    server: <nfs-server-ip>
  storageClassName: nfs
  volumeMode: Filesystem

---

apiVersion: v1
kind: PersistentVolume
metadata:
  name: gitserver-log-volume-cp
spec:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 10Gi
  mountOptions:
    - hard
  nfs:
    path: <exported path on nfs server>
    server: <nfs-server-ip>
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs
  volumeMode: Filesystem

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-volume-cp
spec:
  accessModes:
    - ReadWriteOnly
  capacity:
    storage: 10Gi
  persistentVolumeReclaimPolicy: Retain
  storageClassName: localpath

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gitserver-volume-cp
spec:
  accessModes:
    - ReadWriteOnly
  capacity:
    storage: 10Gi
  persistentVolumeReclaimPolicy: Retain
  storageClassName: localpath

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: metagraph-volume-cp
spec:
  accessModes:
    - ReadWriteOnly
  capacity:
    storage: 10Gi
  persistentVolumeReclaimPolicy: Retain
  storageClassName: localpath

```

</p>
</details>

**Note** _These volumes will be referred in yaml for ProphecyCluster CR. So, any changes in the names of volumes should 
be made in CR too. Also as mentioned before, `nfs path` for all above yamls needs to be exported in NFS server. Also note that `postgres-volume-cp`, 
`gitserver-volume-cp` and `metagraph-volume-cp` are localpath based volume, and the storage class name used in this yaml should be changed to correct storage class._

### ProphecyCluster CRD

<details><summary>ProphecyCluster CRD YAML File</summary>
<p>

```
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: prophecyclusters.prophecy.simpledatalabs.inc
spec:
  group: prophecy.simpledatalabs.inc
  names:
    kind: ProphecyCluster
    listKind: ProphecyClusterList
    plural: prophecyclusters
    singular: prophecycluster
  scope: Namespaced
  subresources:
    status: {}
  validation:
    openAPIV3Schema:
      description: ProphecyCluster is the Schema for the prophecyclusters API
      properties:
        apiVersion:
          description: 'APIVersion defines the versioned schema of this representation
            of an object. Servers should convert recognized schemas to the latest
            internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
          type: string
        kind:
          description: 'Kind is a string value representing the REST resource this
            object represents. Servers may infer this from the endpoint the client
            submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
          type: string
        metadata:
          type: object
        spec:
          description: ProphecyClusterSpec defines the desired state of ProphecyCluster
          properties:
            app:
              properties:
                app-common-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                app-ext-service:
                  type: boolean
                app-gittmp-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                app-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                app-m2-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                app-session-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                app-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                auth-backend:
                  type: string
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                loggingurl:
                  type: string
                monitoringurl:
                  type: string
                openid-client-id:
                  type: string
                openid-connector-id:
                  type: string
                openid-federator-host:
                  type: string
                openid-federator-port:
                  type: string
                openid-issuer-url:
                  type: string
                openid-redirect-ui:
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of kafka instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: Resources determines the compute and memory resources
                    reserved
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
              type: object
            bootup:
              properties:
                bootup-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of zookeeper instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
              type: object
            cgkafka:
              properties:
                cgkafka-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of transpiler instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
              type: object
            cgparse:
              properties:
                cgparse-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of transpiler instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
              type: object
            cgweb:
              properties:
                cgweb-common-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                cgweb-ext-service:
                  type: boolean
                cgweb-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                cgweb-session-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                cgweb-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of kafka instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
              type: object
            customer_name:
              type: string
            disable_fluentbit_sidecar:
              type: boolean
            enable_kamon:
              type: boolean
            enabledapps:
              type: string
            export:
              properties:
                export-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                json-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of transpiler instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
              type: object
            externalpostgres:
              type: string
            externalstorage:
              properties:
                base-vol-name:
                  description: This is the volume name used in bootup container volume
                    Name and not the PV PVC name is computed using Volume name as
                    <volume name>-pvc
                  type: string
                driver:
                  type: string
                provisioner:
                  type: string
                storageclassname:
                  type: string
                storagetype:
                  type: string
                volumehandle:
                  type: string
              type: object
            extraFlags:
              additionalProperties:
                type: string
              type: object
            fabrix:
              properties:
                fabrix-common-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                fabrix-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                fabrix-sock-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of kafka instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
              type: object
            fluentbitconfigname:
              type: string
            fluentbitelastichost:
              type: string
            fluentbitelasticpasswd:
              type: string
            fluentbitelasticport:
              type: integer
            fluentbitelasticuser:
              type: string
            gitserver:
              properties:
                fluentbitconfigname:
                  description: Name of app's fluent-bit config
                  type: string
                git-ext-service:
                  type: boolean
                git-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                git-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of kafka instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
              type: object
            gitsync:
              properties:
                gitsync-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                gitsync-out-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of transpiler instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
              type: object
            kafka:
              properties:
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                kafka-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of kafka instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
              type: object
            lineage:
              properties:
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                lineage-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of lineage instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
              type: object
            metadataui:
              properties:
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
              type: object
            metagraph:
              properties:
                enable-git-manager:
                  type: boolean
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                metagraph-common-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                metagraph-ext-service:
                  type: boolean
                metagraph-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                metagraph-projectrepos-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                metagraph-session-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                metagraph-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of kafka instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
              type: object
            namespace:
              description: Namespace for current prophecy cluster generated ClusterID
              maxLength: 25
              minLength: 1
              pattern: ^[a-z0-9]([a-z0-9]*[a-z0-9])?$
              type: string
            path-prefix:
              description: "\tA common path prefix for all containers where the BaseVol
                is mounted in all containers. Eg `/storage` as decided in discussions
                with Vishal. This is not the actual path in NFS/EFS. Its the mount
                path inside each app container."
              type: string
            pkg_manager:
              properties:
                image:
                  description: Image specifies the app image to use in the data plane.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of pkg_manager instances to
                    deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: Resources determines the compute resources reserved
                    for each pkg_manager replica.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
              type: object
            postgres:
              properties:
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                postgres-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                postgres-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of kafka instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
              type: object
            prophecy_jar_name:
              type: string
            prophecy_libs_jar_name:
              type: string
            prophecyclusterid:
              description: 'UberContolplane generated ClusterID TODO: Add validation'
              type: string
            prophecyclustername:
              description: Name of the cluster
              maxLength: 25
              minLength: 1
              pattern: ^[a-z0-9]([a-z0-9]*[a-z0-9])?$
              type: string
            spark-history:
              properties:
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of kafka instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
                sparkhistory-event-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                sparkhistory-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
              type: object
            spark-master:
              properties:
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of kafka instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
                sparkmaster-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
              type: object
            spark-worker:
              properties:
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of kafka instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
                sparkworker-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
              type: object
            sparkedge:
              properties:
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of kafka instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
                sparkedge-common-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                sparkedge-event-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                sparkedge-jar-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                sparkedge-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                sparkedge-m2-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
              type: object
            tenant_name:
              type: string
            transpiler:
              properties:
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of transpiler instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
                transpiler-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                transpilertype:
                  type: string
              type: object
            utweb:
              properties:
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of utweb instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
                utweb-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
              type: object
            zookeeper:
              properties:
                image:
                  description: Image specifies the app image to use in the cluster.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of zookeeper instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: ResourceRequirements describes the compute resource
                    requirements.
                  properties:
                    limits:
                      additionalProperties:
                        type: string
                      description: 'Limits describes the maximum amount of compute
                        resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                    requests:
                      additionalProperties:
                        type: string
                      description: 'Requests describes the minimum amount of compute
                        resources required. If Requests is omitted for a container,
                        it defaults to Limits if that is explicitly specified, otherwise
                        to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/'
                      type: object
                  type: object
                zk-log-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
                zk-volume:
                  properties:
                    accessmode:
                      type: string
                    appstoragerequest:
                      description: 'Limit of Storage Request which will be available
                        for all the prophecy apps for a given prophecy cluster Default
                        value: 1Gi'
                      type: string
                    volumename:
                      type: string
                  type: object
              type: object
          required:
          - enabledapps
          - namespace
          - prophecyclusterid
          - prophecyclustername
          type: object
        status:
          description: ProphecyClusterStatus defines the observed state of ProphecyCluster
          type: object
      type: object
  version: v1
  versions:
  - name: v1
    served: true
    storage: true

```

</p>
</details>

## Namespace scoped Resources
This section contains the yaml files for the namespace scoped resources needed for deployment.

### Roles, Service Accounts and Role-bindings
The yamls for the creation of role, service-account and role-binding are given below.

<details><summary>Role, Service Account & Role-Binding YAML Files</summary>
<p>

```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: prophecy-operator
rules:
  - apiGroups:
      - ""
    resources:
      - pods
      - services
      - endpoints
      - persistentvolumeclaims
      - events
      - configmaps
      - secrets
    verbs:
      - create
      - delete
      - get
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - apps
    resources:
      - deployments
      - daemonsets
      - replicasets
      - statefulsets
    verbs:
      - create
      - delete
      - get
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - monitoring.coreos.com
    resources:
      - servicemonitors
    verbs:
      - get
      - create
  - apiGroups:
      - apps
    resourceNames:
      - prophecy-operator
    resources:
      - deployments/finalizers
    verbs:
      - update
  - apiGroups:
      - ""
    resources:
      - pods
    verbs:
      - get
  - apiGroups: ["storage.k8s.io"]
    resources:
      - storageclasses
    verbs:
      - list
      - watch
  - apiGroups:
      - apps
    resources:
      - replicasets
      - deployments
    verbs:
      - get
  - apiGroups:
      - prophecy.simpledatalabs.inc
    resources:
      - '*'
      - prophecyclusters
    verbs:
      - create
      - delete
      - get
      - list
      - patch
      - update
      - watch


---

apiVersion: v1
kind: ServiceAccount
metadata:
  name: prophecy-operator
---

kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: prophecy-operator
subjects:
  - kind: ServiceAccount
    name: prophecy-operator
    namespace: cp
roleRef:
  kind: Role
  name: prophecy-operator
  apiGroup: rbac.authorization.k8s.io

```
</p>
</details>

**Note** _The RoleBinding resource assumes namespace `cp` for the service account._

### Secret for Docker image registry

The secret is expected to be created in advance by the infra-admin to provide access to the image registry and 
name of the secret is to be passed in Prophecy Controlplane Operator deployment yaml.

### Deployment of Prophecy Controlplane Operator
The deployment yaml for Prophecy Controlplane Operator is given below.

<details><summary>Deployment YAML File</summary>
<p>

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prophecy-operator
  labels:
    app.kubernetes.io/instance: cp
    app.kubernetes.io/version: 1.1.0
    name: prophecy-operator
    release: cp
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/instance: cp
      name: prophecy-operator
      release: cp
  template:
    metadata:
      labels:
        app.kubernetes.io/instance: cp
        name: prophecy-operator
        release: cp
    spec:
      serviceAccountName: prophecy-operator
      imagePullSecrets:
        - name: <registry-secret-name>
      securityContext: {}
      containers:
        - name: prophecy-operator
          image: <prophecy-controlplane-operator-image>:1.2.0
          imagePullPolicy: Always
          ports:
            - name: metrics
              containerPort: 8383
          resources: {}
          env:
            - name: WATCH_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: OPERATOR_NAME
              value: prophecy-operator

``` 
</p>
</details>

Note that the appropriate operator image and docker image registry secretname is to be passed in the above yaml.

### Ingress Resources
The yamls for ingress resources for exposing some services outside the K8s cluster are given below.

<details><summary>Ingress YAML Files</summary>
<p>

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: prophecy-app
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: prophecy-letsencrypt
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
    ingress.kubernetes.io/proxy-body-size: 100m
    nginx.ingress.kubernetes.io/proxy-body-size: 100m
    nginx.org/client-max-body-size: 100m
spec:
  tls:
    - hosts:
        - cp.visa.cloud.prophecy.io
      secretName: app-tls-secret
  rules:
    - host: cp.visa.cloud.prophecy.io
      http:
        paths:
          - path: /(.*)
            backend:
              serviceName: appservice
              servicePort: 9002

---

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: prophecy-cgweb
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
    ingress.kubernetes.io/proxy-body-size: 100m
    nginx.ingress.kubernetes.io/proxy-body-size: 100m
    nginx.org/client-max-body-size: 100m
spec:
  tls:
    - hosts:
        - cgweb.cp.visa.cloud.prophecy.io
      secretName: cgweb-tls-secret
  rules:
    - host: cgweb.cp.visa.cloud.prophecy.io
      http:
        paths:
          - path: /(.*)
            backend:
              serviceName: cgweb
              servicePort: 9003

---

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: prophecy-metagraph
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
    ingress.kubernetes.io/proxy-body-size: 100m
    nginx.ingress.kubernetes.io/proxy-body-size: 100m
    nginx.org/client-max-body-size: 100m
    nginx.ingress.kubernetes.io/configuration-snippet: |
      server_tokens off;
      location ~ ^/graphiql(.*) {
         deny all;
         return 403;
      }
spec:
  tls:
    - hosts:
        - metagraph.cp.visa.cloud.prophecy.io
      secretName: metagraph-tls-secret
  rules:
    - host: metagraph.cp.visa.cloud.prophecy.io
      http:
        paths:
          - path: /(.*)
            backend:
              serviceName: metagraph
              servicePort: 9004

---

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: prophecy-gitserver
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: prophecy-letsencrypt
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
    ingress.kubernetes.io/proxy-body-size: 100m
    nginx.ingress.kubernetes.io/proxy-body-size: 100m
    nginx.org/client-max-body-size: 100m
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_clear_headers 'X-Frame-Options';
      server_tokens off;
      location ~ ^/explore/users(.*) {
         deny all;
         return 403;
      }
spec:
  tls:
    - hosts:
        - gitserver.cp.visa.cloud.prophecy.io
      secretName: gitserver-tls-secret
  rules:
    - host: gitserver.cp.visa.cloud.prophecy.io
      http:
        paths:
          - path: /(.*)
            backend:
              serviceName: gitserver
              servicePort: 3000

---

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: prophecy-sparkedge
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
    ingress.kubernetes.io/proxy-body-size: 100m
    nginx.ingress.kubernetes.io/proxy-body-size: 100m
    nginx.org/client-max-body-size: 100m
spec:
  rules:
    - host: sparkedge.cp.visa.cloud.prophecy.io
      http:
        paths:
          - path: /(.*)
            backend:
              serviceName: sparkedge
              servicePort: 9005

```
</p>
</details>

**Note** _The annotation `cert-manager.io/cluster-issuer: prophecy-letsencrypt` in `prophecy-app` and `prophecy-gitserver` 
ingress resources. This needs to be changed based on the certificate issuer being used for cert-management._

### ProphecyCluster CR
The yaml for deploying this custom resource is given below. This resource is managed by the controlplane operator deployed 
above and it takes care of deploying and managing all Prophecy components. 

<details><summary>ProphecyCluster CR YAML File</summary>
<p>

```
apiVersion: prophecy.simpledatalabs.inc/v1
kind: ProphecyCluster
metadata:
  name: cp
spec:
  # Add fields here
  prophecyclustername: cp
  prophecyclusterid: "0XC0000001"
  namespace: cp
  disable_fluentbit_sidecar: true
  path-prefix: "/storage"
  prophecy_jar_name: prophecy-libs-assembly-1.0.jar
  prophecy_libs_jar_name: prophecy-libs_2.11-1.0.jar
  tenant_name: cp
  customer_name: visa
  image_registry_secret: <registry-secret-name>
  enabledapps: app,cgweb,gitserver,lineage,metagraph,postgres,sparkedge,utweb,pkgmanager
  bootup:
    bootup-volume:
      volumename: nfs-init-pv-cp
  app:
    auth-backend: ldap
    image: <app-image>:latest
    loggingurl: ""
    monitoringurl: ""
    openid-client-id: visaprophecyapp
    openid-connector-id: ldapvisa
    openid-federator-host: federator.prophecy.visa.cloud.prophecy.io
    openid-federator-port: "80"
    openid-issuer-url: http://federator.prophecy.visa.cloud.prophecy.io
    openid-redirect-ui: http://0.0.0.0:5555/callback
    resources:
      limits:
        cpu: 2000m
        memory: 4000Mi
      requests:
        cpu: 200m
        memory: 400Mi
  postgres:
    image: <postgres-image>:latest
    postgres-volume:
      volumename: postgres-volume-cp
    postgres-log-volume:
      volumename: postgres-log-volume-cp
  metagraph:
    image: <metagraph-image>:latest
    enable-git-manager: true
    metagraph-project-repos:
      volumename: metagraph-volume-cp
    resources:
      limits:
        cpu: 3000m
        memory: 8000Mi
      requests:
        cpu: 300m
        memory: 800Mi
  gitserver:
    image: <gitserver-image>:latest
    git-volume:
      volumename: gitserver-volume-cp
    git-log-volume:
      volumename: gitserver-log-volume-cp
  cgweb:
    image: <codegen-image>:latest
    resources:
      limits:
        cpu: 3000m
        memory: 8000Mi
      requests:
        cpu: 300m
        memory: 800Mi
  sparkedge:
    image: <sparkedge-image>:latest
  lineage:
    image: <lineage-image>:latest
  utweb:
    image: <utweb-image>:latest
  pkg_manager:
    image: <pkgmanager-image>:latest
  size: 3
  name: cp
  externalstorage:
    storagetype: nfs
    storageclassname: nfs
    base-vol-name: cp-shared-vol

```
</p>
</details>

**Note**  
*  _An appropriate image path is supposed to be passed for respective services in above CR._

* _`spec.namespace` value is assumed to be `cp`. This value needs to be changed if controlplane is being deployed in some other namespace._

* _`volumename` field in sections_
    * _bootup.bootup-volume_
    * _postgres.postgres-volume_
    * _postgres.postgres-log-volume_
    * _gitserver.git-volume_
    * _gitserver.git-log-volume_
    * _metagraph.metagraph-project-repos_

   _of above CR should be passed with appropriate Persistent volume names as defined during creation of Persistent Volumes._


