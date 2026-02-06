# Observability Stack

This folder hosts a complete, self-contained observability stack to help users monitor the health and performance of their AlloyDB Omni fleet. This project includes open-source tooling (e.g., Prometheus, Grafana) pre-configured with dashboards and alerts.

## Architecture

The observability bundle is a single Helm chart (`alloydb-observability`) that deploys:

- **[kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)** - Prometheus, Grafana, AlertManager, and kube-state-metrics
- **[Loki](https://github.com/grafana/loki/tree/main/production/helm/loki)** - Log aggregation
- **[OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector)** - Container log collection and forwarding

```
┌─────────────────────────────────────────────────────────────────────┐
│                    alloydb-observability chart                       │
│                                                                     │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────────────┐    │
│  │  Prometheus   │   │    Grafana    │   │    AlertManager      │    │
│  │  (metrics)    │◀──│  (dashboards) │   │    (email alerts)    │    │
│  └──────┬───────┘   └──────┬───────┘   └──────────┬───────────┘    │
│         │                  │                       │                │
│  ┌──────┴───────┐   ┌──────┴───────┐              │                │
│  │     KSM      │   │     Loki     │◀─────────────┤                │
│  │ (CR metrics) │   │   (logs)     │     ┌────────┴──────────┐     │
│  └──────────────┘   └──────────────┘     │  OTel Collector   │     │
│                                          │  (log forwarding)  │     │
│                                          └───────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
         │                                          │
         ▼                                          ▼
  ┌──────────────────────────────────────────────────────────────┐
  │              AlloyDB Omni DBCluster Fleet                     │
  │  (metrics on port 9187, container logs)                      │
  └──────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Kubernetes cluster (e.g., [kind](https://kind.sigs.k8s.io/))
- [Helm](https://helm.sh/) v3.x
- AlloyDB Omni Kubernetes Operator deployed

### Deploy

```bash
# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Build chart dependencies
cd experimental-tools/observability-stack/samples/alloydb-observability
helm dependency build

# Install the observability bundle
helm install alloydb-o11y . --namespace monitoring --create-namespace

# Access Grafana
kubectl port-forward svc/alloydb-o11y-grafana 3000:80 -n monitoring
# Open http://localhost:3000 (admin / admin)
```

## Pre-Built Dashboards

All dashboards are automatically provisioned in the **AlloyDB Omni** folder in Grafana.

| Dashboard | Description |
|---|---|
| **DBCluster Insights** | Deep-dive into a single DBCluster: CPU, memory, disk I/O, network, storage per disk, PostgreSQL wait events, replication lag and state. |
| **Simple DB Cluster** | Quick health overview: connections, storage, CPU, memory usage %, PostgreSQL up status. |
| **DBCluster Fleet Overview** | Fleet-wide monitoring with Top-K queries: connections per cluster, memory utilization, top clusters by storage/CPU. |
| **DBCluster Operations** | Operational view: primary/HA readiness, failover events and duration, backup/restore status, PgBouncer status, critical incidents. |

Dashboard JSON files are stored separately in `files/dashboards/` and can be imported directly into Grafana UI if needed.

## Pre-Built Alerts

Alerts are defined as PrometheusRule CRDs and are automatically picked up by Prometheus.

| Alert | Severity | Condition |
|---|---|---|
| **AlloyDBOmniHighMemoryUtilization** | critical | Memory usage > 95% for 5+ minutes |
| **AlloyDBOmniHighCPUUtilization** | warning | CPU usage > 90% for 10+ minutes |
| **AlloyDBOmniDiskSpaceLow** | warning | Disk usage > 85% for 5+ minutes |
| **AlloyDBOmniDiskSpaceCritical** | critical | Disk usage > 95% for 5+ minutes |
| **AlloyDBOmniPostgresDown** | critical | PostgreSQL down for 2+ minutes |
| **AlloyDBOmniPrimaryNotReady** | critical | Primary not ready for 5+ minutes |
| **AlloyDBOmniHANotReady** | warning | HA not ready for 10+ minutes |
| **AlloyDBOmniHighReplicationLag** | warning | Replication flush lag > 30s for 5+ minutes |
| **AlloyDBOmniHighReplayLag** | warning | Replication replay lag > 60s for 5+ minutes |
| **AlloyDBOmniCriticalIncident** | critical | Any critical incident reported |
| **AlloyDBOmniHighConnectionCount** | warning | Connection count > 100 for 5+ minutes |

## Configuration

The chart exposes knobs for all underlying components. Override values in `values.yaml` or pass `--set` flags to `helm install`.

### Key Configuration Options

```yaml
# AlloyDB Omni scraping settings
alloydb:
  namespace: alloydb-omni-system    # Where your DBClusters are
  metricsPort: 9187                 # Metrics port
  interval: 25s                     # Scrape interval

# Enable/disable alerts
alerting:
  enabled: true
  email:
    enabled: false                  # Set to true and configure below
    smarthost: "smtp.example.com:587"
    from: "alertmanager@example.com"
    to: "oncall@example.com"

# kube-prometheus-stack overrides (full reference:
# https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml)
kube-prometheus-stack:
  grafana:
    adminPassword: admin

# OpenTelemetry Collector toggle
opentelemetry-collector:
  enabled: true

# Loki toggle
loki:
  enabled: true
```

### Disabling Components

```bash
# Install without Loki and OTel (metrics-only mode)
helm install alloydb-o11y . \
  --namespace monitoring \
  --create-namespace \
  --set opentelemetry-collector.enabled=false \
  --set loki.enabled=false
```

## Standalone Samples

For users who prefer deploying individual components without Helm, standalone manifests are available in the `samples/` directory:

- `samples/prometheus/` - Prometheus deployment and configuration
- `samples/grafana/` - Grafana deployment and dashboard JSONs
- `samples/ksm/` - Kube-State-Metrics with AlloyDB Omni custom resource config

See [`samples/README.md`](samples/README.md) for deployment instructions.

## Cleanup

```bash
helm uninstall alloydb-o11y -n monitoring
kubectl delete namespace monitoring
```
