## 1. Set Docker Desktop to use WSL 2

1. Open Docker Desktop
2. Click on the gear icon in the top right corner
3. Click on `Resources`
4. Click on `WSL Integration`
5. Enable the WSL integration for the WSL distro you want to use with Docker Desktop
6. Click `Apply & Restart`

## 2. Enable Kubernetes

1. Open Docker Desktop
2. Click on the gear icon in the top right corner
3. Click on `Kubernetes`
4. Enable Kubernetes
5. Click `Apply & Restart`

## 3. Install aimlfw-dep-wsl

```bash
git clone https://github.com/sodyn99/aimlfw-dep-wsl.git
cd aimlfw-dep-wsl
```

## 4. Deploy AIMLFW

```bash
bin/install_traininghost.sh
```