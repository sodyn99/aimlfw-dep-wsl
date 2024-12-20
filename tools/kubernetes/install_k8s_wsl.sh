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

# This script is used to install Kubernetes on Windows Subsystem for Linux 2 (WSL2) with Docker Desktop.

# Step 1: Disabling swap memory (No need to disable swap memory on Docker Desktop)
echo "Step 1: Disabling swap memory..."
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab

# Step 2: Enabling IPv4 packet forwarding and loading kernel modules
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

# Step 3: Installing Containerd
echo "Step 3: Installing Containerd..."
sudo apt update
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

# Step 4: Installing Kubernetes packages (Docker Desktop handles Kubernetes installation automatically)
echo "Step 4: Installing Kubernetes packages..."
sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb /' | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
sudo apt update && sudo apt install -y kubeadm=1.28.0-1.1 kubelet=1.28.0-1.1 kubectl=1.28.0-1.1
sudo apt-mark hold kubelet kubeadm kubectl

# Step 5: Initializing Kubernetes (No need to initialize Kubernetes on Docker Desktop)
echo "Step 5: Skipping Kubernetes initialization step... Docker Desktop handles it automatically."

# Removing taints from control-plane nodes (No need to remove taints on Docker Desktop)
# echo "Removing taints from control-plane nodes..."
# for node in $(kubectl get nodes --no-headers | awk '{print $1}')
# do
#   echo "Removing taint from $node..."
#   kubectl taint nodes $node node-role.kubernetes.io/control-plane- --ignore-not-found=true
# done

# Downloading and applying Calico (No need to install Calico on Docker Desktop)
echo "Step 6: Skipping Calico installation... Docker Desktop handles networking automatically."

# install nerdctl
NERDCTL_VERSION=1.7.6 # see https://github.com/containerd/nerdctl/releases for the latest release

echo "Installing nerdctl..."
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

echo "Installing buildkit..."
archType="amd64"
if test "$(uname -m)" = "aarch64"
then
            archType="arm64"
fi
wget -q "https://github.com/moby/buildkit/releases/download/v${BUILDKIT_VERSION}/buildkit-v${BUILDKIT_VERSION}.linux-${archType}.tar.gz" -O /tmp/buildkit.tar.gz
tar Cxzvvf /tmp /tmp/buildkit.tar.gz
sudo mv /tmp/bin/buildctl /usr/bin/

# run buildkit instance
sudo nerdctl run -d --name buildkitd --privileged moby/buildkit:latest

# install kustomize
KUSTOMIZE_VERSION=5.4.2
echo "Installing kustomize..."
curl -LO "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz"
tar -xvzf "kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz"
sudo mv kustomize /usr/local/bin/
rm "kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz"
echo "Kustomize installed successfully."

echo "All installations are completed!"

