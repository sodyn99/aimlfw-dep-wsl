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

check_status() {
    if [ $? -eq 0 ]; then
        echo -e "\e[32m✓ $1 successful\e[0m"
    else
        echo -e "\e[31m✗ $1 failed\e[0m"
        exit 1
    fi
}

echo "Step 1: Disabling swap memory..."
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab

echo "Step 2: Enabling IPv4 packet forwarding and loading kernel modules..."
echo -e "overlay\nbr_netfilter" | sudo tee /etc/modules-load.d/k8s.conf > /dev/null
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf > /dev/null
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
check_status "Enabling IPv4 packet forwarding and loading kernel modules"

echo "Step 3: Installing Containerd..."
sudo apt update
sudo apt install -y containerd
check_status "Installing containerd"

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
check_status "Configuring and restarting containerd"

echo "Step 4: Downloading and installing minikube..."

sudo apt update && sudo apt install -y conntrack containernetworking-plugins apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb /' | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
sudo apt update && sudo apt install -y kubeadm=1.28.0-1.1 kubelet=1.28.0-1.1 kubectl=1.28.0-1.1
sudo apt-mark hold kubelet kubeadm kubectl
echo 'source <(kubectl completion bash)' >> ~/.bashrc

check_status "Installing kubeadm, kubelet, and kubectl"

VERSION="v1.28.0"
curl -LO https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm crictl-$VERSION-linux-amd64.tar.gz
check_status "Installing crictl"

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
echo 'source <(minikube completion bash)' >> ~/.bashrc
check_status "Installing minikube"

echo "Step 5: Starting minikube..."
# minikube start --driver=none --container-runtime=containerd --kubernetes-version=v1.28.0 \
#     --apiserver-ips 127.0.0.1 --apiserver-name localhost \
#     --addons=nvidia-device-plugin \
#     --cni=flannel
# check_status "Starting minikube"
minikube start --driver=docker --container-runtime=containerd --kubernetes-version=v1.28.0 \
    --apiserver-ips 127.0.0.1 --apiserver-name localhost \
    --addons=nvidia-device-plugin \
    --cni=flannel
check_status "Starting minikube"

echo "Kubernetes cluster started with minikube using containerd!"

# install nerdctl
NERDCTL_VERSION=1.7.6 # see https://github.com/containerd/nerdctl/releases for the latest release

archType="amd64"
if test "$(uname -m)" = "aarch64"
then
    archType="arm64"
fi

wget -q "https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-${archType}.tar.gz" -O /tmp/nerdctl.tar.gz
sudo tar Cxzvvf /usr/bin /tmp/nerdctl.tar.gz

echo "Installation completed for nerdctl!"

# install buildkit
BUILDKIT_VERSION=0.13.2 # see https://github.com/moby/buildkit/releases for the latest release

wget -q "https://github.com/moby/buildkit/releases/download/v${BUILDKIT_VERSION}/buildkit-v${BUILDKIT_VERSION}.linux-${archType}.tar.gz" -O /tmp/buildkit.tar.gz
tar Cxzvvf /tmp /tmp/buildkit.tar.gz
sudo mv /tmp/bin/buildctl /usr/bin/
check_status "Installing buildkit"

# run buildkit instance
sudo nerdctl run -d --name buildkitd --privileged moby/buildkit:latest
check_status "Running buildkitd instance"

# install kustomize
KUSTOMIZE_VERSION=5.4.2
curl -LO "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz"
tar -xvzf "kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz"
sudo mv kustomize /usr/local/bin/
rm "kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz"
check_status "Installing kustomize"

echo "Kustomize installed successfully."
