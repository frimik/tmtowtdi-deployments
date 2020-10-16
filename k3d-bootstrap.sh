#!/bin/bash
# https://gist.github.com/tom-butler/e512243b29a27878223cd488798e84b0
#
# Tools:
# - k3d - https://github.com/rancher/k3d
# - kustomize - https://kustomize.io/
# - 

#set -o xtrace

SCRIPTNAME=$(basename $0)

CLUSTER_NAME="local"

# Install k3d
#k3d version || wget -q -O - https://raw.githubusercontent.com/rancher/k3d/master/install.sh | bash

# Options not supported yet in k3d v3:
#K3D_OPTIONS="--enable-registry --enable-registry-cache --registry-volume=k3d-registry" # --dns 172.17.0.1"

# traefik gets installed afterwards
k3d cluster create "${CLUSTER_NAME}" \
    --servers 1 \
    --agents 1 \
    --k3s-server-arg='--no-deploy=traefik' \
    --volume "$(pwd)/registries.yaml:/etc/rancher/k3s/registries.yaml" \
    --wait

#echo "# ${SCRIPTNAME}: Replacing 'default' with '$CLUSTER_NAME' in $KUBECONFIG ..."
#sed -i -r "s/(:\s+)default\b/\1${CLUSTER_NAME}/" "${KUBECONFIG}"

kubectl cluster-info

#KUSTOMIZE_FLAGS="--enable_alpha_plugins --load_restrictor none"
#KUSTOMIZE_FLAGS="--enable_alpha_plugins --reorder none"

#kustomize build ${KUSTOMIZE_FLAGS} base/cluster-setup | kubectl apply -f -

# First, init the cluster, including ArgoCD
kustomize build ./k3d-bootstrap | kubectl apply -f -

sleep 5

# second, init the applications
kustomize build ./k3d-bootstrap/apps | kubectl apply -f -

#if [ -d "./overlay/${USER}/cluster_init" ]; then
#    kustomize build ${KUSTOMIZE_FLAGS} overlay/${USER}/cluster_init | kubectl apply -f -
#fi

echo -n "# ${SCRIPTNAME}: Trying to fetch ingress IP. Will give up after 120 attempts."
n=0
until [ $n -ge 120 ]; do
    INGRESS_IP=$(kubectl get service -n ingress traefik -o template --template='{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}')
    if [[ -n "${INGRESS_IP}" ]]; then
        echo " Found: ${INGRESS_IP}."
        break
    fi
    echo -n "."
    sleep 1
done

echo "# ${SCRIPTNAME}: Trying to get all currently existing ingress hosts."
INGRESS_HOSTS=$(kubectl get ingress --all-namespaces --template '{{range .items}}{{range .spec.rules}}{{printf "%s " .host}}{{end}}{{end}}')

echo ""
echo "# ${SCRIPTNAME}: Add (at least) the following to your /etc/hosts file!"
echo "${INGRESS_IP} ${CLUSTER_NAME}.kube ${INGRESS_HOSTS}"
echo ""

ARGO_POD="$(kubectl get pod -n argocd -l app.kubernetes.io/name=argocd-server -o=name)"
echo "# ${SCRIPTNAME}: Argo Pod name is: '${ARGO_POD/pod\//}'. If this is the first run, this is the argo-cd admin password."
echo "Change the password by running:"
echo "argocd login grpc.argocd.kube --username admin --password ${ARGO_POD//pod\//} --insecure --plaintext"
echo "argocd account update-password --current-password ${ARGO_POD//pod\//}"