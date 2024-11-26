# Azure Virtual Desktop Deployment Pipelines

This repository contains YAML files for automating Azure Virtual Desktop (AVD) deployment. Each pipeline focuses on a specific step in the deployment process, from setting up infrastructure to provisioning session hosts.

## 1. deploy-avd-infrastructure.yaml
This pipeline provisions the foundational Azure infrastructure required for Azure Virtual Desktop, including:

- **Resource Groups**: Creates logical containers for managing AVD-related resources.
- **Host Pools**: Establishes pools for managing session hosts.
- **Networking Components**: Configures virtual networks and subnets to ensure connectivity and security.

## 2. deploy-create-image.yaml
This pipeline automates the creation of a custom virtual machine image tailored for AVD deployments. Key features include:

- Preparing a base image with pre-installed configurations, optimizations, and applications.
- Ensuring compatibility with AVD session hosts.
- Storing the image in a Shared Image Gallery for reuse across deployments.

## 3. deploy-installation-vm.yaml
This pipeline deploys a virtual machine using the custom image created earlier. It supports post-deployment tasks such as:

- Verifying and testing the custom image.
- Installing additional applications or settings that may be required after initial image creation.

## 4. deploy-sessionhost-2022-existing-vnet.yaml
This pipeline deploys Azure Virtual Desktop session hosts running **Windows Server 2022** into an existing virtual network (VNet). Key aspects include:

- Utilizing an existing VNet and subnets for deployment.
- Connecting the session hosts to the appropriate AVD host pool.
- Ensuring seamless integration with existing infrastructure.

## 5. deploy-sessionhost-2022-new-vnet.yaml
This pipeline deploys Azure Virtual Desktop session hosts running **Windows Server 2022** into a virtual network (VNet) that is deployed as part of the IaC Bicep infrastructure. It includes:

- Utilization of the VNet and subnets defined and provisioned during the infrastructure deployment via Bicep templates.
- Deployment of session hosts into the pre-configured VNet.
- Automatic association with the AVD host pool for seamless operation.

This approach ensures consistency between the network infrastructure and the session host deployment while leveraging the existing IaC setup.

## 6. deploy-infra-create_image-deploy_vm.yaml
This pipeline combines multiple steps for end-to-end deployment of AVD, including:

- **Infrastructure Setup**: Provisions resource groups, host pools, and networking components.
- **Custom Image Creation**: Builds and registers a custom VM image in the Shared Image Gallery.
- **Session Host Deployment**: Deploys virtual machines using the custom image into the appropriate environment.

Automates the entire AVD setup process, ensuring a streamlined and consistent deployment.

## 7. deploy-sessionhost-win11-multi-existing-vnet.yaml
This pipeline deploys Azure Virtual Desktop session hosts running **Windows 11 Multi-session** into an existing virtual network (VNet). Key aspects include:

- Utilizing an existing VNet and subnets for deployment.
- Connecting the session hosts to the appropriate AVD host pool.
- Ensuring seamless integration with existing infrastructure.

## 8. deploy-sessionhost-win11-multi-new-vnet.yaml
This pipeline deploys Azure Virtual Desktop session hosts running **Windows 11 Multi-session** into a virtual network (VNet) that is deployed as part of the IaC Bicep infrastructure. It includes:

- Utilization of the VNet and subnets defined and provisioned during the infrastructure deployment via Bicep templates.
- Deployment of session hosts into the pre-configured VNet.
- Automatic association with the AVD host pool for seamless operation.

This approach ensures consistency between the network infrastructure and the session host deployment while leveraging the existing IaC setup.

## Purpose
These pipelines are designed to streamline and automate the deployment and management of Azure Virtual Desktop environments, ensuring consistency, scalability, and efficiency across all stages of the setup process.
