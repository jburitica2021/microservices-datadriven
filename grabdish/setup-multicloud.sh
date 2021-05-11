#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# The following setup and install of Verrazzano is taken directly from https://verrazzano.io/docs/setup/quickstart/

echo Setting up Verrazzano...
echo Deploying the Verrazzano platform operator...
kubectl apply -f https://github.com/verrazzano/verrazzano/releases/latest/download/operator.yaml
echo Waiting for the deployment to complete...
kubectl -n verrazzano-install rollout status deployment/verrazzano-platform-operator
echo Confirming that the operator pod is correctly defined and running...
kubectl -n verrazzano-install get pods

echo Installing Verrazzano with its dev profile... this will take approximately 20 minutes...
kubectl apply -f - <<EOF
apiVersion: install.verrazzano.io/v1alpha1
kind: Verrazzano
metadata:
  name: example-verrazzano
spec:
  profile: dev
  components:
    dns:
      wildcard:
        domain: nip.io
EOF

echo Waiting for the installation to complete...
kubectl wait \
    --timeout=20m \
    --for=condition=InstallComplete \
    verrazzano/example-verrazzano

#(Optional) View the installation logs...
#kubectl logs -f \
#    $( \
#      kubectl get pod  \
#          -l job-name=verrazzano-install-example-verrazzano \
#          -o jsonpath="{.items[0].metadata.name}" \
#    )

echo Adding labels identifying the msdataworkshop namespace as managed by Verrazzano and enabled for Istio...
kubectl label namespace msdataworkshop verrazzano-managed=true istio-injection=enabled

#echo undeploy any previously deployed microservices... this is not needed unless another workshop using graddish/msdataworkshop was previously deployed
#./undeploy.sh

echo deploy microservices using Verrazzano Open Application Model...
./deploy-multicloud.sh

echo Wait for the application to be ready...
kubectl wait --for=condition=Ready pods --all -n msdataworkshop --timeout=300s

echo Saving the host name of the load balancer exposing the Frontend service endpoints...
#HOST=$(kubectl get gateway hello-helidon-hello-helidon-appconf-gw -n hello-helidon -o jsonpath='{.spec.servers[0].hosts[0]}')
HOST=$(kubectl get gateway frontend-helidon-frontend-helidon-appconf-gw -n hello-helidon -o jsonpath='{.spec.servers[0].hosts[0]}')
echo HOST is ${HOST}

# From https://verrazzano.io/docs/operations/  (see this link to change passwords as well)
# Display information to access various consoles... todo don't display passwords
echo Verrazzano installs several consoles. The ingress for the consoles is the following:
kubectl get ingress -A
echo The Username for Grafana, Prometheus, Kibana, and Elasticsearch consoles is verrazzano and the password is...
kubectl get secret --namespace verrazzano-system verrazzano -o jsonpath={.data.password} | base64 --decode; echo
echo The Username for KeyCloak console is keycloakadmin and the password is...
kubectl get secret --namespace keycloak keycloak-http -o jsonpath={.data.password} | base64 --decode; echo
echo The Username for Rancher console is admin and the password is...
kubectl get secret --namespace cattle-system rancher-admin-secret -o jsonpath={.data.password} | base64 --decode; echo
