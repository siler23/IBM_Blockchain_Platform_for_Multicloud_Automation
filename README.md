# IBM Blockchain Platform for Multicloud Automation

This repository contains automation scripts to create new namespaces with the necessary setup for the IBM Blockchain Platform for Multicloud console and deploy said console into each of these namespace chosen. You can clean up all artifacts including helm releases, the clusterrole, and the namespaces with all of the other deployed resources.

## Scripts

In order to accomplish the above stated tasks there are 4 scripts:

1. `Blockchain_Setup.sh` contains the initial variables and is the start script to execute with options depending on your needs described below in `Deploy the IBM Blockchain Platform for Multicloud Helm Chart, creating a namespace for each deployment with the number of charts you desire`.

2. `NamespaceSetup.sh` contains the logic to setup namespaces with necessary credentials based on clusterroles in this repo. Apply with `kubectl apply -f` as mentioned in the **Pre-reqs** section. It also gets the values necessary values for the IBM Blockchain Platform for Multicloud helm chart. For example, it finds first available ports for each chart and hands them out to helm releases in sequential order.

3. `create_optools.sh` contains the helm deploy logic for the IBM Blockchain Platform for Multicloud helm chart

4. `cleanupNamespaces.sh` contains the logic to clean everything up after you are through using it.

## Get this repository

1. clone using ssh key: 
```
git clone git@github.com:siler23/IBM_Blockchain_Platform_for_Multicloud_Automation.git MultiCloud-Automation
```

Note: The final word `MultiCloud-Automation` will be the name of the directory once cloned. You can change this as you see fit to have a different directory name. For example, if you wanted the directory to be named `SetOperationalToolingUpForMe` you would use `git clone git@github.ibm.com:Garrett-Lee-Woodworth/MultiCloud-Lab-Automation.git SetOperationalToolingUpForMe`

2. clone using https: 
```
git clone https://github.com/siler23/IBM_Blockchain_Platform_for_Multicloud_Automation.git MultiCloud-Automation
```

Note: The note above regarding directory naming applies to the https method of git clone as well.

3. Download the repository as a zip file: 

   Go to the following url in your web browser:
   
   https://github.com/siler23/IBM_Blockchain_Platform_for_Multicloud_Automation/archive/master.zip

## Pre-reqs 

(Install via your ibm cloud private for correct version numbers to match cluster)
Check output of commands to make sure versions much that of your cluster [i.e. client matches server] (an example is below for my cluster):

- kubectl command line (Version 1.12.4)
```
kubectl version 
Client Version: version.Info{Major:"1", Minor:"12", GitVersion:"v1.12.4", GitCommit:"f49fa022dbe63faafd0da106ef7e05a29721d3f1", GitTreeState:"clean", BuildDate:"2018-12-14T07:10:00Z", GoVersion:"go1.10.4", Compiler:"gc", Platform:"darwin/amd64"}
Server Version: version.Info{Major:"1", Minor:"12", GitVersion:"v1.12.4+icp-ee", GitCommit:"d03f6421b5463042d87aa0211f116ba4848a0d0f", GitTreeState:"clean", BuildDate:"2019-01-17T13:14:09Z", GoVersion:"go1.10.4", Compiler:"gc", Platform:"linux/amd64"}
```

- cloudctl command line (Version 3.1.2)
```
cloudctl version
Client Version: 3.1.2-1203+81b254e18da556ae1d9b683a9702e8420896dae9
Server Version: 3.1.2-1203+81b254e18da556ae1d9b683a9702e8420896dae9
```

- helm cli  (Version 2.9.1)
```
helm version --tls
Client: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.9.1+icp", GitCommit:"8ddf4db6a545dc609539ad8171400f6869c61d8d", GitTreeState:"clean"}
```

- Use a computer running macos or a linuxos with the bash shell.

- Add necessary clusterroles (once per cluster)

   You only need to apply these once per cluster, so if they already exist in the correct configuration, you can skip this step.

   If not, apply all while in the `IBM_Blockchain_Platform_for_Multicloud_Automation` you cloned with:

   ```
   kubectl apply -f .
   ```

## Login and Configuration

### Login to your ICP cluster

```
cloudctl login -a https://CLUSTER_HOSTNAME:8443 -n default
```

For example:

```
cloudctl login -a https://mycluster.icp:8443 -n default
```

#### Troubleshooting Login

##### Troubleshooting cannot connect error

1. Check to make sure vpn is running, if applicable

2. Check hostname is correct

3. Check that hostname maps to the correct IP in /etc/hosts file with `sudo cat /etc/hosts`. If not add hostname/ip mapping to /etc/hosts with:

   ```
   echo "CLUSTER_IP   CLUSTER_HOSTNAME" | sudo tee -a /etc/hosts
   ```

   For example:

   ```
   echo "192.52.32.94   mycluster.icp" | sudo tee -a /etc/hosts
   ```

##### Troubleshooting x509 error on Login to your ICP Cluster (ONLY If above step [`cloudctl login`] failed)

If this fails with x509 error, it means you need to trust a ca cert for the cluster.

One way to do this on mac is to run:

```
cloudctl login -a https://CLUSTER_HOSTNAME:8443 -n default --skip-ssl-validation
```

For example:

```
cloudctl login -a https://mycluster.icp:8443 -n default --skip-ssl-validation
```

This will download a ca.pem certificate for your cluster

You can then trust this certificate on macos with:

```
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ~/.helm/ca.pem
```

If you have docker and want to configure this as well, please restart docker to pick up the new certs in docker.

To make sure this has been done successfully use

```
cloudctl login -a https://CLUSTER_HOSTNAME:8443 -n default
```

For example:

```
cloudctl login -a https://mycluster.icp:8443 -n default
```

You should now find success. If you don't, please troubleshoot further before progressing with a deploy as you will be setting yourself up for failure / wasting time.

### If you don't already have a local helm repo mirror, please configure one

```
helm repo add blockchain-charts --ca-file "${HOME}"/.helm/ca.pem --cert-file "${HOME}"/.helm/cert.pem --key-file "${HOME}"/.helm/key.pem https://CLUSTER_HOSTNAME:8443/helm-repo/charts
helm repo update
```

```
helm repo add blockchain-charts --ca-file "${HOME}"/.helm/ca.pem --cert-file "${HOME}"/.helm/cert.pem --key-file "${HOME}"/.helm/key.pem https://mycluster.icp:8443/helm-repo/charts
helm repo update
```

## Deploy the IBM Blockchain Platform for Multicloud Helm Chart, creating a namespace for each deployment with the number of consoles you desire

```
TEAM_NUMBER=<number_of_consoles> PREFIX=<chosen_prefix> ./Blockchain_Setup.sh
```

For example, to create `1` instance with PREFIX of `garrett` use:

```
TEAM_NUMBER=1 PREFIX=garrett ./Blockchain_Setup.sh
```

The prefix makes it so different users can coexist. Please check to make sure your prefix isn't being used by a namespace yet with `kubectl get ns | grep prefix` where prefix is the name of your prefix.

### Table of Deployment Options

The following table explains each variable, gives its default value and specifies if `User_Must_Set` for the script to run. 

| Variable                	| Definition                                                                                       	| Default_Value                           	| User_Must_Set    	|
|-------------------------	|--------------------------------------------------------------------------------------------------	|-----------------------------------------	|------------------	|
| PREFIX                  	| Prefix to use to group resources of one run of automation                                        	| none                                    	| Yes              	|
| TEAM_NUMBER             	| Number of consoles to have given prefix                                                          	| none                                    	| Yes              	|
| START_NUMBER            	| Start script w/ this console #. START_NUMBER=1 => start with 2nd console                         	| 0                                       	| No               	|
| ADMIN_EMAIL             	| Use 1 admin email (username) for all consoles vs. different team usernames                       	| none                                    	| No               	|
| DEFAULT_PASSWORD        	| Use 1 default password for all consoles vs. different random team passwords                      	| none                                    	| No               	|
| ARCH                    	| Architecture for deployment (either s390x [z/LinuxONE] or amd64 [x86] )                          	| s390x                                   	| No               	|
| HELM_REPO               	| Local helm repo used in helm install command                                                     	| blockchain-charts                       	| No               	|
| PROXY_IP                	| Proxy IP of Cluster (command below)                                                              	| output of command                       	| if command fails 	|
| (continuation of above) 	| kubectl get nodes -l 'proxy=true' -o jsonpath='{.items[0].status.addresses[0].address}'          	|  N/A                                    	| N/A              	|
| CONSOLE_HOSTNAME        	| Desired hostname of blockchain console                                                           	| value of PROXY_IP                       	| No               	|
| PROD                    	| Set resources to prod limits if true. Otherwise, use dev limits                                  	| false                                   	| No               	|
| CERTS                   	| Signer of TLS CERTS 1.self-signed (none); 2.icp-ca-signed (icp); 3. bring your own (byo)         	| none                                    	| No               	|
| TLS_CERT                	| Path to TLS certificate for blockchain console (Only used if CERTS=byo)                          	| cert.pem                                	| No               	|
| TLS_KEY                 	| Path to TLS key for blockchain console (Only used if CERTS=byo)                                  	| key.pem                                 	| No               	|
| STORAGE_CLASS           	| Kubernetes Storage class for dynamic provisioning                                                	| managed-nfs-storage                     	| No               	|
| CLUSTER_HOSTNAME        	| Hostname for ICP Cluster                                                                         	| mycluster.icp                           	| No               	|
| DOCKER_NAMESPACE        	| Namespace where docker images pushed for the helm chart (cloudctl load-archive namespace)        	| blockchain-time                         	| No               	|
| IBP_CLUSTERROLE         	| Clusterrole set that has necessary resource access for IBP optools helm chart.                   	| ibm-blockchain-platform-clusterrole     	| No               	|
| CRD_CLUSTERROLE         	| Clusterrole to give cluster-wide access to create CRD, is bound via clusterrolebinding in script 	| crd-clusterrole                         	| No               	|
| PSP_CLUSTERROLE         	| Clusterrole to give access to ibm-blockchain-platform-psp                                        	| ibm-blockchain-platform-psp-clusterrole 	| No               	|
| SERVICE_ACCOUNT_NAME    	| Service account to be created in each namespace to dole out extra permissions                    	| ibp                                     	| No               	|

### Sample Run with Deployment Options Specified 

If all defaults were left and user added the 2 required values of `PREFIX` as `all-in` and `TEAM_NUMBER` as `1` the result written out would be the following command.

```
PREFIX="all-in" TEAM_NUMBER=1 START_NUMBER=0 ADMIN_EMAIL="" DEFAULT_PASSWORD="" ARCH="s390x" HELM_REPO="blockchain-charts" PROXY_IP="$(kubectl get nodes -l 'proxy=true' -o jsonpath='{.items[0].status.addresses[0].address}')" CONSOLE_HOSTNAME="${PROXY_IP}" PROD="false" CERTS="" TLS_CERT="cert.pem" TLS_KEY="key.pem" STORAGE_CLASS="managed-nfs-storage" CLUSTER_HOSTNAME="mycluster.icp" DOCKER_NAMESPACE="blockchain-time" IBP_CLUSTERROLE="ibm-blockchain-platform-clusterrole"  CRD_CLUSTERROLE="crd-clusterrole" PSP_CLUSTERROLE="ibm-blockchain-platform-psp-clusterrole" SERVICE_ACCOUNT_NAME="ibp" ./Blockchain_Setup.sh
```

This translates to (without resetting defaults):

```
PREFIX="all-in" TEAM_NUMBER=1 ./Blockchain_Setup.sh
```

You can use the above `Table of Deployment Options` to see which options you need to change from default and add these to the 2nd command to form the command you need to run. For example, if the only default I needed to change was `STORAGE_CLASS="managed-nfs-storage"` to `STORAGE_CLASS="nfs-share"` I would run

```
PREFIX="all-in" TEAM_NUMBER=1 STORAGE_CLASS="nfs-share" ./Blockchain_Setup.sh
```

### Further Explanation of Deployment Options 

**If you wish to use one admin email / admin username for all consoles instead of team users as initial admin users**


For example, to set up the admin email for 5 consoles use the following setup:

```
TEAM_NUMBER=5 PREFIX=<chosen_prefix> ADMIN_EMAIL="<admin_email>" ./Blockchain_Setup.sh
```

For example:

```
TEAM_NUMBER=5 PREFIX=email-time ADMIN_EMAIL="siler23@ibm.com" ./Blockchain_Setup.sh
```

**If you wish to use one default password as the default password for each console instead of using a random password**

For example, to set up the default password for 5 consoles use the following setup:

```
TEAM_NUMBER=5 PREFIX=<chosen_prefix> DEFAULT_PASSWORD="<default_password>" ./Blockchain_Setup.sh
```

For example:

```
TEAM_NUMBER=5 PREFIX=email-time DEFAULT_PASSWORD="secure_password" ./Blockchain_Setup.sh
```

**If you wish to start off midway through setup due to adding additional consoles (or due to a snag), use START_NUMBER=x where x is the team you wish to start with**

This defaults to 0 such that: 

```
TEAM_NUMBER=5 PREFIX=email-time ./Blockchain_Setup.sh
```

is equivalent to:

```
START_NUMBER=0 TEAM_NUMBER=5 PREFIX=email-time ./Blockchain_Setup.sh
```

For example, to set up consoles 06 to 10 use:

```
TEAM_NUMBER=11 PREFIX=garrett START_NUMBER=6 ./Blockchain_Setup.sh
```

**Default helm repo is *blockchain-charts*. If your icp mirror is named something else (i.e. IloveBeingDifferent)**

```
helm repo update 
TEAM_NUMBER=5 PREFIX=garrett HELM_REPO=IloveBeingDifferent ./Blockchain_Setup.sh
```

**Default is using IBM Z (s390x). If you wish to use x86**

```
TEAM_NUMBER=5 PREFIX=garrett ARCH=amd64 ./Blockchain_Setup.sh
```

**FYI**: *You can adjust other values in the same way for the other values set in `Blockchain_Setup.sh` as necessary. I have just listed the one I believe will be the most common above.*

**Using a hostname**

In order to use a hostname rather than an ip for your proxy console, please enter CONSOLE_HOSTNAME parameter when deploying the console.

For example, to set up the CONSOLE_HOSTNAME for 5 consoles use the following setup:

```
TEAM_NUMBER=5 PREFIX=<chosen_prefix> CONSOLE_HOSTNAME="<my_console_hostname>" ./Blockchain_Setup.sh
```

```
TEAM_NUMBER=5 PREFIX=hostname-test CONSOLE_HOSTNAME="mycluster.icp" ./Blockchain_Setup.sh
```

**Certificate Options**

There are 3 certificate options

1. Use a self-signed certificate for the IBM Blockchain Platform for Multicloud Console

   This is the default option.

2. Use a certificate signed by the ICP CA
   
   This will happen if you set `CERTS=icp`. The hostname for the certificate will be the value of `CONSOLE_HOSTNAME`, which if not set will default to the IP of the proxy node of the cluster.

   For example:

   ```
   TEAM_NUMBER=1 PREFIX=icp-certs CONSOLE_HOSTNAME=mycluster.icp CERTS=icp ./Blockchain_Setup.sh
   ```


3. Bring your own certificate to use 

   This will happen if you set `CERTS=byo`. If you choose this option, you must have the certificate and key in the location specified by `TLS_CERT` and `TLS_KEY` respectively. The defaults for these are `cert.pem` and `key.pem` in the home directory. Ideally, the hostname specified in the cert should match the value of `CONSOLE_HOSTNAME`, which if not set will default to the IP of the proxy node of the cluster.

   For example:
     
   ```
   TEAM_NUMBER=1 PREFIX=byo-certs CONSOLE_HOSTNAME=mycluster.icp CERTS=byo TLS_CERT=blockcrt.pem TLS_KEY=block-key.pem ./Blockchain_Setup.sh
   ```

**Resource Options**

The resource settings are set to observed defaults based on cluster max and overall usage for previous deployments. (Thus, some values are lower than regular defaults for lab purposes). For production, please use Full resource configurations by setting the variable `PROD=true`.

For example,

```
TEAM_NUMBER=1 PREFIX=garrett PROD=true ./Blockchain_Setup.sh
```

### Troubleshooting ProxyIP issue 

Make sure you can get the ProxyIP with

```
kubectl get nodes -l 'proxy=true' -o jsonpath='{.items[0].status.addresses[0].address}' && echo
```

You should get an IP output like: `192.52.32.94` which you can use for the PROXY_IP value when running the script.

If not, then use an IP that your cluster nodePorts are available from for the PROXY_IP and run script with PROXY_IP entered:

```
TEAM_NUMBER=1 PREFIX=garrett PROXY_IP=192.52.32.94 ./Blockchain_Setup.sh
```

### Deployment Description

This helm chart deploys the **optools pod** (with containers optools, couchdb, configtxlator, deployer, and operator)

Note: Firefox ESR is not officially supported at this time. Please use the regular Firefox or Safari or Chrome. Additionally, you may need to delete your web browser cache from an earlier IBM Blockchain Platform for Multicloud instance for things to load properly if you are having problems seeing the sign-on screen.

## Recommended Access After Deployment

**The deployment details for all teams are available for in the `portList.txt` file created by the script so that instructors can see all of these in one place for their reference.**

`portList.txt` will be created in the directory you clone this repo into (Default is `MultiCloud-Lab-Automation`). To view this file you could either open up `portlist.txt` in a text editor or use a terminal command after running the script, such as:

```
cat portList.txt
```

## CLEANUP
There is a cleanup script which will cleanup the helm charts for all of the namespaces as well as created secrets and namespace itself. This makes sure everything is cleaned up after a lab.

The command for cleanup will be printed at the end of `portList.txt` based on the setup command you entered. The full cleanup command will be printed in format:

```
Full Cleanup Command: TEAM_NUMBER=<number_of_teams> PREFIX=<chosen_prefix> ./cleanupNamespaces.sh
```

If START_NUMBER was set greater than 0, the partial cleanup command will also be in `portList.txt` printed in the format:

```
Cleanup Command for This Run: TEAM_NUMBER=<number_of_teams> START_NUMBER=<chosen_starting_team> PREFIX=<chosen_prefix> ./cleanupNamespaces.sh
```


** If you wish to start off midway through deletion due to a snag, use START_NUMBER=x where x is the team you wish to start with **

For example, to delete team06 to team10 use:

```
TEAM_NUMBER=11 PREFIX=garrett START_NUMBER=6 ./cleanupNamespaces.sh
```

## Notes
This script uses the docker credentials for the namespace that IBP was loaded to as set by `DOCKER_NAMESPACE` in Blockchain_Setup.sh. While theoretically you can set the number of teams as high as you want, there is of course a limit in terms of cluster capacity at a certain point.

This script has been tested up to 15 namespaces / IBM Blockchain Platform for Multicloud deploys. One of these deploys was then successfully tested with e2e deployment (i.e. deploy 2CAs, with 1 peer, 1 orderer, create/join channel, install/instantiate/invoke smart contract).

A run like `TEAM_NUMBER=15 PREFIX=garrett ./Blockchain_Setup.sh` should end as follows with the number of instances setup depending on the number you set:
```
@@@@@@@@  @@@  @@@  @@@  @@@   @@@@@@   @@@  @@@  @@@@@@@@  @@@@@@@   
@@@@@@@@  @@@  @@@@ @@@  @@@  @@@@@@@   @@@  @@@  @@@@@@@@  @@@@@@@@  
@@!       @@!  @@!@!@@@  @@!  !@@       @@!  @@@  @@!       @@!  @@@  
!@!       !@!  !@!!@!@!  !@!  !@!       !@!  @!@  !@!       !@!  @!@  
@!!!:!    !!@  @!@ !!@!  !!@  !!@@!!    @!@!@!@!  @!!!:!    @!@  !@!  
!!!!!:    !!!  !@!  !!!  !!!   !!@!!!   !!!@!!!!  !!!!!:    !@!  !!!  
!!:       !!:  !!:  !!!  !!:       !:!  !!:  !!!  !!:       !!:  !!!  
:!:       :!:  :!:  !:!  :!:      !:!   :!:  !:!  :!:       :!:  !:!  
 ::        ::   ::   ::   ::  :::: ::   ::   :::   :: ::::   :::: ::  
 :        :    ::    :   :    :: : :     :   : :  : :: ::   :: :  :   

It took 4 minutes and 56 seconds to setup 15 IBM Blockchain Platform for Multicloud instances each in an unique namespace
```

You would then cleanup with `TEAM_NUMBER=15 PREFIX=garrett ./cleanupNamespaces.sh` which should end as follows:
```
namespace "team14ns" deleted
+ set +x


       `..   `..      `........      `.       `...     `..
 `..   `..`..      `..           `. ..     `. `..   `..
`..       `..      `..          `.  `..    `.. `..  `..
`..       `..      `......     `..   `..   `..  `.. `..
`..       `..      `..        `...... `..  `..   `. `..
 `..   `..`..      `..       `..       `.. `..    `. ..
   `....  `........`........`..         `..`..      `..

It took 3 minutes and 32 seconds to cleanup 15 IBM Blockchain Platform for Multicloud instances and their namespaces
```