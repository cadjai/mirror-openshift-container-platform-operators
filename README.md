# mirror-openshift-container-platform-operators 

This repository contains helper playbooks to mirror Red Hat Openshift Container Platform operators and create a bundle that can be used in air-gapped or disconnected environments. The playbooks use scripts from two other Red Hat consultants to achieve this.   

The main script from [Arvin Amirian](https://github.com/redhat-cop/openshift-disconnected-operators) is primarily used for the content mirroring, passing in for each operator index being mirrored, the list of operators. This results in pulling the latest operators for the operator index tag passed in and also only the latest operand images being pulled.   

If you need all versions of operand images, you can either use the [role](https://github.com/cadjai/mirror-ocp4-contents-for-artifactory.git), which provides an automation of the steps described in the [official docs](https://docs.openshift.com/container-platform/4.7/operators/admin/olm-managing-custom-catalogs.html) or follow the steps documented in the documentation.   

> **:WARNING: As it currently exists, the steps in the documentation (using the opm tool even with pruning), pull all operand images associated with an operator. That might bring in images that are no longer maintained or for which security vulnerabilities might no longer be remediated.**

**It is therefore recommanded for the time being to use the Arvin based approach, which only brings in the latest version of each operand.** 

To help ready the file system of the pulled images from the above step (using the Arvin script) so that the images can easily be pushed to the destination registry, the second script from [Alex Flom](https://github.com/RedHatGov/openshift-disconnected-operators/blob/master/container/upload.sh) is used to fix the v2 registry file system layout to help push the content into the destination registry.

## Requirements

It is recommended to look at the source repositories for each of the main scripts for the requirements of that script.  
The playbooks here only require ansible to run. 

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

