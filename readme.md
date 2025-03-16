# Azure Virtual Desktop Deployment Pipelines

This repository contains YAML files for automating Azure Virtual Desktop (AVD) deployment. Each pipeline focuses on a specific step in the deployment process, from setting up infrastructure to provisioning session hosts.

## 1. deploy-avd-infrastructure.yaml  

This pipeline provisions the foundational Azure infrastructure required for Azure Virtual Desktop, including:  

- **Resource Groups**: Creates logical containers for managing AVD-related resources.  
- **Host Pools**: Establishes pools for managing session hosts.  
- **Networking Components**: Configures virtual networks and subnets to ensure connectivity and security.  
- **Shared Image Gallery**: Creates and manages shared images for AVD deployments.  
- **Managed Identities**: Provisions a user-assigned managed identity for secure access to Azure resources.  
- **Image Templates**: Automates the creation and customization of VM images for AVD.  
- **Application Groups**: Sets up desktop or app groups linked to the host pools.  
- **Workspaces**: Configures AVD workspaces to organize application groups.  
- **Storage Accounts**: Creates storage for FSLogix profile containers with proper role assignments.  
- **Availability Sets**: Ensures high availability for VMs in the AVD deployment.  

Each module is configured with dependencies and resource-specific parameters to orchestrate the deployment seamlessly.  

## 2. deploy-create-image.yaml  

This pipeline automates the creation of a custom virtual machine image tailored for Azure Virtual Desktop (AVD) deployments. Key features include:  

- **Preparing a Base Image with Pre-Installed Configurations, Optimizations, and Applications**: The image template used in this pipeline is created as part of the infrastructure deployment in the `deploy-avd-infrastructure.yaml` pipeline. This ensures a standardized base for all images. Any additional application installations, configurations, or system optimizations required for AVD session hosts should be incorporated into the image template during the infrastructure deployment phase. This approach ensures that all images generated through this pipeline adhere to the same baseline standards.  
- **Ensuring Compatibility with AVD Session Hosts**: Configures the image to support the requirements of multi-session environments.  
- **Storing the Image in a Shared Image Gallery for Reuse Across Deployments**: Facilitates version management and centralized access to images.  

This pipeline ensures consistency across deployments by leveraging the foundational image template from the infrastructure setup, while providing flexibility for additional preparation as needed.  

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

## 9. deploy-create-new-image-version.yaml  
This pipeline automates the process of capturing a new version of a virtual machine image, making it ready for reuse in future AVD deployments. Key tasks include:

- **Taking a Snapshot of the VM**: Captures the current state of the installation VM to ensure that it is preserved before sysprep is applied.
- **Sysprep and Capture**: The VM is sysprepped (generalized), and its image is captured for later use. This prepares the VM for redeployment as a clean, generalized image.
- **Sharing to Azure Compute Gallery**: Once the image is captured, it is shared with the Azure Compute Gallery for central management and versioning.
- **Deleting the Installation VM**: After the image has been successfully captured and shared, the installation VM is deleted to clean up resources.

This step ensures that the image is properly versioned, generalized, and stored in the Azure Compute Gallery for consistent deployment across your AVD environments.

## 10. deploy-windows-update-new-version.yaml  
This pipeline automates updating a Windows virtual machine to create a new image version. It includes:

- **Spinning Up a New Machine**: Deploys a fresh VM based on an existing image.
- **Updating Windows**: Installs the latest Windows updates and patches.
- **Snapshotting the VM**: Captures a snapshot of the VM to preserve the updated state.
- **Sysprepping the Machine**: Generalizes the machine using Sysprep for redeployment.
- **Sharing to Azure Compute Gallery**: Publishes the updated image to the Azure Compute Gallery for future use.
- **Cleaning Up Resources**: Deletes temporary resources after the image is successfully stored.

This ensures that AVD session hosts always use the latest patched and optimized Windows images.

---

## Purpose  
These pipelines are designed to streamline and automate the deployment and management of Azure Virtual Desktop environments, ensuring consistency, scalability, and efficiency across all stages of the setup process.
