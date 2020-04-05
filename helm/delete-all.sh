#!/bin/sh

set -eux

kubectl delete --all pv
kubectl delete --all pvc
kubectl delete --all statefulsets
kubectl delete --all deployments
kubectl delete --all services
kubectl delete --all pods
kubectl delete --all jobs

while :; do
  sleep 5
  n=$(kubectl get pods | wc -l)
  if [[ n -eq 0 ]]; then
    break
  fi
done

kubectl delete --all persistentvolumeclaims