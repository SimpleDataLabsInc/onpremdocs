# 3. Dataplane Deployment

Deployment of dataplane also requires installing bunch of global resources followed by namespace scoped resources as listed below -
* Global Resources
    1. Deploy Persistent Volumes
    2. Install Custom Resource Definition(CRD) for kind ProphecyDataPlane. Note that this resource is managed by Prophecy Dataplane Operator.

* Namespace Scoped Resources
    1. Set up roles and permissions for Prophecy Dataplane Operator to spin up new pods and services in the dedicated namespace.
    2. Deploy a secret to access the Docker image registry.
    2. Deploy Prophecy Dataplane Operator in the same namespace.
    3. Deploy the ingress resource for services that need to be exposed outside the kubernetes cluster.
    4. Deploy the custom resource(CR) ProphecyDataPlane in the same namespace.
    
The above steps have been listed under the following assumptions:
* The underlying kubernetes cluster has an nginx-controller running to manage ingress deployments.
* The k8s cluster has external-dns or something equivalent deployed to create DNS entries for ingress hosts in some DNS zone
* The k8s cluster has cert-manager deployed to automate issuance or renewal of certificates for services being deployed.
* There is an NFS server setup which will be used by Persistent Volumes for storage. Also, few paths are expected to be 
exported on this server - 
    * One for a persistent volume shared by all Prophecy services in dataplane.
    * One for postgres logs
* There is a dedicated namespace created for dataplane deployment.
* There is a image registry setup which has images for all Prophecy services.

Rest of the sections in this document focus on each of the yamls that need to be deployed to get the Prophecy dataplane 
setup on your cluster. Also, the given yamls assume the dataplane deployment name to be `dp`. This can be changed as per need.


## Global Resources
This section contains the yaml files for the global resources needed for deployment.

### Persistent Volumes
The yamls for Persistent Volumes creation are provided below. `<nfs-server-ip>` needs to be populated for them to work.
Also, as mentioned above, it is assumed that the deployment name is `dp`. 

<details><summary>Persistent Volumes YAML Files</summary>
<p>

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-init-pv-cp-dp
  labels:
    prophecy.io/dataplane: dp
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
  name: postgres-log-volume-cp-dp
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
  name: postgres-volume-cp-dp
spec:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 10Gi
  persistentVolumeReclaimPolicy: Retain
  storageClassName: localpath

```
</p>
</details>

**Note** _These volumes will be referred in yaml for ProphecyDataPlane CR. So, any changes in the names of volumes should 
be made in CR too. Also as mentioned before, `nfs path` for all above yamls needs to be exported in NFS server. Also note that `postgres-volume-cp-dp` 
is a localpath based volume, and the storage class name used in this yaml should be changed to correct storage class._

**Things to check** _Persistent volumes with appropriate name, size and policy are created in system_

### ProphecyDataPlane CRD

<details><summary>ProphecyDataPlane CRD YAML File</summary>
<p>

```
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: prophecydataplanes.prophecy.simpledatalabs.inc
spec:
  group: prophecy.simpledatalabs.inc
  names:
    kind: ProphecyDataPlane
    listKind: ProphecyDataPlaneList
    plural: prophecydataplanes
    singular: prophecydataplane
  scope: Namespaced
  subresources:
    status: {}
  validation:
    openAPIV3Schema:
      description: ProphecyDataPlane is the Schema for the prophecydataplanes API
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
          description: ProphecyDataPlaneSpec defines the desired state of ProphecyDataPlane
          properties:
            airflow:
              properties:
                airflow-dags-volume:
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
                airflow-ext-service:
                  type: boolean
                airflow-log-volume:
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
                airflow_base_url:
                  description: Base URL for airflow webserver
                  type: string
                image:
                  description: Image specifies the app image to use in the data plane.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of airflow instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: Resources determines the compute resources reserved
                    for each airflow replica.
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
            aws_access_key_id:
              type: string
            aws_default_region:
              type: string
            aws_emr_ec2_instance_profile:
              type: string
            aws_emr_ec2_subnet_id:
              type: string
            aws_emr_log_uri:
              type: string
            aws_emr_machine_type:
              type: string
            aws_emr_prophecy_jar_path:
              type: string
            aws_emr_role:
              type: string
            aws_emr_version:
              type: string
            aws_secret_access_key:
              type: string
            aws_session_token:
              type: string
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
                  description: Replicas is the number of bootup instances to deploy
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
            databricks_org_id:
              type: string
            databricks_prophecy_jar_path:
              type: string
            databricks_token:
              type: string
            databricks_url:
              type: string
            disable_fluentbit_sidecar:
              type: boolean
            enable_kamon:
              type: boolean
            enabledapps:
              type: string
            execution:
              properties:
                codegen_host:
                  type: string
                codegen_port:
                  type: integer
                databricks_glue_enabled:
                  type: boolean
                execution-common-volume:
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
                execution-dags-volume:
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
                execution-ext-service:
                  type: boolean
                execution-log-volume:
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
                execution_url:
                  type: string
                image:
                  description: Image specifies the app image to use in the data plane.
                  type: string
                metagraph_host:
                  type: string
                metagraph_port:
                  type: integer
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of execution instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: Resources determines the compute resources reserved
                    for each execution replica.
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
                spark-event-volume:
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
                spark-log-volume:
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
                sparkedge_host:
                  type: string
                sparkedge_port:
                  type: integer
                sparkhistory_url:
                  type: string
              required:
              - codegen_host
              - codegen_port
              - execution_url
              - metagraph_host
              - metagraph_port
              - sparkhistory_url
              type: object
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
            extra_flags:
              additionalProperties:
                type: string
              type: object
            fabric:
              type: string
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
            livy:
              properties:
                image:
                  description: Image specifies the app image to use in the data plane.
                  type: string
                livy-common-volume:
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
                livy-volume:
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
                  description: Replicas is the number of livy instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: Resources determines the compute resources reserved
                    for each livy replica.
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
            livy_execution_mode:
              type: string
            name:
              description: Name of the Data Plane
              maxLength: 25
              minLength: 1
              pattern: ^[a-z0-9]([a-z0-9]*[a-z0-9])?$
              type: string
            namespace:
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
                  description: Image specifies the app image to use in the data plane.
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
                  description: Replicas is the number of postgres instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: Resources determines the compute resources reserved
                    for each postgres replica.
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
            prophecy_jar_path:
              type: string
            redis:
              properties:
                image:
                  description: Image specifies the app image to use in the data plane.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of redis instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: Resources determines the compute resources reserved
                    for each redis replica.
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
            spark_execution_provider:
              type: string
            sparkhistory:
              properties:
                image:
                  description: Image specifies the app image to use in the data plane.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of execution instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: Resources determines the compute resources reserved
                    for each execution replica.
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
                spark-event-volume:
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
                spark-log-volume:
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
                sparkhistory-ext-service:
                  type: boolean
              type: object
            superset:
              properties:
                image:
                  description: Image specifies the app image to use in the data plane.
                  type: string
                qosclass:
                  description: PodQOSClass defines the supported qos classes of Pods.
                  type: string
                replicas:
                  description: Replicas is the number of superset instances to deploy
                  format: int32
                  minimum: 0
                  type: integer
                resources:
                  description: Resources determines the compute resources reserved
                    for each superset replica.
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
                superset-common-volume:
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
                superset-log-volume:
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
            team:
              type: string
            tenant_name:
              type: string
          required:
          - name
          - namespace
          type: object
        status:
          description: ProphecyDataPlaneStatus defines the observed state of ProphecyDataPlane
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

**Things to check** _A CRD with name `prophecydataplanes.prophecy.simpledatalabs.inc` is created in cluster. We can use `kubectl get crd` command to check the same._

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
  name: prophecy-dataplane-operator
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
      - dataplane-operator
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
      - prophecydataplanes
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
  name: prophecy-dataplane-operator
---

kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: prophecy-dataplane-operator
subjects:
  - kind: ServiceAccount
    name: prophecy-dataplane-operator
    namespace: dp
roleRef:
  kind: Role
  name: prophecy-dataplane-operator
  apiGroup: rbac.authorization.k8s.io

```
</p>
</details>

**Note** The RoleBinding resource assumes namespace `dp` for the service account.

**Things to check** _Please check if a role with name `prophecy-dataplane-operator` is created. `kubectl -n <dataplanenamespace' get role` can be used to check the same. 
Also we should see a rolebinding and a service account with name `prophecy-operator` should be created. `kubectl -n <dataplanenamespace' get rolebindings` and `kubectl -n <dataplanenamespace' get serviceaccounts` can be used to check the rolebinding and serviceaccount status respectively._

### Secret for Docker image registry

The secret is expected to be created in advance by the infra-admin to provide access to the Docker image registry and 
name of the secret is to be passed in Prophecy Dataplane Operator deployment yaml.

### Deployment of Prophecy Dataplane Operator
The deployment yaml for Prophecy Dataplane Operator is given below.

<details><summary>Deployment YAML File</summary>
<p>

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prophecy-dataplane-operator
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/instance: dp
      name: prophecy-dataplane-operator
      release: dp
  template:
    metadata:
      labels:
        app.kubernetes.io/instance: dp
        name: prophecy-dataplane-operator
        release: dp
    spec:
      serviceAccountName: prophecy-dataplane-operator
      imagePullSecrets:
        - name: <registry-secret-name>
      securityContext: {}
      containers:
        - name: prophecy-dataplane-operator
          image: <prophecy-dataplane-operator-image>:1.2
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
              value: prophecy-dataplane-operator

``` 
</p>
</details>

**Note** _An appropriate operator image and docker image registry secretname is to be passed in the above yaml._

**Things to check** _A deployment with a pod for prophecy dataplane operator should be created after deploying above yaml._

### Ingress Resources
The yamls for ingress resources for exposing some services outside the K8s cluster are given below.

<details><summary>Ingress YAML Files</summary>
<p>

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: prophecy-dataplane-execution
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: prophecy-letsencrypt
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
    ingress.kubernetes.io/proxy-body-size: 100m
    nginx.ingress.kubernetes.io/proxy-body-size: 100m
    nginx.org/client-max-body-size: 100m
spec:
  tls:
    - hosts:
        - execution.dp.cp.visa.cloud.prophecy.io
      secretName: execution-tls-secret
  rules:
    - host: execution.dp.cp.visa.cloud.prophecy.io
      http:
        paths:
          - path: /(.*)
            backend:
              serviceName: execution
              servicePort: 9001

---

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: prophecy-dataplane-sparkhistory
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: prophecy-letsencrypt
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
    ingress.kubernetes.io/proxy-body-size: 100m
    nginx.ingress.kubernetes.io/proxy-body-size: 100m
    nginx.org/client-max-body-size: 100m
spec:
  tls:
    - hosts:
        - sparkhistory.dp.cp.visa.cloud.prophecy.io
      secretName: sparkhistory-tls-secret
  rules:
    - host: sparkhistory.dp.cp.visa.cloud.prophecy.io
      http:
        paths:
          - path: /(.*)
            backend:
              serviceName: sparkhistory
              servicePort: 18080

```
</p>
</details>

**Note** The annotation `cert-manager.io/cluster-issuer: prophecy-letsencrypt` in above  
ingress resources. This needs to be changed based on the certificate issuer being used for cert-management.  

**Things to check** _Please verify if all the ingress points given in above yaml are created._

### ProphecyDataPlane CR
The yaml for deploying this custom resource is given below. This resource is managed by the dataplane operator deployed 
above and it takes care of deploying and managing all Prophecy dataplane components. 

<details><summary>ProphecyDataPlane CR YAML File</summary>
<p>

```
apiVersion: prophecy.simpledatalabs.inc/v1
kind: ProphecyDataPlane
metadata:
  name: dp
spec:
  name: dp
  namespace: dp
  tenant_name: cp
  customer_name: visa
  image_registry_secret: <registry-secret-name>
  team: ""
  disable_fluentbit_sidecar: true
  path-prefix: "/storage"
  spark_execution_provider: databricks
  databricks_url: ""
  databricks_org_id: ""
  databricks_prophecy_jar_path: ""
  databricks_token: ""
  enabledapps: execution,postgres,pkg_manager,sparkhistory
  bootup:
    bootup-volume:
      volumename: nfs-init-pv-cp-dp
  execution:
    image: <execution-image>:latest
    execution_url: https://execution.dp.cp.visa.cloud.prophecy.io
    metagraph_host: metagraph.cp.visa.cloud.prophecy.io
    codegen_host: cgweb.cp.visa.cloud.prophecy.io
    sparkedge_host: sparkedge.cp.visa.cloud.prophecy.io
    metagraph_port: 80
    codegen_port: 80
    sparkedge_port: 80
    # Check why are we passing url like this. It can be accessed on internal network too.
    sparkhistory_url: https://sparkhistory.dp.cp.visa.cloud.prophecy.io
  postgres:
    image: <postgres-image>:latest
    postgres-volume:
      volumename: postgres-volume-cp-dp
    postgres-log-volume:
      volumename: postgres-log-volume-cp-dp
  pkg_manager:
    image: <pkg-manager-image>:latest
  sparkhistory:
    image: <sparkhistory-image>:latest
  externalstorage:
    storagetype: nfs
    storageclassname: nfs
    base-vol-name: cp-dp-shared-vol

```
</p>
</details>

**Note**  
* _An appropriate image path should be passed for respective services in above CR._
* _`volumename` field in sections_ 
    * _bootup.bootup-volume_
    * _postgres.postgres-volume_
    * _postgres.postgres-log-volume_

    _of above CR should be passed with appropriate Persistent volume names as defined during creation of Persistent Volumes._
* _`spec.namespace` value is assumed to be `dp`. This value needs to be changed if dataplane is being deployed in some other namespace._
* _Fields in `spec.execution` like_
    * _execution_url_
    * _metagraph_host_
    * _codegen_host_
    * _sparkedge_host_
    
    _should be passed based on the hostnames provided in ingress resources during this and controlplane deployment._
    
**Things to check** 
* _A custom resource of type `ProphecyDataPlane` is created. `kubectl -n <dataplanenamespace> get ProphecyDataPlane` will tell you the same._

* _Please run `kubectl -n <dataplanenamespace> get deployments`, `kubectl -n <dataplanenamespace> get pods` to verify if we see all the deployments/pods for the apps listed here: https://github.com/SimpleDataLabsInc/onpremdocs#list-of-apps-2._

*  _Please run `kubectl -n <dataplanenamespace> get pvc` to check if there is a pvc created for all the PVs mentioned in this section : https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/dataplane.md#persistent-volumes. Also please verify if they are in bounded state._

* _At this stage you should be able to create fabric in prophecy app GUI and run workflow executions. Please contact Prophecy Support to help you for the same._

Please contact Prophecy Support in case you see problem in any of the above steps. 
