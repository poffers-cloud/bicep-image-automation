# Azure Virtual Desktop Deployment Pipelines

This repository contains YAML files for automating Azure Virtual Desktop (AVD) deployment:

- **deploy-avd-infrastructure.yaml**: Sets up AVD infrastructure, including host pools and resource groups.
- **deploy-create-image.yaml**: Creates a custom VM image for AVD.
- **deploy-vm.yaml**: Create virtual machine based on the custom image.
- **deploy-infra-create_image-deploy_vm.yaml**: Combines infrastructure deployment, image creation, and VM provisioning.

These pipelines streamline AVD setup and management