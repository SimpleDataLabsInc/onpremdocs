# Introduction

![logo](logo.png)

Prophecy application is deployed in three parts:
* Platform
* Controlplane
* Dataplane

Apart from that, certain ports are expected to be open on machine where the above 
components are running- 
* Platform
    * 5556
* Controlplane
    * 80
    * 9003
    * 9004
    * 9005
* Dataplane
    * 9001
    * 18080
    
## Platform
Set of apps responsible for managing authentication
### List of apps
* Federator

### Platform Deployment
Deployment of platform requires 
* Editing `../platform/.env` to have appropriate host volume paths and image names
* Creation of some volumes on host machine using `../platform/mkdirs.sh`
* Running federator app using `docker-compose -f ../platform/docker-compose.yml --env-file ../platform/.env up -d`


## Control Plane
Set of apps responsible to serve the core prophecy app. 
### List of apps
* App
* Codegen
* Metagraph
* Metadata UI
* Gitserver
* Postgres
* Lineage
* Unit test
* Sparkedge
* Nginx

### Controlplane Deployment
Deployment of controlplane requires 
* Editing `../controlplane/.env` to have appropriate host volume paths and image names
* Creation of some volumes on host machine using `../controlplane/mkdirs.sh`
* Making prophecy jars available in `common-volume`
* Running controlplane apps using `docker-compose -f ../controlplane/docker-compose.yml --env-file ../controlplane/.env up -d`


## Data Plane
Set of apps responsible to manage execution fabric.
### List of apps
* Execution
* Postgres
* Sparkhistory

### Dataplane Deployment
Deployment of dataplane requires 
* Editing `../dataplane/.env` to have appropriate host volume paths, image names and other env variables
* Creation of some volumes on host machine using `../dataplane/mkdirs.sh`
* Making prophecy jars available on `livy server`
* Running dataplane apps using `docker-compose -f ../dataplane/docker-compose.yml --env-file ../dataplane/.env up -d`
