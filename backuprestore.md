# Prophecy Backup Restore
Customers can schedule periodic backup to a NFS server using prophecy backup cron pod. 

## Deployment process for backup pod
Deployment of backup tool requires installing bunch of global resources followed by namespace scoped resources as listed below -
* Global Resources
    1. Deploy Persistent Volume where the data would be backed up.

* Namespace Scoped Resources
    1. Set up roles and permissions for Backup tool to access pods in the dedicated namespace.
    2. Deploy a secret to access the Docker image registry.
    3. Deploy a Persistent Volume Claim corresponding to the Persistent Volume deployed above.
    4. Deploy a Cronjob to run the backup script at certain frequency.
    
The above steps have been listed under the following assumptions:
* There is an NFS server setup which will be used by Persistent Volume for backup. Also, there will be a path 
exported on this server for backup storage. 
* There is a docker image registry setup which has docker images for this backup tool.

Rest of the sections in this document focus on each of the yamls that need to be deployed to get the Prophecy backup tool
setup on your cluster. Also, the given yamls assume the deployment name to be `backup`. This can be changed as per need.


### Global Resources
This section contains the yaml files for the global resources needed for deployment.

#### Persistent Volumes
The yaml for Persistent Volume creation is provided below. `<nfs-server-ip>` needs to be populated for it to work.
Also, as mentioned above, it is assumed that the deployment name is `backup`. 

<details><summary>Persistent Volume YAML File</summary>
<p>

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: backup-volume-prophecy
spec:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 30Gi
  mountOptions:
    - hard
  nfs:
    path: <exported path on nfs server>
    server: <nfs-server-ip>
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs
  volumeMode: Filesystem

```

</p>
</details>

**Note** _This volume will be referred in yaml for Persistent Volume Claim. So, any changes in the name of volume should 
be made in PVC yaml too. Also as mentioned before, `nfs path` for the above yaml needs to be exported in NFS server._

### Namespace scoped Resources
This section contains the yaml files for the namespace scoped resources needed for deployment.

#### Roles, Service Accounts and Role-bindings
The yamls for the creation of role, service-account and role-binding are given below.

<details><summary>Role, Service Account & Role-Binding YAML Files</summary>
<p>

```
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: backup
rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["pods/exec"]
    verbs: ["create"]

---

apiVersion: v1
kind: ServiceAccount
metadata:
  name: backup
  labels:
    name: backup

---

kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: backup
subjects:
  - kind: ServiceAccount
    name: backup
    namespace: prophecy
roleRef:
  kind: Role
  name: backup
  apiGroup: rbac.authorization.k8s.io

```
</p>
</details>

**Note** _The RoleBinding resource assumes namespace `prophecy` for the service account._

#### Secret for Docker image registry

The secret is expected to be created in advance by the infra-admin to provide access to the image registry and 
name of the secret is to be passed in Prophecy Controlplane Operator deployment yaml.

#### Deployment of Persistent Volume Claim
The PVC yaml corresponding to persistent volume deployed is given below.

<details><summary>PVC YAML File</summary>
<p>

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    prophecy.io/component: backup
  name: backup-volume-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs
  volumeMode: Filesystem
  volumeName: backup-volume-prophecy
``` 
</p>
</details>

Note that the `volumeName` in the above yaml should match the name of persistent volume created in above section.

#### CronJob for Backup
The yaml for deploying cronjob for backup tool is given below.

<details><summary>CronJob YAML File</summary>
<p>

```
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: backup
  namespace: prophecy
spec:
  concurrencyPolicy: Forbid
  failedJobsHistoryLimit: 3
  jobTemplate:
    metadata:
      creationTimestamp: null
    spec:
      template:
        metadata:
          creationTimestamp: null
        spec:
          containers:
            - image: <prophecy-backup-tool-image>:latest
              imagePullPolicy: Always
              name: backup
              resources: {}
              env:
                - name: PGUSER
                  value: sdl
                - name: PGHOST
                  value: postgres
                - name: NAMESPACE
                  valueFrom:
                    fieldRef:
                      fieldPath: metadata.namespace
              volumeMounts:
                - mountPath: /backup
                  name: backup-volume
          dnsPolicy: ClusterFirst
          imagePullSecrets:
            - name: <registry-secret-name>
          serviceAccountName: backup
          restartPolicy: OnFailure
          schedulerName: default-scheduler
          securityContext: {}
          terminationGracePeriodSeconds: 30
          volumes:
            - name: backup-volume
              persistentVolumeClaim:
                claimName: backup-volume-pvc
  schedule: "0 1 * * *"
  startingDeadlineSeconds: 120
  successfulJobsHistoryLimit: 1
  suspend: false

```
</p>
</details>

**Note** _An appropriate backup-tool image path and docker image registry secretname should be passed in above yaml file. Also, 
other parameters like `schedule`, `failedJobsHistoryLimit`, etc can be changed as per need._

### OnDemand Backups
On demand backups can be taken using the following command-
```
kubectl create job -n <namespace>  <job-name> --from=cronjob/<backup cronjob name>
```

A sample command assuming the names from above deployment would look like -
```
kubectl create job -n prophecy on-demand-backup --from=cronjob/backup
```

## Deployment process for restore pod
Deployment of restore tool requires access to the persistent volume used by backup cronjob/pod. 
It can use the same Service account as used by backup cronjob/pod. To run restore tool, deployment of following
namespace scoped resources is required - 

* Namespace Scoped Resources
    1. Deploy restore tool deployment yaml to run the restore script.
    
The above steps have been listed under the following assumptions:
* There is a Persistent Volume used for backup that can be shared with restore pod.
* There is a docker image registry setup which has docker images for this restore tool.
* There are roles and permissions setup for backup cronjob which can be used by this restore tool.

Rest of the sections in this document focus on the yamls that need to be deployed to get the Prophecy restore tool
setup on your cluster. Also, the given yamls assume the deployment name to be `restore`. This can be changed as per need.

#### Deployment for Restore
The yaml for restore tool deployment is given below.

<details><summary>Deployment YAML File</summary>
<p>

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: restore
  namespace: prophecy
spec:
  replicas: 1
  selector:
    matchLabels:
      name: restore
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        name: restore
    spec:
      containers:
        - name: restore
          image: <prophecy-restore-tool-image>:latest
          imagePullPolicy: Always
          resources: {}
          env:
            - name: PGUSER
              value: sdl
            - name: PGHOST
              value: postgres
            - name: NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          volumeMounts:
            - mountPath: /backup
              name: backup-volume
      dnsPolicy: ClusterFirst
      imagePullSecrets:
        - name: <registry-secret-name>
      serviceAccountName: backup
      restartPolicy: OnFailure
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
      volumes:
        - name: backup-volume
          persistentVolumeClaim:
            claimName: backup-volume-pvc

```
</p>
</details>

**Note** _An appropriate restore-tool image path and docker image registry secretname should be passed in above yaml file. Also, 
notice that `persistentVolumeClaim.claimName` is same as the one passed in CronJob yaml for backup tool._