# mirror-openshift-container-platform-operators 

This repository contains helper playbooks to mirror Red Hat Openshift Container Platform operators and create a bundle that can be used in air-gapped or disconnected environments. The playbooks use scripts from two other Red Hat consultants to achieve this.   

The main script from [Arvin Amirian](https://github.com/redhat-cop/openshift-disconnected-operators) is primarily used for the content mirroring, passing in for each operator index being mirrored, the list of operators. This results in pulling the latest operators for the operator index tag passed in and also only the latest operand images being pulled.   

If you need all versions of operand images, you can either use the [role](https://github.com/cadjai/mirror-ocp4-contents-for-artifactory.git), which provides an automation of the steps described in the [official docs](https://docs.openshift.com/container-platform/4.7/operators/admin/olm-managing-custom-catalogs.html) or follow the steps documented in the documentation.   

> **:WARNING: As it currently exists, the steps in the documentation (using the opm tool even with pruning), pull all operand images associated with an operator. That might bring in images that are no longer maintained or for which security vulnerabilities might no longer be remediated.**

**It is therefore recommanded for the time being to use the Arvin based approach, which only brings in the latest version of each operand.** 

To help ready the file system of the pulled images from the above step (using the Arvin script) so that the images can easily be pushed to the destination registry, the second script from [Alex Flom](https://github.com/RedHatGov/openshift-disconnected-operators/blob/master/container/upload.sh) is used to fix the v2 registry file system layout to help push the content into the destination registry.

If you need to get an updated list of operators different from the list for the various keys in operator_registries_to_mirror, use the following sample commands:
```
podman run -d --name operator_collector_redhat-operators -p 50051:50051 registry.redhat.io/redhat/redhat-operator-index:v4.7

podman run -d --name operator_collector_redhat-community-operators -p 40051:50051 registry.redhat.io/redhat/community-operator-index:v4.7

podman run -d --name operator_collector_redhat-certified-operators -p 20051:50051 registry.redhat.io/redhat/certified-operator-index:v4.7

podman run -d --name operator_collector_redhat-market-operators -p 30051:50051 registry.redhat.io/redhat/redhat-marketplace-index:v4.7

grpcurl -plaintext localhost:50051 api.Registry/ListPackages > /tmp/operators-list/packages-redhat-operators.out

grpcurl -plaintext localhost:40051 api.Registry/ListPackages > /tmp/operators-list/packages-redhat-community-operators.out

grpcurl -plaintext localhost:20051 api.Registry/ListPackages > /tmp/operators-list/packages-redhat-certified-operators.out

grpcurl -plaintext localhost:30051 api.Registry/ListPackages > /tmp/operators-list/packages-redhat-market-operators.out
```
The generated files contain the name of the operators and you can pick the ones you want for each of the operator index.


## Requirements

It is recommended to look at the source repositories for each of the main scripts for the requirements of that script.  
The playbooks here only require ansible to run. 

## Cloning the repository
1. Use `git clone https://github.com/cadjai/mirror-openshift-container-platform-operators.git` to clone the repository
2. USe `cd mirror-openshift-container-platform-operators && git submodule update --init --recursive` to initialize all submodules
 
## Running the playbooks 
### Mirror operators from the Internet Connected Device
1. Update the vars/registry.yml file to match your environment if necessary
2. Create the vars/vault.yml using the vars/vault.yml.example as template and using `ansible-vault create vars/vault.yml` 
3. Run the playbook using the following command   
   ```
   ansible-playbook mirror-operators.yml --vault-id @prompt -vvv
   ``` 

### Push operators images to the destination registry from a Device with registry API access to the registry
1. Update the vars/registry.yml file to match your environment 
2. Create the vars/vault.yml using the vars/vault.yml.example as template and using `ansible-vault create vars/vault.yml` 
3. Run the playbook using the following command   
   ```
   ansible-playbook push-operators-to-registry.yml --vault-id @prompt -vvv
   ``` 

## Playbook Variables

### openshift_client_binary
Optional:   
Default: '/usr/bin/oc'   
The location of the OpenShift client on the Internet Connected Collection Device if you prefer to use your own installed client.   

### opm_binary
Optional:   
Default: '/usr/bin/opm'   
The location of the opm tool client binary on the Internet Connected Collection Device if you prefer to use your own installed version or want it installed for later use.    

### opm_binary_download_url
Optional:    
Default: 'https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/opm-linux.tar.gz'   
The URL to download the opm client from. Only required if the install_opm is set to true and you want to opm client installed on the host.   

### temp_dir
Optional:   
Default: '/data'   
The temporary location the archive is downloaded into before being installed on the host. Only required if the opm or grpcurl client is being installed for later use.    

### opm_binary_downloaded_artifact
Optional:   
Default: 'opm-linux.tar.gz'   
The name of the opm client archive downloaded to the temp location used for the installation.   

### grpcurl_binary
Optional:   
Default: '/usr/bin/grpcurl'   
The location of the grpcurl tool client binary on the Internet Connected Collection Device. Only required if the pull_all is set to true to pull all operators for each of the indices.   

### grpcurl_binary_download_url
Optional:   
Default: 'https://github.com/fullstorydev/grpcurl/releases/download/v1.8.1/grpcurl_1.8.1_linux_x86_64.tar.gz'   
The URL to download the opm client from. Only required if the install_grpcurl is set to true. Only required if the pull_all is set to true to pull all operators for each of the indices.   

### grpcurl_binary_downloaded_artifact
Optional:   
Default: 'grpcurl_1.8.1_linux_x86_64.tar.gz'   
The name of the grpcurl client archive downloaded to the temp location used for the installation. Only required if the pull_all is set to true to pull all operators for each of the indices.    

### pull_all
Optional:   
Default: 'false'   
The flag used to determine if all operators for each of the operator index are mirrored.   

### registry_host_fqdn
Required:   
The FQDN or IP of the destination registry. This is used by the push-operators-to-registry.yml playbook to push the mirrored operators to the registry.   

### registry_admin_username
Required:   
The username associated to the user used to push the mirrored operators to the destination registry. This is used by the push-operators-to-registry.yml playbook to push the mirrored operators to the registry.   

### registry_admin_password
Required:   
The password associated to the user used to push the mirrored operators to the destination registry. This is used by the push-operators-to-registry.yml playbook to push the mirrored operators to the registry.   

### registry_container_name
Optional:   
Default: mirror-registry   
The name of the container registry used to stage the operator mirror.   

### registry_container_image
Optional:  
Default: 'docker.io/library/registry:2'   
The registry container image used for to stage the mirror process.   

### registry_container_dir
Optional:   
Default: '/data/registry'   
The host directory that is mounted into the container registry to store the operator and operand images pulled into the temp container registry.   

### operator_local_repository
Required:   
The destination repository for all operator and operand images on the destionation registry.   

### default_operator_registry
Optional:   
Default: 'registry.redhat.io'   
The source registry where operators are been pulled from.   

### default_operator_registry_username
Required:   
The username or service account used to pull operators from the default operator registry referenced above.   

### default_operator_registry_password
Required:   
The password associated to the username or service account for the source registry.   

### dir_bundle_location
Optional:   
Default: "/data/bundles"   
The location on the host where the mirrored operator content bundle is stored.    

### bundle_file_name
Optional:   
Default: 'operators-bundle.tar.xz'   
The name of the mirrored operator content bundle.   

### bundle_file_location
Optional:   
Default: "/data/staging/operators-bundle.tar.xz"   
The location on the host used to push the mirrored content to the destination registry.    

### dir_bundle_staging
Optional:   
Default: "/data/staging"   
The staging location where the staging is processed from. The resulting manifests from the pull operation can be found in there.    

### bundle
Optional:   
Default: 'true'   
The flag to indicate if the bundle should be created after the content has been mirrored.    

### unpack_bundle
Optional:   
Default: 'true'   
The flag to indicate if the bundle should be unpacked before being pushed to the destination registry.   

### operator_registries_to_mirror
Optional:   
Default: (see structure below)   
The dictionary containing list of operators to mirror per operator index listed within the dictionary.    

	operator_registries_to_mirror:  
          redhat-operators:  
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'  
            container_port: '50051'  
            host_port: 50051  
            #kubevirt-hyperconverged,sriov-network-operator is beaking the mirroring  
            mirrored_operator_list:
              - name: 3scale-operator
                start_version: ''
              - name: advanced-cluster-management
                start_version: ''
              - name: amq-streams
                start_version: ''
              - name: businessautomation-operator
                start_version: ''
              - name: cluster-kube-descheduler-operator
                start_version: ''
              - name: cluster-logging
                start_version: ''
              - name: clusterresourceoverride
                start_version: ''
              - name: codeready-workspaces
                start_version: ''
              - name: compliance-operator
                start_version: ''
              - name: container-security-operator
                start_version: ''
              - name: elasticsearch-operator
                start_version: ''
              - name: file-integrity-operator
                start_version: ''
              - name: jaeger-product
                start_version: ''
              - name: kiali-ossm
                start_version: ''
              - name: local-storage-operator
                start_version: ''
              - name: nfd
                start_version: ''
              - name: ocs-operator
                start_version: ''
              - name: ptp-operator
                start_version: ''
              - name: rhsso-operator
                start_version: ''
              - name: serverless-operator
                start_version: ''
              - name: servicemeshoperator
                start_version: ''
              - name: web-terminal
                start_version: ''
              - name: mtc-operator
                start_version: ''
              - name: costmanagement-metrics-operator
                start_version: ''
              - name: cincinnati-operator
                start_version: ''
              - name: performance-addon-operator
                start_version: ''
              - name: rhacs-operator
                start_version: ''
            mirror: "true"  
            upgrade: "false"
          community-operators:  
            source: 'registry.redhat.io/redhat/community-operator-index:v4.7'  
            container_port: 50051  
            host_port: 40051  
            mirrored_operator_list:
              - name: group-sync-operator
                start_version: ''
              - name: keycloak-operator
                start_version: ''
              - name: koku-metrics-operator
                start_version: ''
              - name: konveyor-forklift-operator
                start_version: ''
              - name: konveyor-operator
                start_version: ''
              - name: namespace-configuration-operator
                start_version: ''
              - name: prometheus
                start_version: ''
              - name: prometheus-exporter-operator
                start_version: ''
              - name: splunk
                start_version: ''
              - name: argocd-operator
                start_version: ''
              - name: argocd-operator-helm
                start_version: ''
              - name: jupyterlab-operator
            mirror: "true"  
            upgrade: "false"
          market-operators:  
            source: 'registry.redhat.io/redhat/redhat-marketplace-index:v4.7'  
            container_port: 50051  
            host_port: 30051  
            mirrored_operator_list: ""  
            mirror: "false"  
            upgrade: "false"
          certified-operators:  
            source: 'registry.redhat.io/redhat/certified-operator-index:v4.7'  
            container_port: 50051  
            host_port: 20051  
            mirrored_operator_list:
              - name: anchore-engine
                start_version: ''
              - name: elasticsearch-eck-operator-certified
                start_version: ''
              - name: falco-certified
                start_version: ''
              - name: gitlab-runner-operator
                start_version: ''
              - name: gpu-operator-certified
                start_version: ''
              - name: nginx-ingress-operator
                start_version: ''
              - name: node-red-operator-certified
                start_version: ''
              - name: openshiftartifactoryha-operator
                start_version: ''
              - name: openshiftpipeline-operator
                start_version: ''
              - name: openshiftxray-operator
                start_version: ''
              - name: prisma-cloud-compute-console-operator.v2.0.1
                start_version: ''
              - name: redhat-marketplace-operator
                start_version: ''
              - name: rocketchat-operator-certified
                start_version: ''
              - name: splunk-certified
                start_version: ''
              - name: sysdig-certified
                start_version: ''
            mirror: "false"  
            upgrade: "false"
          community-operators:
            source: 'registry.redhat.io/redhat/community-operator-index:v4.8'
            container_port: 50051
            host_port: 40051
            ### konveyor-operator is no longer part of the index 11192021
            mirrored_operator_list:
              - name: group-sync-operator
                start_version: ''
              - name: keycloak-operator
                start_version: ''
              - name: koku-metrics-operator
                start_version: ''
              - name: konveyor-forklift-operator
                start_version: ''
              - name: namespace-configuration-operator
                start_version: ''
              - name: prometheus
                start_version: ''
              - name: prometheus-exporter-operator
                start_version: ''
              - name: splunk
                start_version: ''
              - name: argocd-operator
                start_version: ''
              - name: argocd-operator-helm
                start_version: ''
              - name: jupyterlab-operator
                start_version: ''
            mirror: "true"  
            upgrade: "false"
          jupyterlab-operator:
            source: 'registry.redhat.io/redhat/community-operator-index:v4.7'
            container_port: '50051'
            host_port: 10051
            mirrored_operator_list:
              - name: jupyterlab-operator
                start_version: ''
            mirror: "false"
            upgrade: "false"
