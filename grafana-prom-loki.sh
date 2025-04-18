#!/bin/bash

# Create namespace
kubectl create namespace monitoring || true

# Add helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Loki stack (loki + promtail)
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set loki.enabled=true,promtail.enabled=true

# Install kube-prometheus-stack with Grafana, Prometheus, Alertmanager
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f ./custom_kube_prometheus_stack.yml
