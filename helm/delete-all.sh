#!/bin/bash

set -eux
kubectl delete --all jobs --wait=false
kubectl delete --all pods --wait=false
kubectl delete --all services --wait=false
kubectl delete --all deployments --wait=false
kubectl delete --all statefulsets --wait=false
kubectl delete --all configmaps --wait=false
kubectl delete --all svc --wait=false
kubectl delete --all pvc --wait=false
kubectl delete --all pv --wait=false

while :; do
  n=$(kubectl get pods | wc -l)
  if [[ n -eq 0 ]]; then
    break
  fi
  sleep 5
done

