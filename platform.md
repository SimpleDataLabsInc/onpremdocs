# 1. Platform Deployment

Deployment of platform requires installation of global resources and a few namespace scoped resources followed by registration of auth-systems with Prophecy platform -

* Global Resources 
    1. Deploy Persistent Volumes
   
* Namespace Scoped Resources
    1. Deploy a secret to access the image registry.
    2. Deploy Prophecy OpenID federator
    3. Deploy the ingress resource for federator service to be exposed outside the kubernetes cluster and its namespace.
    
* Registration
    1. Register LDAP IDP with Prophecy OpenID federator
    2. Register Prophecy App with Prophecy OpenID federator
    
The above steps have been listed under the following assumptions:
* The underlying kubernetes cluster has an nginx-controller running to manage ingress deployments.
* The k8s cluster has external-dns or something equivalent deployed to create DNS entries for ingress hosts in some DNS zone
* The k8s cluster has cert-manager deployed to automate issuance of renewal of certificates for services being deployed.
* There is an NFS server setup which will be used by Persistent Volume for storage. Also, a path need to be expected to be 
exported on this server - 
    * One export for a persistent volume used by federator to store its configurations.
* There is a dedicated namespace created for platform with name `prophecy`.
* There is a docker image registry setup which has images for all Prophecy services.

Rest of the sections in this document focus on each of the yamls that need to be deployed to get the Prophecy platform 
setup on your cluster. Also, the given yamls assume the namespace name to be `prophecy`. This can be changed as per need.


## Global Resources
This section contains the yaml files for the global resources needed for deployment.

### Persistent Volumes
The yamls for Persistent Volumes creation are provided below. `<nfs-server-ip>` needs to be populated for them to work.
Also, as mentioned above, it is assumed that the namespace name is `prophecy`. 

<details><summary>Persistent Volumes YAML Files</summary>
<p>

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: federator-nfs-pv
  labels:
    prophecy.io/cluster: prophecy
    prophecy.io/component: nfs
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs
  mountOptions:
    - hard
  nfs:
    path: <exported path on nfs server>
    server: <nfs-server-ip>

```
</p>
</details>

**Note**: _These volumes will be referred in persistentvolumeclaim yaml. So, any changes in the names of volumes should 
be made in persistentvolumeclaim too_.

**Things to check**: _Please verify that a volume of 5 GB with with name given in above yaml, and with policy as `Retain` is created with nfs as storage class._


## Namespace scoped Resources
This section contains the yaml files for the namespace scoped resources needed for deployment.

### Secret for Docker image registry

The secret is expected to be created in advance by the infra-admin to provide access to the Docker image registry and 
the same name of the secret is to be passed in Prophecy OpenID Federator deployment yaml. Also, this secret should be deployed in `prophecy` namespace.

### Deployment of Prophecy OpenID Federator
The deployment yaml for Prophecy OpenID Federator is given below.

<details><summary>YAML Files for OpenID Federator</summary>
<p>

```
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: federator-nfs-pvc
spec:
  accessModes:
    - ReadWriteMany
  volumeName: federator-nfs-pv
  resources:
    requests:
      storage: 5Gi
  storageClassName: nfs

---
apiVersion: "v1"
kind: "Service"
metadata:
  name: "openidfederator-service"
  labels:
    prophecy.io/component: "openidfederator"
spec:
  ports:
  - protocol: "TCP"
    port: 5556
    targetPort: 5556
  selector:
    prophecy.io/component: "openidfederator"
  type: "LoadBalancer"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openidfederator
  labels:
    prophecy.io/component: "openidfederator"
spec:
  selector:
    matchLabels:
      prophecy.io/component: "openidfederator"
  template:
    metadata:
      labels:
        prophecy.io/component: "openidfederator"
    spec:
      imagePullSecrets:
      - name: <registry-secret-name>
      containers:
      - name: openidfederator
        image: <prophecy-openid-federator-image>:latest
        imagePullPolicy: Always
        env:
        - name: issuer
          value: http://federator.prophecy.visa.cloud.prophecy.io
        ports:
        - containerPort: 5556
        volumeMounts:
        - mountPath: /etc/openidfederator
          name: federator-nfs-pv
      restartPolicy: Always
      volumes:
      - name: federator-nfs-pv
        persistentVolumeClaim:
          claimName: federator-nfs-pvc
``` 
</p>
</details>

**Note** An appropriate operator image and docker image registry secretname is to be passed in the above yaml.

**Things to check**: _A persistent volume claim, a service and a deployment with a single pod is created with the name mentioned in above yamls._

### Ingress Resources
The yamls for ingress resources for exposing openid federator service outside the K8s cluster are given below.

<details><summary>Ingress YAML Files</summary>
<p>

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    ingress.kubernetes.io/proxy-body-size: 100m
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: 100m
    nginx.ingress.kubernetes.io/rewrite-target: /$1
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.org/client-max-body-size: 100m
  generation: 1
  name: prophecy-openidfederator
  namespace: prophecy
spec:
  rules:
  - host: federator.prophecy.visa.cloud.prophecy.io
    http:
      paths:
      - backend:
          serviceName: openidfederator-service
          servicePort: 5556
        path: /(.*)
        pathType: ImplementationSpecific
```
</p>
</details>

**Things to check** _An ingress with name given in above yaml is created_

## Registration
Admin needs to register their LDAP IDP and Prophecy App(Deployed under controlplane) with OpenID Federator. Prophecy provides a CLI tool, ProCtl and that can be used to register both IDP and App.

### IDP(LDAP) Registration
1. Run proctl and get into proctl shell.
```
./proctl
proctl » 
```
2. Run auth register idp command with input as configfile and federator ingress url.
```
proctl » auth register idp --configfile <absolute path to idp registration yaml> --federatorurl <federator url exposed by ingress yaml>
```
A sample command will look like this:
```
proctl » auth register idp --configfile /Users/visauser/visaldapregistration.yaml --federatorurl http://federator.prophecy.visa.cloud.prophecy.io
Registered IDP with federator
```

Please use below visaldapregistration.yaml, edit the fields to match your ldap configuration and pass the same to 'auth register idp' command.

<details><summary>LDAP Registration YAML File</summary>
<p>

```
connectors:
- type: ldap
  # Required field for connector id.
  id: ldapvisa
  # Required field for connector name.
  name: ldapvisa
  ldapconfig:
    # Host and optional port of the LDAP server in the form "host:port".
    # If the port is not supplied, it will be guessed based on "insecureNoSSL",
    # and "startTLS" flags. 389 for insecure or StartTLS connections, 636
    # otherwise.
    host: ec2-18-217-115-53.us-east-2.compute.amazonaws.com:636

    # Following field is required if the LDAP host is not using TLS (port 389).
    # Because this option inherently leaks passwords to anyone on the same network
    # as openid federator, THIS OPTION MAY BE REMOVED WITHOUT WARNING IN A FUTURE RELEASE.
    #
    insecureNoSSL: false

    # If a custom certificate isn't provide, this option can be used to turn on
    # TLS certificate checks. As noted, it is insecure and shouldn't be used outside
    # of explorative phases.
    #
    insecureSkipVerify: true

    # When connecting to the server, connect using the ldap:// protocol then issue
    # a StartTLS command. If unspecified, connections will use the ldaps:// protocol
    #
    # startTLS: true

    # Path to a trusted root certificate file. Default: use the host's root CA.
    rootCA: /etc/openidfederator/ldap/certs/ca.crt
    clientKey: /etc/openidfederator/ldap/certs/client_key.pem
    clientCert: /etc/openidfederator/ldap/certs/client_cert.pem
    # The DN and password for an application service account. The connector uses
    # these credentials to search for users and groups. Not required if the LDAP
    # server provides access for anonymous auth.
    # Please note that if the bind password contains a `$`, it has to be saved in an
    # environment variable which should be given as the value to `bindPW`.
    bindDN: cn=admin,dc=example,dc=org
    bindPW: ldap123

    # The attribute to display in the provided password prompt. If unset, will
    # display "Username"
    usernamePrompt: Email Address

    # User search maps a username and password entered by a user to a LDAP entry.
    userSearch:
      # BaseDN to start the search from. It will translate to the query
      # "(&(objectClass=person)(uid=<username>))".
      baseDN: ou=People,dc=example,dc=org
      # Optional filter to apply when searching the directory.
      filter: "(objectClass=person)"

      # username attribute used for comparing user entries. This will be translated
      # and combined with the other filter as "(<attr>=<username>)".
      username: mail
      # The following three fields are direct mappings of attributes on the user entry.
      # String representation of the user.
      idAttr: DN
      # Required. Attribute to map to Email.
      emailAttr: mail
      # Maps to display name of users. No default value.
      nameAttr: cn

    # Group search queries for groups given a user entry.
    groupSearch:
      # BaseDN to start the search from. It will translate to the query
      # "(&(objectClass=group)(member=<user uid>))".
      baseDN: ou=Groups,dc=example,dc=org
      # Optional filter to apply when searching the directory.
      filter: "(objectClass=groupOfNames)"

      # Following list contains field pairs that are used to match a user to a group. It adds an additional
      # requirement to the filter that an attribute in the group must match the user's
      # attribute value.
      userMatchers:
        - userAttr: DN
          groupAttr: member

      # Represents group name.
      nameAttr: cn
```
</p>
</details>

**Things to check** _Please check if you get a message `Registered IDP with federator` as an output of above command. In case of error, please contact Prophecy Support_

### Prophecy App Registration
1. Run proctl and get into proctl shell.
```
./proctl
proctl » 
```
2. Run auth register app command with input as configfile and federator ingress url.
```
proctl » auth register app --configfile <absolute path to app registration yaml> --federatorurl <federator url exposed by ingress yaml>
```
A sample command will look like this:
```
proctl » auth register app --configfile /Users/visauser/appregistration.yaml --federatorurl http://federator.prophecy.visa.cloud.prophecy.io
Registered App with federator
```

Please use below appregistration.yaml as it is and pass the same to 'auth register app' command.

<details><summary>App Registration YAML File</summary>
<p>

```
idpid: ldapvisa
apps:
- type: prophecyapp
  # Required field for app id.
  id: visaprophecyapp
  # Required field for app name.
  name: visaprophecyapp
  # Required field for app's secret.
  secret: XXXXX
  redirectURIs:
  - http://0.0.0.0:5555/callback
```
</p>
</details>

**Note**  _The idpid (ldapvisa) used in above appregistration.yaml and visaldapregistration.yaml is same. If you change it at one place, please change it other place as well._

**Things to check** _Please check if you get a message `Registered App with federator` as an output of above command. In case of error, please contact Prophecy Support_
