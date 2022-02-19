# mirror-openshift-container-platform-operators 

This repository contains helper playbooks to mirror Red Hat Openshift Container Platform operators and create a bundle that can be used in air-gapped or disconnected environments. The playbooks use scripts from two other Red Hat consultants to achieve this.   

The main script from [Arvin Amirian](https://github.com/redhat-cop/openshift-disconnected-operators) is primarily used for the content mirroring, passing in for each operator index being mirrored, the list of operators. This results in pulling the latest operators for the operator index tag passed in and also only the latest operand images being pulled.   

If you need all versions of operand images, you can either use the [role](https://github.com/cadjai/mirror-ocp4-contents-for-artifactory.git), which provides an automation of the steps described in the [official docs](https://docs.openshift.com/container-platform/4.7/operators/admin/olm-managing-custom-catalogs.html) or follow the steps documented in the documentation.   

> **:WARNING: As it currently exists, the steps in the documentation (using the opm tool even with pruning), pull all operand images associated with an operator. That might bring in images that are no longer maintained or for which security vulnerabilities might no longer be remediated.**

**It is therefore recommanded for the time being to use the Arvin based approach, which only brings in the latest version of each operand.** 

To help ready the file system of the pulled images from the above step (using the Arvin script) so that the images can easily be pushed to the destination registry, the second script from [Alex Flom](https://github.com/RedHatGov/openshift-disconnected-operators/blob/master/container/upload.sh) is used to fix the v2 registry file system layout to help push the content into the destination registry.

Originally the playbook pulls operators coming from one index and uses that index for a big bang approach, which simplified the amount of operator indices to track and deploy. 
However, the downside to this is in maintaining and updating operators. When a single operator or a subset of the operators in the index need to be updated, that usually ends up affecting other operators that are part of that index but are not being updated at the moment. 
To solve this, we are switching the approach used by dedicating an index to each operator so that their lifecycle can be maintained separately/independently. The main branch now uses that approach where each of the operators included in the list has its own index named after the operator being mirrored. If for any reason you need to still use the original approach of including all operators coming from the same index with that index, you can checkout the operators-by-index-bundle branch. 

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

> **:WARNING: If while running the mirror-operators.yml playbook you run into "A signature was required but no signatures exists" or "Unable to pull signed images " error, it is due to the container policy on the host (see /etc/containers/policy.json). You can either add the missing signature to the sigstore if you can get it or disable security for that repository using the "'type': 'insecureAcceptAnything'".**


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
The dictionary containing list of operator indices to use to generate full list of operators.    

	operator_registries_to_mirror:  
          redhat-operators:  
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'  
            container_port: '50051'  
            host_port: 50051  
          community-operators:  
            source: 'registry.redhat.io/redhat/community-operator-index:v4.7'  
            container_port: 50051  
            host_port: 40051  
          market-operators:  
            source: 'registry.redhat.io/redhat/redhat-marketplace-index:v4.7'  
            container_port: 50051  
            host_port: 30051  
          certified-operators:  
            source: 'registry.redhat.io/redhat/certified-operator-index:v4.7'  
            container_port: 50051  
            host_port: 20051  
            image_registry: 'registry.connect.redhat.com'

### operators_to_mirror 
Required:   
Default: (see structure below)   
The dictionary containing list of operators to mirror .    

	operators_to_mirror:  
          3scale-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          advanced-cluster-management:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          amq-streams:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          businessautomation-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          cincinnati-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          cluster-kube-descheduler-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          cluster-logging:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          clusterresourceoverride:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          codeready-workspaces:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          compliance-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          container-security-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          costmanagement-metrics-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          elasticsearch-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          file-integrity-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          jaeger-product:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          kiali-ossm:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          local-storage-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          nfd:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          ocs-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          performance-addon-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          ptp-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          rhacs-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          rhsso-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          serverless-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          servicemeshoperator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          web-terminal:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          mtc-operator:
            source: 'registry.redhat.io/redhat/redhat-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          group-sync-operator:
            source: 'registry.redhat.io/redhat/community-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          keycloak-operator:
            source: 'registry.redhat.io/redhat/community-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          namespace-configuration-operator:
            source: 'registry.redhat.io/redhat/community-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          argocd-operator:
            source: 'registry.redhat.io/redhat/community-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          argocd-operator-helm:
            source: 'registry.redhat.io/redhat/community-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          prometheus:
            source: 'registry.redhat.io/redhat/community-operator-index:v4.7'
            start_version: ''
            mirror: "false"
            upgrade: "false"
          prometheus-exporter-operator:
            source: 'registry.redhat.io/redhat/community-operator-index:v4.7'
            start_version: ''
            mirror: "false"
            upgrade: "false"
          jupyterlab-operator:
            source: 'registry.redhat.io/redhat/community-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          anchore-engine:
            source: 'registry.redhat.io/redhat/certified-operator-index:v4.7'
            start_version: ''
            mirror: "false"
            upgrade: "false"
          elasticsearch-eck-operator-certified:
            source: 'registry.redhat.io/redhat/certified-operator-index:v4.7'
            start_version: ''
            mirror: "false"
            upgrade: "false"
          falco-certified:
            source: 'registry.redhat.io/redhat/certified-operator-index:v4.7'
            start_version: ''
            mirror: "false"
            upgrade: "false"
          gitlab-runner-operator:
            source: 'registry.redhat.io/redhat/certified-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          gpu-operator-certified:
            source: 'registry.redhat.io/redhat/certified-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          nginx-ingress-operator:
            source: 'registry.redhat.io/redhat/certified-operator-index:v4.7'
            start_version: ''
            mirror: "false"
            upgrade: "false"
          openshiftartifactoryha-operator:
            source: 'registry.redhat.io/redhat/certified-operator-index:v4.7'
            start_version: ''
            mirror: "false"
            upgrade: "false"
          openshiftpipeline-operator:
            source: 'registry.redhat.io/redhat/certified-operator-index:v4.7'
            start_version: ''
            mirror: "true"
            upgrade: "false"
          openshiftxray-operator:
            source: 'registry.redhat.io/redhat/certified-operator-index:v4.7'
            start_version: ''
            mirror: "false"
            upgrade: "false"
          prisma-cloud-compute-console-operator.v2.0.1:
            source: 'registry.redhat.io/redhat/certified-operator-index:v4.7'
            start_version: ''
            mirror: "false"
            upgrade: "false"
          redhat-marketplace-operator:
            source: 'registry.redhat.io/redhat/certified-operator-index:v4.7'
            start_version: ''
            mirror: "false"
            upgrade: "false"
          rocketchat-operator-certified:
            source: 'registry.redhat.io/redhat/certified-operator-index:v4.7'
            start_version: ''
            mirror: "false"
            upgrade: "false"
          sysdig-certified:
            source: 'registry.redhat.io/redhat/certified-operator-index:v4.7'
            start_version: ''
            mirror: "false"
            upgrade: "false"
        
