#!/usr/bin/env bash
optspec=":hn-:"
namespace=""
kubeconfig=""
while getopts "$optspec" optchar; do
    case "${optchar}" in
        -)
            case "${OPTARG}" in
                kubeconfig)
                    val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    kubeconfig=$val
                    ;;
                kubeconfig=*)
                    val=${OPTARG#*=}
                    opt=${OPTARG%=$val}
                    kubeconfig=$val
                    ;;
                *)
                    if [ "$OPTERR" = 1 ]; then
                      val=${OPTARG#*=}
                      opt=${OPTARG%=$val}
                      echo "Unknown option --${opt}" >&2
                      exit 1
                    fi
#                    if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
#                        echo "Unknown option --${OPTARG}" >&2
#                    fi
                    ;;
            esac;;
        h)
          usage='usage: $0 -n <namespace> [-p] [--kubeconfig[=]<Path to kubeconfig file>]
where:
  -n             <string>  Namespace which needs to be upgraded
  --kubeconfig   <string>  Path of the kubeconfig file. (Default is ~/.kube/config)
'
            echo "$usage"
            exit 2
            ;;
        n)
            namespace="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
            ;;
        *)
            if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
                echo "Non-option argument: '-${OPTARG}'" >&2
                exit 1
            fi
            ;;
    esac
done

if [ -z $namespace ]; then
  echo "Error: Required option '-n' is missing. Check './proupgrade.sh -h' for more help."
  exit 1
fi

kctl=kubectl
if [ ! -z $kubeconfig ]; then
  kctl="kubectl --kubeconfig $kubeconfig"
fi


echo "Upgrading the Prophecy platform and operators in $namespace namespace"
pods=($(${kctl} get pods -n ${namespace} -o name))
selected_pods=""
#$kctl delete -n $namespace $(${kctl} get pods -n ${namespace} -o name)

for pod in "${pods[@]}"
do
  if [[ ($pod =~ pod/openidfederator* || $pod =~ pod/.*operator*) ]]; then
#    echo $pod
    $kctl delete -n $namespace $pod
  fi
done

echo "Waiting for platform services and operators to come up"
sleep 10

non_ready_count=-1
while [ $non_ready_count != 0 ]
do
  updated_pods=($(${kctl} get pods -n ${namespace} -o jsonpath='{.items[*].status.containerStatuses[0].ready}'))
  declare -p updated_pods > /dev/null
  non_ready_count=($(grep -o false <<< ${updated_pods[*]} | wc -l))
  echo "Total pending services: $non_ready_count"
  sleep 10
done

echo "All the Prophecy platform services and operators in $namespace namespace have been upgraded"

echo "Upgrading the Prophecy services in $namespace namespace"

deps=($(${kctl} get deployments -n ${namespace} -o name))
selected_deps=""

for dep in "${deps[@]}"
do
  if [[ ! ($dep =~ deployment.apps/bootup* || $dep =~ deployment.apps/.*operator*) && ($dep =~ deployment.apps/.*-prophecy) ]]; then
#    As the $pod itself is of the form pod/<pod_name>
    selected_deps="$selected_deps $dep"
  fi
done

#echo "$kctl delete -n $namespace $selected_deps"
$kctl delete -n $namespace $selected_deps

echo "Waiting for services to come up"
sleep 10

non_ready_count=-1
while [ $non_ready_count != 0 ]
do
  updated_pods=($(${kctl} get pods -n ${namespace} -o jsonpath='{.items[*].status.containerStatuses[0].ready}'))
  declare -p updated_pods > /dev/null
  non_ready_count=($(grep -o false <<< ${updated_pods[*]} | wc -l))
  echo "Total pending services: $non_ready_count"
  sleep 10
done

echo "All the Prophecy services in $namespace namespace have been upgraded"