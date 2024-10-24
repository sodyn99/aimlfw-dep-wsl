# ==================================================================================
#
#       Copyright (c) 2022 Samsung Electronics Co., Ltd. All Rights Reserved.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#          http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# ==================================================================================

tools/kubernetes/install_k8s_wsl.sh
tools/helm/install_helm.sh

bin/install_common_templates_to_helm.sh

sudo buildctl --addr=nerdctl-container://buildkitd build \
    --frontend dockerfile.v0 \
    --opt filename=Dockerfile.pipeline \
    --local dockerfile=tools/kubeflow \
    --local context=tools/kubeflow \
    --output type=docker,name=traininghost/pipelineimage:latest | docker load

kubectl create namespace kubeflow
sleep 10
head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8 | kubectl create secret generic leofs-secret -n kubeflow --from-file=password=/dev/stdin

sudo buildctl --addr=nerdctl-container://buildkitd build \
    --frontend dockerfile.v0 \
    --opt filename=Dockerfile.leofs \
    --local dockerfile=tools/leofs \
    --local context=. \
    --output type=docker,name=leofs | docker load

helm dep up helm/leofs
helm install leofs helm/leofs -f RECIPE_EXAMPLE/example_recipe_latest_stable.yaml
sleep 10
NAMESPACE=kubeflow
COMPONENT=leofs
POD_NAME=$(kubectl get pod -l app.kubernetes.io/name=$COMPONENT -n $NAMESPACE -o jsonpath="{.items[0].metadata.name}")
while [[ $(kubectl get pods $POD_NAME -n kubeflow -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for leofs pod" && sleep 1; done

tools/kubeflow/bin/install_kubeflow.sh
kubectl create namespace traininghost
# #copy of secrets to traininghost namespace to enable modelmanagement service to access leofs
# kubectl get secret leofs-secret --namespace=kubeflow -o yaml | sed -e 's/kubeflow/traininghost/g' | kubectl apply -f -

# bin/install_rolebindings.sh
# bin/install_databases.sh
# bin/install.sh -f RECIPE_EXAMPLE/example_recipe_latest_stable.yaml
