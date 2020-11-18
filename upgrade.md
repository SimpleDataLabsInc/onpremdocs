# Prophecy Upgrade

This section covers the how-to for upgrading prophecy cluster. Prophecy cluster is distributed among three kubernetes namespaces, prophecy(platform), cp(controlplane) and dp(dataplane). Note that a customer might have multiple controlplanes and dataplanes in their environment depending upon their team structure and how many clusters they want to deploy.

Prophecy upgrade tool can be used to upgrade a particular namespace at a time. Please contact Prophecy Support to get the upgrade tool and run it with the below command:

```
./proupgrade.sh -n <namespace> [--kubeconfig[=]<Path to kubeconfig file>]

```
A sample command, which will upgrade controlplane namespace with latest version will look like this:

```
./proupgrade.sh -n cp --kubeconfig=/User/visauser/prophecykubeconfig.yaml
All the Prophecy services in cp namespace have been upgraded
```
