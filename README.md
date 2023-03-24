# mirror-openshift-container-platform-operators 

This repository contains helper playbooks to mirror Red Hat Openshift Container Platform operators (as well as OCP payload, adhoc images and helm charts) and create a bundle that can be used in air-gapped or disconnected environments. 

Originally the playbooks used scripts from two other Red Hat consultants to achieve this. These can still be found under the apppropriate branches or within v3 tags. 
The playbooks are been updated to start using the supported oc-mirror binary but anyone who still want to use the old playbooks can checkout the appropriate branches or tags referenced above. 

   
> **:WARNING: This is a new version of the repo which nows uses the the oc-mirror tool as the default tool. Please use the other braches if you still need the old approach.**


There are several solutions to how to mirror content for disconnected/airgapped environments.
We have used various approaches but oc-mirror is the new supported binary provided and suported by Red Hat. We are switching to using that so that we don't have to maintain custom scripts.

Out of box when the binary is used with a single imageset config file to mirror the various types of content it supports and most importantly for operators, a single ImageContentSourcePolicy (ICSP) is generated for all operators and they all share the same index. One of the issues we were faced with was scanning of the bundle and separating out some of the operators that might violate threshholds set by the security teams at various organizations, which was causing unnecessary amount of rework since the bundle usually contains everything.  
To work around that problem using our previous approach, we were able to mirror a single operator and customize the index to be dedicated to the single operator to make it easy to exclude operators that were not passing the vulnerability threshhold. That is one of the key goals of the playbooks used here to enable replicating that same approach and make it easy to exclude operators without worrying about how to handle the all encompassing index. 

The oc-mirror tool allows some customization of the catalog and that is the key feature used here to enable dedicating a custom index to a single operator. The gist of the workaround is to use an imageset config per operator if one choses to go that route. To make things easy we are using a dictionary variable for the operators to mirror and some automation (Ansible) is used to create the imageset config file for each operator. More details will be provided below.  

On the other hand if we stick with the main way the binary is used , we can still use the same playbooks to mirror the content as well as push it to the destination registry.   
In addition, the playbooks will retrieve the appropriate manifests (ICSP, catalogsource and mapping.txt) so that they can be used to deploy the various items to the various clusters.

The playbooks by default allow running the oc-mirror command against multiple content types.

However, the workflow we are chosing to implement here is to use the same type of content imageset files (ocp release, operators, adhoc images or helm) during each run to keep it simple and consistent.  

To use this approach, make sure you have the oc-mirror binary installed on the content mirror host and also available on the bastion used to push the mirrored content to the destination registries, unless you want to push using the mapping file, which can be done using the previous approach (see older branches for existing push playbooks).  

The binary can be downloaded from [the Red Hat oc-mirror client page](https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/oc-mirror.tar.gz) and transferred alongside other mirrored content to the various environments it is to be used in .  
Once the binary is downloaded, installed, configured and made available on your path, navigate to the directory containing the playbooks; once you mirror the repo in order to start the process using the following steps.

### Mirror operators using the single operator index approach

#### Single Operator content Mirror
1. Update the `imageset_config_files_to_create` variable in the `content-mirror.yml` variable file to reflect the operators you want to mirror for which the imageset config file will be created and used to mirror the content for each operator into a single tar archive with the operator name. You will also need to update the `manifests_dir`, `imageset_config_files_dir` and  any other variables as appropriate. You can use your editor of choice to edit the file like in the example below using `vi`.

```bash
vi ../vars/content-mirror.yml
```

2. Mirror the operators using the `mirror-content-using-oc-mirror.yml` playbook passing in the appropriate arguments like below .
```bash
 ansible-playbook --ask-vault-pass -vvv mirror-content-using-oc-mirror.yml
```
The outcome of the above playbook is the creation of several tar archives (one for each of the operator listed in the `imageset_config_files_to_create` variable above).
Those archives are ready to be pushed to the appropriate registries and repositories as well as cross domained to the appropriate air-gapped fabrics.

#### Single Operator content Push to the repository
Similar to how we mirrored the operators above, we will need to update the appropriate variables and then run the appropriate playbook to push the content to the destination repository using the steps below
1. Update the appropriate variables to use to push the right bundles to the registry.
If you still have the imageset config files generated during the content mirror step, you can use those by updating the value of `imageset_config_files` variable to reflect the location of the files. If not you can also use the `imageset_config_files_dir` variable in the `content-mirror.yml` variable file to reflect the location of the imageset config files related to the operators you want to push.  

> :warning: Note that the `imageset_config_files` variable takes precedence and if defined and populated will be used. If not the files are loaded from the `imageset_config_files_dir`.

Edit the variable file using any editor like done below using 'vi`.
```bash
vi ../vars/content-mirror.yml
vi ../vars/registry.yml
```
The registry.yml file might also need to be edited to reflect the right registry and repository combination.

2. Push the operators to the registry using the `push-content-using-oc-mirror.yml` playbook passing in the appropriate arguments like below .
```bash
 ansible-playbook --ask-vault-pass -vvv push-content-using-oc-mirror.yml
```
The outcome of the above playbook is the push of the operators from the various tar archives to the specified registry and repository and the creation of several manifests retrived from the tar archives or created (the catalogsource file is not part of the archive and is created based on a jinja 2 template) based on the information passed via the variaous variable files edited above .
Those manifests can be committed and  ready to be used to deploy the operators to the appropriate clusters.


### Mirror operators or any other content using the oc-mirror with its default configuration
As stated above the oc-mirror can be used to mirror a wide variety of content (operators, ocp release images, adhoc container images and helm charts).   
To make things simpler for us we chose a workflow where the playbook is run for the same content type where the content type is defined by the imageset config files used to run the playbooks. 
Instead of having an imageset config file that has operators, ocp release, additional images and helm charts, we are chosing to create an imageset file for each content type to match the lifecycle of how each of the content type is mirrored into the environment. Also the key difference between this approach and the previous one above for operators using a dedicated index is that the imageset config files are the expected inputs to this process instead of the playbook creating them based on some defined variable.  
So the steps below will be the same for all content type and the only change will be the value of the variable pointing to the appropriate imageset config files to use.


#### Mirror and Push Operators content

##### Mirror Operators content

1. Update the `imageset_config_files` variable in the `content-mirror.yml` variable file to reflect the location of the imageset config file container the list of operators to mirror.
2. Ensure the `imageset_config_files_to_create` variable is commented out so that the playbook does not missinterpret the intent.
3. Update the `dir_bundle_location` variable in the `registry.yml` variable file to reflect the location of the operator bundle to be created .
4. Update the imageset config file (a default file is named `operators-imageset-config.yaml` under the `manifests` directory ) to reflect the list of operators you are mirroring. Some of the value to set are the the name of the channel, the min and max version for each operator. If needed you can set the targetName and targetTag to provide a custom name and tag for the index.
For more information about the configuration options available to configure the imageset config file [refer to the oc-mirror official documentation](https://docs.openshift.com/container-platform/4.12/installing/disconnected_install/installing-mirroring-disconnected.html) .   
> :warning: !!! Note that since the index here contains all the operators on the list that belong under that index, removing one would mean that the mirrored index will not contain that operator once deployed.

5. Mirror the operators using the `mirror-content-using-oc-mirror.yml` playbook passing in the appropriate arguments like below .  
```bash
 ansible-playbook --ask-vault-pass -vvv mirror-content-using-oc-mirror.yml
```
The outcome of the above playbook is the creation of a single tar archive for all the operators in the imageset config file provided in the `imageset_config_files` variable above. Note that the archive in this case will have the name of the imageset config file provided without the extension.
The archive is ready to be pushed to the appropriate registries and repositories as well as cross domained to the appropriate air-gapped fabrics.  


##### Push Operators content
This use case assumes that the bundle is being pushed directly to the destination registry.

The original playbooks being replaced had a use case (not covered here) where the operators can be pushed to a temporary container registry for extra handling and then pushed from there to the destination registry. These playbooks can be run similarly but what is described below will not cover that use case.   

1. Update the appropriate variables to use to push the operator bundle created above to the registry.
   - Update the `imageset_config_files` variable in the `content-mirror.yml` variable file to reflect the location of the imageset config file container the list of operators to mirror.
   - Set `operator_content_type` variable to `true` in the `content-mirror.yml` variable file. This is so that the extra manifests related to operators are processed.
   - Update the `dir_bundle_location` variable in the `registry.yml` variable file to reflect the location of the operator bundle created during the mirror step. Other variables that can be updated are `operator_local_repository` and `registry_host_fqdn` if necessary.
Edit the variable file using any edit like the one below.
```bash
vi ../vars/content-mirror.yml
vi ../vars/registry.yml
```

2. Push the operators to the registry using the `push-content-using-oc-mirror.yml` playbook passing in the appropriate arguments like below .
```bash
 ansible-playbook --ask-vault-pass -vvv push-content-using-oc-mirror.yml
```
The outcome of the above playbook is the push of the operators from the operator tar archive to the specified registry and repository and the creation of several manifests retrieved from the tar archive or created (the catalogsource file is not part of the archive and is created based on a jinja 2 template) based on the information passed via the various variable files edited above .   
Those manifests can be committed and are ready to be used to deploy the operators to the appropriate clusters.


##### Mirror OCP Release content

1. Update the `imageset_config_files` variable in the `content-mirror.yml` variable file to reflect the location of the imageset config file containing the OCP relase to mirror.
2. Ensure the `imageset_config_files_to_create` variable is commented out so that the playbook does not missinterpret the intent.
3. Update the `dir_bundle_location` variable in the `registry.yml` variable file to reflect the location of the OCP release bundle to be created .
4. Update the imageset config file (a default file is named `ocp-imageset-config.yaml` under the `manifests` directory ) to reflect the release you are mirroring. Some of the value to set are the the name of the channel, the min and max version and shortest path. You should also ensure that `graph` attribute is set to true to ensure the graph image is included .
For more information about the configuration options available to configure the imageset config file [refer to the oc-mirror official documentation](https://docs.openshift.com/container-platform/4.12/installing/disconnected_install/installing-mirroring-disconnected.html) .
5. Mirror the OCP release bundle using the `mirror-content-using-oc-mirror.yml` playbook passing in the appropriate arguments like below .
```bash
 ansible-playbook --ask-vault-pass -vvv mirror-content-using-oc-mirror.yml
```
The outcome of the above playbook is the creation of a single tar archive for all the images included in the OCP releases payload based on the releases listed in the imageset config file provided in the `imageset_config_files` variable above.  
Note that the archive in this case will have the name of the imageset config file provided without the extension.  
The archive is ready to be pushed to the appropriate registries and repositories as well as cross domained to the appropriate air-gapped fabrics.


##### Push OCP Release content

1. Update the appropriate variable to use to push the OCP release bundle created above to the registry.
   - Update the `imageset_config_files` variable in the `content-mirror.yml` variable file to reflect the location of the imageset config file containing the list of OCP releases that were mirrored.
   - Set `operator_content_type` variable to `false` in the `content-mirror.yml` variable file (or remove it). There is no need to create a catalogsource when dealing with OCP release images.
   - Update the `dir_bundle_location` variable in the `registry.yml` variable file to reflect the location of the OCP release bundle created during the mirror step. Other variables that can be updated are `operator_local_repository` and `registry_host_fqdn` if necessary.
Edit the variable file using any editor like done below using `vi`.
```bash
vi ../vars/content-mirror.yml
vi ../vars/registry.yml
```
2. Push the OCP release images to the registry using the `push-content-using-oc-mirror.yml` playbook passing in the appropriate arguments like below .
```bash
 ansible-playbook --ask-vault-pass -vvv push-content-using-oc-mirror.yml
```
The outcome of the above playbook is the push of the OCP release images from the release bundle tar archive to the specified registry and repository and the creation of ImageContentSourcePolicy and mapping.txt file .   
Those manifests can be committed and are ready to be used to deploy the operators to the appropriate clusters.


##### Mirror adhoc/additional image content

1. Update the `imageset_config_files` variable in the `content-mirror.yml` variable file to reflect the location of the imageset config file containing the list of additional/adhoc container images to mirror.
2. Ensure the `imageset_config_files_to_create` variable is commented out so that the playbook does not missinterpret the intent.
3. Update the `dir_bundle_location` variable in the `registry.yml` variable file to reflect the location of the addtional images bundle to be created .
4. Update the imageset config file (a default file is named `adhoc-imageset-config.yaml` under the `manifests` directory ) to reflect the list of additional imags you are mirroring. Here you can also block images that might be problematic or causing some issues during mirroring process.
For more information about the configuration options available to configure the imageset config file [refer to the oc-mirror official documentation](https://docs.openshift.com/container-platform/4.12/installing/disconnected_install/installing-mirroring-disconnected.html) .
5. Mirror the additional images bundle using the `mirror-content-using-oc-mirror.yml` playbook passing in the appropriate arguments like below .
```bash
 ansible-playbook --ask-vault-pass -vvv mirror-content-using-oc-mirror.yml
```
The outcome of the above playbook is the creation of a single tar archive for all the images included in the adhoc/additional image bundle based on the images listed in the imageset config file provided in the `imageset_config_files` variable above.   
Note that the archive in this case will have the name of the imageset config file provided without the extension.  
The archive is ready to be pushed to the appropriate registries and repositories as well as cross domained to the appropriate air-gapped fabrics.


##### Push adhoc/additional image content

1. Update the appropriate variable to use to push the additional bundle created above to the registry.
   - Update the `imageset_config_files` variable in the `content-mirror.yml` variable file to reflect the location of the imageset config file containing the list of additional images that were mirrored.
   - Set `operator_content_type` variable to `false` in the `content-mirror.yml` variable file (or remove it). There is not need to create a catalogsource when dealing with OCP release images.
   - Update the `dir_bundle_location` variable in the `registry.yml` variable file to reflect the location of the additional image bundle created during the mirror step. Other variables that can be updated are `operator_local_repository` and `registry_host_fqdn` if necessary.
Edit the variable file using any editor like done below using `vi`.
```bash
vi ../vars/content-mirror.yml
vi ../vars/registry.yml
```
2. Push the additional images to the registry using the `push-content-using-oc-mirror.yml` playbook passing in the appropriate arguments like below .
```bash
 ansible-playbook --ask-vault-pass -vvv push-content-using-oc-mirror.yml
```
The outcome of the above playbook is the push of the additonal images from the bundle tar archive to the specified registry and repository and the creation of ImageContentSourcePolicy and mapping.txt file .   
Those manifests can be committed and are ready to be used to deploy the operators to the appropriate clusters.


##### Mirror helm charts

1. Update the `imageset_config_files` variable in the `content-mirror.yml` variable file to reflect the location of the imageset config file containing the list of helm charts to mirror.
2. Ensure the `imageset_config_files_to_create` variable is commented out so that the playbook does not missinterpret the intent.
3. Update the `dir_bundle_location` variable in the `registry.yml` variable file to reflect the location of the helm charts bundle to be created .
4. Update the imageset config file (a default file is named `helm-imageset-config.yaml` under the `manifests` directory ) to reflect the list of helm charts you are mirroring.
For more information about the configuration options available to configure the imageset config file [refer to the oc-mirror official documentation](https://docs.openshift.com/container-platform/4.12/installing/disconnected_install/installing-mirroring-disconnected.html) .
5. Mirror the additional images bundle using the `mirror-content-using-oc-mirror.yml` playbook passing in the appropriate arguments like below .
```bash
 ansible-playbook --ask-vault-pass -vvv mirror-content-using-oc-mirror.yml
```
The outcome of the above playbook is the creation of a single tar archive for all the images included in the adhoc/additional image bundle based on the images listed in the imageset config file provided in the `imageset_config_files` variable above.   
Note that the archive in this case will have the name of the imageset config file provided without the extension.   
The archive is ready to be pushed to the appropriate registries and repositories as well as cross domained to the appropriate air-gapped fabrics.


##### Push helm charts 

1. Update the appropriate variable to use to push the helm charts bundle created above to the repository.
   - Update the `imageset_config_files` variable in the `content-mirror.yml` variable file to reflect the location of the imageset config file containing the list of additional images that were mirrored.
   - Set `operator_content_type` variable to `false` in the `content-mirror.yml` variable file (or remove it). There is not need to create a catalogsource when dealing with helm charts.
   - Update the `dir_bundle_location` variable in the `registry.yml` variable file to reflect the location of the helm charts bundle created during the mirror step. Other variables that can be updated are `operator_local_repository` and `registry_host_fqdn` if necessary.
Edit the variable file using any editor like done below using `vi`.
```bash
vi ../vars/content-mirror.yml
vi ../vars/registry.yml
```

2. Push the helm charts to the repository using the `push-content-using-oc-mirror.yml` playbook passing in the appropriate arguments like below .
```bash
 ansible-playbook --ask-vault-pass -vvv push-content-using-oc-mirror.yml
```
The outcome of the above playbook is the push of the helm charts from the bundle tar archive to the specified repository .    
Those manifests can be committed and are ready to be used to deploy the operators to the appropriate clusters.


## Requirements

It is recommended to look at the official documentation for the [oc-mirror binary](https://docs.openshift.com/container-platform/4.12/installing/disconnected_install/installing-mirroring-disconnected.html) for the requirements of that binary.  
The playbooks here only require ansible to run. 

## Cloning the repository
1. Use `git clone https://github.com/cadjai/mirror-openshift-container-platform-operators.git` to clone the repository
2. USe `cd mirror-openshift-container-platform-operators` to change directory into the playbook directory from where to run the playbooks 
 
## Running the playbooks 
See various sections above covering the various use cases. 


## Playbook Variables


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

### imageset_config_files_to_create 
Optional:   
Default: (see structure below)   
The dictionary containing list of operators to mirror .    

	imageset_config_files_to_create:
          advanced-cluster-management:
            src_index: 'registry.redhat.io/redhat/redhat-operator-index:v4.10'
            channel: 'release-2.7'
            min_version: ''
            max_version: ''
          amq-streams:
            src_index: 'registry.redhat.io/redhat/redhat-operator-index:v4.10'
            channel: 'stable'
            min_version: ''
            max_version: ''
          businessautomation-operator:
            src_index: 'registry.redhat.io/redhat/redhat-operator-index:v4.10'
            channel: 'stable'
            min_version: ''
            max_version: ''
          cincinnati-operator:
            src_index: 'registry.redhat.io/redhat/redhat-operator-index:v4.10'  
            channel: 'stable'
            min_version: ''
            max_version: ''

### imageset_config_files 
Optional:   
Default: (see structure below)   
The list containing list of imageset config files to use  .    

	imageset_config_files:
          - "manifests/advanced-cluster-management-imageset-config.yml"
          - "manifests/amq-streams-imageset-config.yml"
          - "manifests/businessautomation-operator-imageset-config.yml"
          - "manifests/cincinnati-operator-imageset-config.yml"
          - "manifests/cluster-kube-descheduler-operator-imageset-config.yml"
          - "manifests/cluster-logging-imageset-config.yml"
          - "manifests/clusterresourceoverride-imageset-config.yml"
          - "manifests/codeready-workspaces-imageset-config.yml"
          - "manifests/compliance-operator-imageset-config.yml"
          - "manifests/container-security-operator-imageset-config.yml"
          - "manifests/costmanagement-metrics-operator-imageset-config.yml"
          - "manifests/devspaces-imageset-config.yml"
          - "manifests/devworkspace-operator-imageset-config.yml"
          - "manifests/elasticsearch-operator-imageset-config.yml"
          - "manifests/file-integrity-operator-imageset-config.yml"
          - "manifests/jaeger-product-imageset-config.yml"
          - "manifests/kiali-ossm-imageset-config.yml"
          - "manifests/local-storage-operator-imageset-config.yml"
          - "manifests/nfd-imageset-config.yml"
          - "manifests/ocs-operator-imageset-config.yml"
          - "manifests/openshift-pipelines-operator-rh-imageset-config.yml"
          - "manifests/openshift-gitops-operator-imageset-config.yml"
          - "manifests/performance-addon-operator-imageset-config.yml"
          - "manifests/ptp-operator-imageset-config.yml"
          - "manifests/redhat-oadp-operator-imageset-config.yml"
          - "manifests/rhacs-operator-imageset-config.yml"
          - "manifests/rhpam-kogito-operator-imageset-config.yml"
          - "manifests/rhsso-operator-imageset-config.yml"
          - "manifests/serverless-operator-imageset-config.yml"
          - "manifests/servicemeshoperator-imageset-config.yml"
          - "manifests/web-terminal-imageset-config.yml"
          - "manifests/argocd-operator-imageset-config.yml"
          - "manifests/cert-manager-imageset-config.yml"
          - "manifests/keycloak-operator-imageset-config.yml"
          - "manifests/mongodb-operator-imageset-config.yml"
          - "manifests/confluent-for-kubernetes-imageset-config.yml"
          - "manifests/gitlab-runner-operator-imageset-config.yml"
          - "manifests/gpu-operator-certified-imageset-config.yml"
          - "manifests/elasticsearch-eck-operator-certified-imageset-config.yml"
          - "manifests/minio-operator-imageset-config.yml"
  
### set_custom_catalog_name 
Optional:   
Default: 'true'   
The flag to indicate if the custom catalog name should be set and used when pushing content to the destination registry.   

### custom_catalog_prefix
Optional:   
Default: 'custom-'   
The string prefix to prepend to the custom catalog name should be set and used when pushing content to the destination registry.   

### imageset_config_files_dir 
Optional:   
Default: 'manifests'   
The directory where where the created or provided imageset config files are placed or retrieved from .   

