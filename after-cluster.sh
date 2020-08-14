#!/bin/bash
docker pull nginx:1.13 # used by config-serve

# Add images here for them to be available at runtime
# for example:
# docker pull quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.9.0

kubectl config set-context --current --namespace=kube-system
git clone https://github.com/kubernetes-csi/external-snapshotter
kubectl create -f external-snapshotter/config/crd
sed -i -e 's/default/kube-system/g' external-snapshotter/deploy/kubernetes/csi-snapshotter/rbac-csi-snapshotter.yaml
sed -i -e 's/default/kube-system/g' external-snapshotter/deploy/kubernetes/csi-snapshotter/rbac-external-provisioner.yaml
sed -i -e 's/default/kube-system/g' external-snapshotter/deploy/kubernetes/csi-snapshotter/setup-csi-snapshotter.yaml
kubectl create -f external-snapshotter/deploy/kubernetes/csi-snapshotter
# Needed because of this todo: https://github.com/kubernetes-csi/external-snapshotter/blob/master/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml#L13
sed -i -e 's/default/kube-system/g' external-snapshotter/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
sed -i -e 's/default/kube-system/g' external-snapshotter/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
kubectl create -f external-snapshotter/deploy/kubernetes/snapshot-controller
# We also need the corresponding StorageClass and VolumeStorageClass
sed -i -e 's/default/kube-system/g' external-snapshotter/examples/kubernetes/storageclass.yaml
sed -i -e 's/default/kube-system/g' external-snapshotter/examples/kubernetes/snapshotclass.yaml
kubectl create -f external-snapshotter/examples/kubernetes/storageclass.yaml
kubectl create -f external-snapshotter/examples/kubernetes/snapshotclass.yaml
kubectl config set-context --current --namespace=default

# We do not need that repository any longer
rm -rf external-snapshotter

# And because we are lazy, let's install some k8s helper
source /etc/profile
cat <<EOT >> /root/.bashrc
source <(kubectl completion bash)
alias k="kubectl"
complete -F __start_kubectl k
EOT
source ~/.bashrc
