# Introduction

![logo](logo.png)

Prophecy application is deployed in three parts:
## [Platform](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/platform.md)
Set of apps responsible for managing authentication
### List of apps
* Federator

## [Control Plane](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/controlplane.md)
Set of apps responsible to serve the core prophecy app. 
### List of apps
* App
* Codegen
* Metagraph
* Gitserver
* Postgres
* Lineage
* Unit test
* Sparkedge
* Bootup manager
* Package manager

## [Data Plane](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/dataplane.md)
Set of apps responsible to manage execution fabric.
### List of apps
* Execution
* Postgres
* Sparkhistory
* Bootup manager
* Package manager

## Architecture Diagram

 ![Architecture](Deploymentvisa.png)
 
## Deployment process
Please follow [Prophecy Images](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/prophecyimages.md) page to download prophecy apps and operator images.

To deploy prophecy application, admin needs to deploy the [Platform](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/platform.md) first, followed by [Controlplane](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/controlplane.md) and then [Dataplane](https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/dataplane.md). Please follow the respective sections to deploy these components.

To update prophecy cluster, please follow [Prophecy Upgrade] (https://github.com/SimpleDataLabsInc/onpremdocs/blob/master/upgrade.md) page.



