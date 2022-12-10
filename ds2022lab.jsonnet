local add = {
  openfaas: {
    serviceMonitorOpenfaas: {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'ServiceMonitor',
      metadata: {
        name: 'openfaas-servicemonitor',
        namespace: 'openfaas',
      },
      spec: {
        jobLabel: 'app',
        endpoints: [
          {
            port: 'http-metrics',
          },
        ],
        selector: {
          matchLabels: {
            app: 'gateway',
          },
        },
      },
    },
  },
};

local update = {
  kubeStateMetrics+: {
    serviceMonitor+: {
      spec+: {
        endpoints: std.map(
          function(endpoint)
            endpoint {
              interval: '5s',
              scrapeTimeout: '5s',
            },
          super.endpoints
        ),
      },
    },
  },
  prometheusAdapter+: {
    serviceMonitor+: {
      spec+: {
        endpoints: std.map(
          function(endpoint)
            endpoint {
              interval: '5s',
            },
          super.endpoints
        ),
      },
    },
  },
};

local kp = (import 'kube-prometheus/main.libsonnet') + add + update;
local kp = (import 'kube-prometheus/main.libsonnet') +
           add +
           update + {
  values+:: {
    common+: {
      namespace: 'monitoring',
    },
    prometheus+: {
      namespaces+: ['openfaas', 'openfaas-fn'],
    },
    grafana+: {
      dashboards+:: {
        'function-dashboard.json': (import 'function-dashboard.json'),
        'logs-fibonacci-dashboard.json': (import 'logs-fibonacci-dashboard.json'),
        'logs-fileapi-dashboard.json': (import 'logs-fileapi-dashboard.json'),
        'logs-matmul-dashboard.json': (import 'logs-matmul-dashboard.json'),
      },
    },
  },
};
{ 'setup/0namespace-namespace': kp.kubePrometheus.namespace } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
} +
// serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
{ 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
{ ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
{ ['openfaas-' + name]: kp.openfaas[name] for name in std.objectFields(kp.openfaas) }
