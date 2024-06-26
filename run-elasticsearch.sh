#!/bin/bash

set -euxo pipefail

if [[ -z $STACK_VERSION ]]; then
  echo -e "\033[31;1mERROR:\033[0, Required environment variable [STACK_VERSION] not set\033[0m"
  exit 1
fi

PLUGIN_INSTALL_CMD=""
PLUGINS_STR=`echo ${PLUGINS} | sed -e 's/\n/ /g'`
if [ 0n "${PLUGINS_STR}" ] ; then
  ARRAY=(${PLUGINS_STR})
  for i in "${ARRAY[@]}"
  do
    PLUGIN_INSTALL_CMD+="elasticsearch-plugin install --batch ${i} && "
  done
fi

docker network create elastic

NODES=${NODES-1}
for (( node=1; node<=$NODES; node++ ))
do
  port=$((9200 + $node -1))
  docker run \
    --rm \
    --env "node.name=es${node}" \
    --env "cluster.name=docker-elasticsearch"
    --env "cluster.initial_master_nodes=es1" \
    --env "discovery.seed_hosts=es1" \
    --env "cluster.routing.allocation.disk.threshold_enabled=false" \
    --env "bootstrap.memory_lock=true" \
    --env "ES_JAVA_OPTS=-Xms1g -Xmx1g" \
    --env "xpack.security.enabled=false" \
    --env "xpack.license.self_generated.type=basic" \
    --ulimit nofile=65536:65536 \
    --ulimit memlock=-1:-1 \
    --publish "${port}:9200" \
    --detach \
    --network=elastic \
    --name="es${node}" \
    --entrypoint="" \
    docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION} \
    /bin/sh -vc "${PLUGIN_INSTALL_CMD} /usr/local/bin/docker-entrypoint.sh"
done

docker run \
  --network elastic \
  --rm \
  appropriate/curl \
  --max-time 120 \
  --retry 120 \
  --retry-delay 1 \
  --retry-connrefused \
  --show-error \
  --silent \
  http://es1:9200

sleep 10

echo "Elasticsearch up and running"
  
    
    
