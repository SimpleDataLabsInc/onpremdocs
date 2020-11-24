# Prophecy Images

This section covers the how-to for downloading prophecy app images. Prophecy app images are hosted in a private Google Container repository at`gcr.io/visa-294603/`.

Prophecy images can be accessed and downloaded with a service account. Please follow the below instructions to setup your docker environment to access prophecy gcr repo.

* Service account key

    Please contact Prophecy Support to get the same and store it in a file. The below instruction assumes the json file is stored as `prophecygcr.json`.
   
* Configure gcloud

   Please run the below command to configure your gcloud CLI for prophecy service account.
   `gcloud auth activate-service-account visa-862@visa-294603.iam.gserviceaccount.com --key-file=./prophecygcr.json`
   
   Note: To setup gcloud, please follow: https://cloud.google.com/sdk/docs/quickstart 
   
* Configure docker

  Please run `gcloud auth configure-docker` command to configure your docker to get associated with gcloud/service account.

* List of images to download

  - gcr.io/visa-294603/app:latest
  - gcr.io/visa-294603/codegenweb:latest
  - gcr.io/visa-294603/dataplane-operator:latest
  - gcr.io/visa-294603/execution:latest
  - gcr.io/visa-294603/gitserver:latest
  - gcr.io/visa-294603/lineageweb:latest
  - gcr.io/visa-294603/metadatagraph:latest
  - gcr.io/visa-294603/pkg-manager:latest
  - gcr.io/visa-294603/postgres-sdl:latest
  - gcr.io/visa-294603/prophecy-operator:latest
  - gcr.io/visa-294603/spark-history:latest
  - gcr.io/visa-294603/sparkedge:latest
  - gcr.io/visa-294603/utweb:latest
  - gcr.io/visa-294603/openidfederator:latest
 
