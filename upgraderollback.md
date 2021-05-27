# Prophecy Upgrade/Rollback
Prophecy cluster can be updated by running a single command of proupgrade.sh tool. Prooupgrade tool supports both version upgrade(update) and version downgrade (rollback) operation, and version number used in command decides if its a upgrade or a downgrade operation.

This section covers the how-to for upgrading prophecy cluster. 

```
./proupgrade.sh -n <namespace> --version <versionno> [--kubeconfig[=]<Path to kubeconfig file>]

```
--kubeconfig is an optional parameter, if not given, tool will use default kubeconfig and k8s cluster.
A sample command, which will upgrade prophecy cluster with the latest version will look like this:

```
./proupgrade.sh -n prophecy --version 0.7.10 --kubeconfig=/User/visauser/prophecykubeconfig.yaml
All the Prophecy services in prophecy namespace have been upgraded
```

Please contact Prophecy Support to get the upgrade tool and run it with the below command: