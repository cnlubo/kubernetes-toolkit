<!--
 * @Author: cnak47
 * @Date: 2019-08-19 11:35:12
 * @LastEditors: cnak47
 * @LastEditTime: 2019-08-19 11:57:41
 * @Description:
 -->

# Before you begin

```bash
# macOS
sysctl -a | grep -E --color 'machdep.cpu.features|VMX'
```

If you see VMX in the output (should be colored), the VT-x feature is enabled in your machine.

# Installing minikube

## Install kubectl

Make sure you have kubectl installed. You can install kubectl according to the instructions in Install and Set Up kubectl.

## Install a Hypervisor

If you do not already have a hypervisor installed, install one of these now:

- HyperKit
- VirtualBox
- VMware Fusion

```bash
brew cask install minikube
# You can also install it on macOS by downloading a stand-alone binary:

curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64 && chmod +x minikube
```
