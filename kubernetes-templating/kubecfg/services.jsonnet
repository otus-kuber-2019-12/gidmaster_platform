local kube = import "https://raw.githubusercontent.com/bitnami-labs/kube-libsonnet/master/kube.libsonnet";

local common(name) = {

  service: kube.Service(name) {
    target_pod:: $.deployment.spec.template,
    metadata+: {
      labels: {
        app: name
      },
    },
  },

  deployment: kube.Deployment(name) {
    metadata+: {
      labels: {
        app: name
      },
    },
    spec+: {
      template+: {
        spec+: {
          containers_: {
            common: kube.Container("common") {
              env: [{name: "PORT", value: "50051"}],
              ports: [{containerPort: 50051}],
              readinessProbe: {
                  initialDelaySeconds: 20,
                  periodSeconds: 15,
                  exec: {
                      command: [
                          "/bin/grpc_health_probe",
                          "-addr=:50051",
                      ],
                  },
              },
              livenessProbe: {
                  initialDelaySeconds: 20,
                  periodSeconds: 15,
                  exec: {
                      command: [
                          "/bin/grpc_health_probe",
                          "-addr=:50051",
                      ],
                  },
              },
              resources: {
                requests: {
                  cpu: "100m",
                  memory: "64Mi",
                },
                limits: {
                  cpu: "200m",
                  memory: "128Mi"
                },
              },
            },
          },
        },
      },
    },
  },
};

{
  catalogue: common("paymentservice") {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            containers_+: {
              common+: {
                name: "server",
                image: "gcr.io/google-samples/microservices-demo/paymentservice:v0.1.3",
              },
            },
          },
        },
      },
    },
  },

  payment: common("shippingservice") {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            containers_+: {
              common+: {
                name: "server",
                image: "gcr.io/google-samples/microservices-demo/shippingservice:v0.1.3",
              },
            },
          },
        },
      },
    },
  },
}