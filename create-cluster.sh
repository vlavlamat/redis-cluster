#!/bin/bash

echo "Creating Redis cluster..."

yes yes | docker run -i --rm --net redis-cluster-net redis:7.2-alpine \
  redis-cli --cluster create \
  redis-node1:6379 \
  redis-node2:6379 \
  redis-node3:6379 \
  redis-node4:6379 \
  redis-node5:6379 \
  redis-node6:6379 \
  redis-node7:6379 \
  redis-node8:6379 \
  redis-node9:6379 \
  redis-node10:6379 \
  --cluster-replicas 1

echo "Done!"
