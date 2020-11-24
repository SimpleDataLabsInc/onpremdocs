#!/usr/bin/env bash

# Avoid putting ':' in filename as kubectl cp gets confused
timestamp=$(date +%d-%b-%y_%H.%M)

POSTGRES_BACKUP_DIR="/backup/postgres/${timestamp}"
GITSERVER_BACKUP_DIR="/backup/gitserver/${timestamp}"

mkdir -p ${POSTGRES_BACKUP_DIR}
mkdir -p ${GITSERVER_BACKUP_DIR}

for i in asp airflow gogs superset exec;
do
  pg_dump -h $PGHOST -p $PGPORT -U $PGUSER -w $i > ${POSTGRES_BACKUP_DIR}/$i.sql;
#  echo `kubectl get ns`
done

## Copy gitserver data..
pods=($(kubectl get pods -o name))
declare -p pods > /dev/null
gitserver_pod=""

for pod in "${pods[@]}"
do
  if [[ $pod =~ pod/gitserver* ]]; then
#    As the $pod itself is of the form pod/<pod_name>. So this removes 'pod/' from $pod
    gitserver_pod=${pod/pod\//}
    break
  fi
done

if [ ! -z $gitserver_pod ]; then
  kubectl cp ${NAMESPACE}/${gitserver_pod}:data -c gitserver ${GITSERVER_BACKUP_DIR}
fi

echo "Backup completed successfully"