# Cloud Pak for Data Deployer

A containerized, automated installation of Cloud Pak for Data

## Prerequisites

Openshift version >= 4.12 and <= 4.15

Cloud Pak for Data version >= 4.8.0 and <= 4.8.5

Access to both File and Block storage classes

Kubectl or oc installed on the machine you plan to deploy from

## Documentation

Using the deployer is simple, in the kube-manifests.yaml file there is a configmap containing the following:

```yaml
OCP_URL: ""
OPENSHIFT_TYPE: "self-managed"
OCP_USERNAME: ""
OCP_PASSWORD: ""
#OCP_TOKEN: ""
IMAGE_ARCH: "amd64"
IBM_ENTITLEMENT_KEY: ""
PROJECT_CPD_INST_OPERANDS: "cp4d"
PROJECT_CPD_INST_OPERATORS: "cp4d-operators"
PROJECT_SCHEDULING_SERVICE: "ibm-cpd-scheduler"
PROJECT_LICENSE_SERVICE: "ibm-licensing"
PROJECT_CERT_MANAGE: "ibm-cert-manager"
STG_CLASS_FILE: "ocs-storagecluster-cephfs"
STG_CLASS_BLOCK: "ocs-storagecluster-ceph-rbd"
VERSION: "4.8.5"
COMPONENTS: "ibm-cert-manager,ibm-licensing,scheduler,cpfs,cpd_platform"
PODMAN_IGNORE_CGROUPSV1_WARNING: "true"
COMMAND: "install"
```

Fill out the information to match your environment, an example configuration might be:

```yaml
OCP_URL: "api.XXXXXXXXXX.cloud.com:6443"
OPENSHIFT_TYPE: "self-managed"
OCP_USERNAME: "kubeadmin"
OCP_PASSWORD: "XXXXX-XXXXX-XXXXX-XXXXX"
#OCP_TOKEN: ""
IMAGE_ARCH: "amd64"
IBM_ENTITLEMENT_KEY: "AIXasdklfasdfjaksdhfaskdfj.asdjfkasldfjsaeioe.iaseoAIoasdlfkaj"
PROJECT_CPD_INST_OPERANDS: "cp4d"
PROJECT_CPD_INST_OPERATORS: "cp4d-operators"
PROJECT_SCHEDULING_SERVICE: "ibm-cpd-scheduler"
PROJECT_LICENSE_SERVICE: "ibm-licensing"
PROJECT_CERT_MANAGE: "ibm-cert-manager"
STG_CLASS_FILE: "ocs-storagecluster-cephfs"
STG_CLASS_BLOCK: "ocs-storagecluster-ceph-rbd"
VERSION: "4.8.5"
COMPONENTS: "ibm-cert-manager,ibm-licensing,scheduler,cpfs,cpd_platform"
PODMAN_IGNORE_CGROUPSV1_WARNING: "true"
COMMAND: "install"
```


## Component Customization

> [!NOTE]
> For component customization there is a second configmap named ```install-options``` where you can place any component customizations found [here](https://www.ibm.com/docs/en/cloud-paks/cp-data/4.8.x?topic=data-specifying-installation-options-services#install-platform-param-file__spark-parms__title__1)

Double check that your indentation matches the example provided in the configmap

## Storage

Make sure to populate ```STG_CLASS_FILE``` and ```STG_CLASS_BLOCK``` with the relevant file and block storage classes from your cluster

## Installation

Once everything is populated, run either:

```shell 
oc apply -f kube-manifests.yaml
```

or

```shell
kubectl apply -f kube-manifests.yaml
```

The installation takes between an hour and four hours depending on the components you attempt the install with

## Commands

Possible values for the ```COMMAND``` include the following:

```shell
install
```

- This will install Cloud Pak for Data with your configuration

```shell
uninstall
```

- This will uninstall Cloud Pak for Data instances installed with this deployer

