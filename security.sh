#echo "Enter container id that will be used during inspection: "
#read containerid;
confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}
#############################
# Host configuration check. #
#############################
echo "## 1.1 Create a separate partition for containers (Scored)";
echo "\"## 1.1 Create a separate partition for containers (Scored)\":" >> output.json ;
if `grep /var/lib/docker /etc/fstab;`; then echo "Ok"; else echo "Bad"; fi
## 1.2 Harden the container host (Not Scored)
echo "## 1.3 Keep Docker up to date (Not Scored)" ; echo "\"## 1.3 Keep Docker up to date (Not Scored)\":" >> output.json ;
echo $(docker version)
echo "## 1.4 Only allow trusted users to control Docker daemon (Scored)"
echo $(getent group docker)
echo "## 1.5 Audit docker daemon (Scored)"
if `auditctl -l | grep /usr/bin/docker;`; then echo "Ok"; else echo "Bad"; fi
#echo "-w /usr/bin/docker -k docker" >> /etc/audit/audit.rules ;
#service auditd restart
echo "## 1.6 Audit Docker files and directories - /var/lib/docker (Scored)"
if `auditctl -l | grep /var/lib/docker;`; then echo "Ok"; else echo "Bad"; fi
#echo "-w /var/lib/docker -k docker" >> /etc/audit/audit.rules ;
#service auditd restart
echo "## 1.7 Audit Docker files and directories - /etc/docker (Scored)"
if `auditctl -l | grep /etc/docker;`; then echo "Ok"; else echo "Bad"; fi
#echo "-w /etc/docker -k docker" >> /etc/audit/audit.rules ;
#service auditd restart
echo "## 1.8 Audit Docker files and directories - docker.service (Scored)"
systemctl show -p FragmentPath docker.service ;
if `auditctl -l | grep docker.service ;`; then echo "Ok"; else echo "Bad"; fi
#echo "-w /usr/lib/systemd/system/docker.service -k docker" >> /etc/audit/audit.rules ;
#service auditd restart
echo "## 1.9 Audit Docker files and directories - docker.socket (Scored)"
echo $(systemctl show -p FragmentPath docker.socket;)
#if [ $? -eq 0 ]; then echo "File exists"; else echo "Bad"; fi
auditctl -l | grep docker.socket ;
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
#echo "-w /usr/lib/systemd/system/docker.socket -k docker" >> /etc/audit/audit.rules ;
#service auditd restart
echo "## 1.10 Audit Docker files and directories - /etc/default/docker (Scored)"
auditctl -l | grep /etc/default/docker ;
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
#echo "-w /etc/default/docker -k docker" >> /etc/audit/audit.rules ;
#service auditd restart
echo "## 1.11 Audit Docker files and directories - /etc/docker/daemon.json (Scored)"
auditctl -l | grep /etc/docker/daemon.json ;
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
#echo "-w /etc/docker/daemon.json -k docker" >> /etc/audit/audit.rules ;
#service auditd restart
## 1.12 Audit Docker files and directories - /usr/bin/docker-containerd (Scored)
auditctl -l | grep /usr/bin/docker-containerd ;
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
#echo "-w /usr/bin/docker-containerd -k docker" >> /etc/audit/audit.rules ;
#service auditd restart
## 1.13 Audit Docker files and directories - /usr/bin/docker-runc (Scored)
auditctl -l | grep /usr/bin/docker-runc ;
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
#echo "-w /usr/bin/docker-runc -k docker" >> /etc/audit/audit.rules ;
#service auditd restart

#################################
# 2 Docker daemon configuration #
#################################
echo "## 2.1 Restrict network traffic between containers (Scored)"
echo " ##  It should return com.docker.network.bridge.enable_icc:false. ##"
#ps -ef | grep dockerd ;
docker network ls --quiet | xargs xargs docker network inspect --format '{{ .Name }}:{{ .Options }}';
#confirm "Would you really like to disable container communication?" && /usr/bin/dockerd --icc=false;
### IMPACT ##################################################################################
### The inter container communication would be disabled. No containers would be able to t ###
### to another container on the same host. If any communication between containers on the ###
### same host is desired, then it needs to be explicitly defined using container linking. ###
#############################################################################################
echo "## 2.2 Set the logging level (Scored)"
echo "Ensure that either the '--log-level' parameter is not present or if present, then it is set to
'info'."
echo $(ps -ef | grep dockerd;)
dockerd --log-level="info";
echo "## 2.3 Allow Docker to make changes to iptables (Scored)";
ps -ef | grep dockerd;
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
# dockerd --iptables=false;
echo "## 2.4 Do not use insecure registries (Scored)"
ps -ef | grep -v grep| grep dockerd | grep insecure-registry   # Ensure that the '--insecure-registry' parameter is not present.
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
echo "## 2.5 Do not use the aufs storage driver (Scored)"
echo "# verify that 'aufs' is not used as storage driver"
echo $(docker info | grep -e "^Storage Driver:\s*aufs\s*$")
echo "## 2.6 Configure TLS authentication for Docker daemon (Scored)"
ps -ef | grep -v grep| grep tlsverify
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
ps -ef | grep -v grep| grep tlscacert
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
ps -ef | grep -v grep| grep tlscert
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
ps -ef | grep -v grep| grep tlskey
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
### Ensure that the below parameters are present:
### * '--tlsverify'
### * '--tlscacert'
### * '--tlscert'
### * '--tlskey'
#################
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
echo "## 2.7 Set default ulimit as appropriate (Not Scored)"
ps -ef | grep dockerd | grep -v grep | grep default-ulimit ; # Ensure that the '--default-ulimit' parameter is set as appropriate.
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
echo "## 2.8 Enable user namespace support (Scored)"
docker info --format '{{ .SecurityOptions }}' | grep userns; # ensure that the userns is listed under Security Options
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then confirm "are sure to use touch?" && touch /etc/subuid /etc/subgid && dockerd --userns-remap=default && dockerd --userns-remap=default; fi

echo "## 2.9 Confirm default cgroup usage (Scored)";
ps -ef | grep -v grep| grep dockerd | grep cgroup-parent #Ensure that the '--cgroup-parent' parameter is either not set or is set as appropriate nondefault cgroup.
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then dockerd --cgroup-parent=/foobar; fi

echo "## 2.10 Do not change base device size until needed (Scored)"
ps -ef | grep -v grep| grep dockerd | grep storage-opt
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
ps -ef | grep -v grep| grep dockerd | grep dm.basesize
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo " ## Do not set --storage-opt dm.basesize until needed"; fi
echo "## 2.11 Use authorization plugin (Scored)"
ps -ef | grep -v grep| grep dockerd | grep authorization-plugin
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo"Step 1: Install/Create an authorization plugin.
Step 2: Configure the authorization policy as desired.
Step 3: Start the docker daemon as below:
dockerd --authorization-plugin=<PLUGIN_ID> /n"; fi

echo "## 2.12 Configure centralized and remote logging (Scored)";
ps -ef | grep -v grep| grep dockerd | grep log-driver
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Remediation:
Step 1: Setup the desired log driver by following its documentation.
Step 2: Start the docker daemon with that logging driver.
For example,
dockerd --log-driver=syslog --log-opt syslog-address=tcp://192.xxx.xxx.xxx
"; fi

echo "## 2.13 Disable operations on legacy registry (v1) (Scored)"
ps -ef | grep -v grep| grep dockerd | grep disable-legacy-registry
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then dockerd --disable-legacy-registry; fi
echo "## 2.14 Enable live restore (Scored)"
ps -ef | grep -v grep| grep dockerd | grep live-restore
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then dockerd --live-restore; fi
echo "## 2.15 Do not enable swarm mode, if not needed (Scored)"
docker info| grep -v grep| grep 'Swarm: inactive'
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then docker swarm leave; fi
echo "## 2.16 Control the number of manager nodes in a swarm (Scored)"
docker node ls | grep 'Leader'
if [ "$1" == "-m" ]; then echo "Remediation:
If an excessive number of managers is configured, the excess can be demoted as worker
using the following command:
docker node demote <ID>
Where <ID> is the node ID value of the manager to be demoted"; fi

echo "## 2.17 Bind swarm services to a specific host interface (Scored)"
netstat -lt | grep -i 2377
if [ $? -ne 0 ]; then echo "It seems that Swarm mode NOT enabled" ; else echo "confirm that that each overlay network has been encrypted."; fi
if [ "$1" == "-m" ]; then dockerd --cgroup-parent=/foobar; fi

echo "## 2.18 Disable Userland Proxy (Scored)"
ps -ef | grep -v grep| grep dockerd | grep userland-proxy
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Create overlay network with --opt encrypted flag."; fi

echo "## 2.19 Encrypt data exchanged between containers on different nodes on the overlay network (Scored)"
docker network ls --filter driver=overlay --quiet
if [ $? -ne 0 ]; then echo "It seems that Swarm mode NOT enabled" ; else echo "confirm that it is only listening on specific interfaces."; fi
if [ "$1" == "-m" ]; then echo "Remediation:
Create overlay network with --opt encrypted flag."; fi

echo "## 2.20 Apply a daemon-wide custom seccomp profile, if needed (Not Scored)"
docker info --format '{{ .SecurityOptions }}' | grep default
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo"Remediation:
By default, Docker's default seccomp profile is applied. If this is good for your environment,
no action is necessary. Alternatively, if you choose to apply your own seccomp profile, use
the --seccomp-profile flag at daemon start or put it in the daemon runtime parameters
file.
dockerd --seccomp-profile </path/to/seccomp/profile>"; fi
echo "## 2.21 Avoid experimental features in production (Scored)"
docker version --format '{{ .Server.Experimental }}'
if [ `docker version --format '{{ .Server.Experimental }}'` == false ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Do not pass --experimental as a runtime parameter to the docker daemon"; fi
echo "## 2.22 Use Docker's secret management commands for managing secrets in a Swarm cluster (Not Scored)"
docker secret ls | grep 'not a swarm'
if [ $? -eq 0 ]; then echo "not a swarm manager node" ; else echo "Follow docker secret documentation and use it to manage secrets effectively"; fi
echo "## 2.23 Run swarm manager in auto-lock mode (Scored)"
echo "If it outputs the key, it means swarm was initialized with the --
autolock flag. If the output is no unlock key is set, it means that swarm was NOT
initialized with the --autolock flag and is non-compliant with respect to this
recommendation."

docker swarm unlock-key
echo "## 2.24 Rotate swarm manager auto-lock key periodically (Not Scored)"
echo "If it outputs the key, it means swarm was initialized with the --
autolock flag. If the output is no unlock key is set, it means that swarm was NOT
initialized with the --autolock flag and is non-compliant with respect to this
recommendation."
if [ "$1" == "-m" ]; then docker swarm unlock-key --rotate; fi
# 3 Docker daemon configuration files
echo "## 3.1 Verify that docker.service file ownership is set to root:root (Scored)";
export MYLOCATION=$(systemctl show -p FragmentPath docker.service | cut -d = -f2);
stat -c %U:%G $MYLOCATION | grep -v root:root;
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then chown root:root $MYLOCATION; fi
echo "## 3.2 Verify that docker.service file permissions are set to 644 or more restrictive (Scored)"
stat -c %a $MYLOCATION
if [ $(stat -c %a $MYLOCATION) == 644 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then chmod 644 $MYLOCATION; fi

echo "## 3.3 Verify that docker.socket file ownership is set to root:root (Scored)";
export SOCKET=$(systemctl show -p FragmentPath docker.socket | cut -d = -f2);
stat -c %U:%G $SOCKET | grep -v root:root
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then chown root:root $SOCKET; fi

echo "## 3.4 Verify that docker.socket file permissions are set to 644 or more restrictive (Scored)"
stat -c %a $SOCKET
if [ $(stat -c %a $SOCKET) == 644 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then chmod 644 $SOCKET; fi

echo "## 3.5 Verify that /etc/docker directory ownership is set to root:root (Scored)"
stat -c %U:%G /etc/docker | grep -v root:root;
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then chown root:root /etc/docker; fi

echo "## 3.6 Verify that /etc/docker directory permissions are set to 755 or more restrictive (Scored)";
stat -c %a /etc/docker;
if [ $(stat -c %a /etc/docker) == 755 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then chmod 755 /etc/docker; fi

echo "## 3.7 Verify that registry certificate file ownership is set to root:root (Scored)";
stat -c %U:%G /etc/docker/certs.d/* | grep -v root:root
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Remediation: chown root:root /etc/docker/certs.d/<registry-name>/*"; fi

echo "## 3.8 Verify that registry certificate file permissions are set to 444 or more restrictive (Scored)";
echo "Execute the below command to verify that the registry certificate files have permissions of
'444' or more restrictive:
stat -c %a /etc/docker/certs.d/<registry-name>/*"
if [ "$1" == "-m" ]; then echo "Remediation: chmod 444 /etc/docker/certs.d/<registry-name>/*"; fi

echo "## 3.9 Verify that TLS CA certificate file ownership is set to root:root (Scored)";
echo "Execute the below command to verify that the TLS CA certificate file is owned and groupowned by 'root':
stat -c %U:%G <path to TLS CA certificate file> | grep -v root:root
The above command should not return anything."
if [ "$1" == "-m" ]; then echo "Remediation: chown root:root <path to TLS CA certificate file>"; fi


echo "## 3.10 Verify that TLS CA certificate file permissions are set to 444 or more restrictive (Scored)";
echo "Execute the below command to verify that the TLS CA certificate file has permissions of
'444' or more restrictive:
stat -c %a <path to TLS CA certificate file>"
if [ "$1" == "-m" ]; then echo "Remediation: chmod 444 <path to TLS CA certificate file>"; fi

echo "## 3.11 Verify that Docker server certificate file ownership is set to root:root (Scored)";
echo "Audit:
Execute the below command to verify that the Docker server certificate file is owned and
group-owned by 'root':
stat -c %U:%G <path to Docker server certificate file> | grep -v root:root"
if [ "$1" == "-m" ]; then echo "Remediation: chown root:root <path to Docker server certificate file>"; fi

echo "## 3.12 Verify that Docker server certificate file permissions are set to 444 or more restrictive (Scored)";
echo "Execute the below command to verify that the Docker server certificate file has
permissions of '444' or more restrictive:
stat -c %a <path to Docker server certificate file>"
if [ "$1" == "-m" ]; then echo "Remediation: chmod 444 <path to Docker server certificate file>"; fi

echo "## 3.13 Verify that Docker server certificate key file ownership is set to root:root (Scored)";
echo "Execute the below command to verify that the Docker server certificate key file is owned
and group-owned by 'root':
stat -c %U:%G <path to Docker server certificate key file> | grep -v root:root"
if [ "$1" == "-m" ]; then echo "Remediation: chown root:root <path to Docker server certificate key file>"; fi

echo "## 3.14 Verify that Docker server certificate key file permissions are set to 400 (Scored)";
echo "Execute the below command to verify that the Docker server certificate key file has
permissions of '400':
stat -c %a <path to Docker server certificate key file>"
if [ "$1" == "-m" ]; then echo "Remediation: chmod 400 <path to Docker server certificate key file>"; fi

echo "## 3.15 Verify that Docker socket file ownership is set to root:docker (Scored)";
stat -c %U:%G /var/run/docker.sock | grep -v root:docker
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then chown root:docker /var/run/docker.sock; fi

echo "## 3.16 Verify that Docker socket file permissions are set to 660 or more restrictive (Scored)";
if [ $(stat -c %a /var/run/docker.sock) = "660" ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then chmod 660 /var/run/docker.sock; fi

echo "## 3.17 Verify that daemon.json file ownership is set to root:root (Scored)";
stat -c %U:%G /etc/docker/daemon.json | grep -v root:root
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then chown root:root /etc/docker/daemon.json; fi

echo "## 3.18 Verify that daemon.json file permissions are set to 644 or more restrictive (Scored)";
if [ $(stat -c %a /etc/docker/daemon.json)=="644" ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then chmod 644 /etc/docker/daemon.json; fi

echo "## 3.19 Verify that /etc/default/docker file ownership is set to root:root (Scored)";
stat -c %U:%G /etc/default/docker | grep -v root:root
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then chown root:root /etc/default/docker; fi

echo "## 3.20 Verify that /etc/default/docker file permissions are set to 644 or more restrictive (Scored)";
if [ $(stat -c %a /etc/default/docker) = "644" ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then chmod 644 /etc/default/docker; fi

echo "# 4 Container Images and Build File";
echo "## 4.1 Create a user for the container (Scored)";
echo $(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: User={{.Config.User }}')
if [ "$1" == "-m" ]; then echo "Remediation:
Ensure that the Dockerfile for the container image contains below instruction:
USER <username or ID>"; fi


echo "## 4.2 Use trusted base images for containers (Not Scored)";
docker images
echo "This would list all the container images that are currently available for use on the Docker
host. Interview the system administrator and obtain a proof of evidence that the list of
images was obtained from trusted source over a secure channel."
if [ "$1" == "-m" ]; then echo "Configure and use Docker Content trust"; fi

echo "## 4.3 Do not install unnecessary packages in the container (Not Scored)";
docker ps --quiet
echo "For each container instance, execute the below or equivalent command:
docker exec INSTANCE_ID rpm -qa
The above command would list the packages installed on the container. Review the list and
ensure that it is legitimate.
"
if [ "$1" == "-m" ]; then echo "Remediation:
At the outset, do not install anything on the container that does not justify the purpose. If
the image had some packages that your container does not use, uninstall them.
Consider using a minimal base image rather than the standard Redhat/Centos/Debian
images if you can. Some of the options include BusyBox and Alpine.
Not only does this trim your image size from >150Mb to ~20 Mb, there are also fewer tools
and paths to escalate privileges. You can even remove the package installer as a final
hardening measure for leaf/production containers."; fi

echo "## 4.4 Scan and rebuild the images to include security patches (Not Scored)";
docker ps --quiet
echo "For each container instance, execute the below or equivalent command to find the
list of packages installed within the container. Ensure that the security updates for various
affected packages are installed.
docker exec INSTANCE_ID rpm -qa"
if [ "$1" == "-m" ]; then echo "Step 1: 'docker pull' all the base images (i.e., given your set of Dockerfiles, extract all
images declared in 'FROM' instructions, and re-pull them to check for an updated/patched
versions). Patch the packages within the images too.
Step 2: Force a rebuild of each image with 'docker build --no-cache'.
Step 3: Restart all containers with the updated images.
You could also use ONBUILD directive in the Dockerfile to trigger particular update
instructions for images that you know are used as base images frequently."; fi



echo "## 4.5 Enable Content trust for Docker (Scored)";
if [[ $DOCKER_CONTENT_TRUST -eq 1 ]]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then export DOCKER_CONTENT_TRUST=1; fi

echo "## 4.6 Add HEALTHCHECK instruction to the container image (Scored)";
echo "Run the below command and ensure that the docker image has appropriate HEALTHCHECK
instruction set up.
docker inspect --format='{{ .Config.Healthcheck }}' <IMAGE>"
if [ "$1" == "-m" ]; then echo "Remediation:
Follow Docker documentation and rebuild your container image with HEALTHCHECK
instruction."; fi

echo "## 4.7 Do not use update instructions alone in the Dockerfile (Not Scored)";
docker images
echo "Step 2: Run the below command for each image in the list above, and look for any update
instructions being in a single line:
docker history <Image_ID>"
if [ "$1" == "-m" ]; then echo "Remediation:
Use update instructions along with install instructions (or any other) and version pinning
for packages while installing them. This would bust the cache and force to extract the
required versions.
Alternatively, you could use --no-cache flag during docker build process to avoid using
cached layers."; fi

echo "## 4.8 Remove setuid and setgid permissions in the images (Not Scored)";
echo "Remediation:
Use update instructions along with install instructions (or any other) and version pinning
for packages while installing them. This would bust the cache and force to extract the
required versions.
Alternatively, you could use --no-cache flag during docker build process to avoid using
cached layers."
if [ "$1" == "-m" ]; then RUN find / -perm +6000 -type f -exec chmod a-s {} \; || true; fi

echo "## 4.9 Use COPY instead of ADD in Dockerfile (Not Scored)";
docker images
echo "Step 2: Run the below command for each image in the list above and look for any ADD
instructions:
docker history <Image_ID>"

echo "## 4.10 Do not store secrets in Dockerfiles (Not Scored)";
docker images
echo "Run the below command for each image in the list above, and look for any secrets:
docker history <Image_ID>
Alternatively, if you have access to Dockerfile for the image, verify that there are no secrets
as described above."
if [ "$1" == "-m" ]; then echo "Remediation: Do not store any kind of secrets within Dockerfiles."; fi


echo "## 4.11 Install verified packages only (Not Scored)";
docker images
echo "Step 2: Run the below command for each image in the list above, and look for how
the authenticity of the packages is determined. This could be via the use of GPG keys or
other secure package distribution mechanisms
docker history <Image_ID>"
if [ "$1" == "-m" ]; then echo "Remediation: Use GPG keys for downloading and verifying packages or any other secure package
distribution mechanism of your choice."; fi


echo "# 5 Container Runtime";
echo "## 5.1 Do not disable AppArmor Profile (Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: AppArmorProfile={{.AppArmorProfile }}'
echo "The above command should return a valid AppArmor Profile for each container instance."
if [ "$1" == "-m" ]; then echo "Remediation:
If AppArmor is applicable for your Linux OS, use it. You may have to follow below set of
steps:
1. Verify if AppArmor is installed. If not, install it.
2. Create or import a AppArmor profile for Docker containers.
3. Put this profile in enforcing mode.
4. Start your Docker container using the customized AppArmor profile. For example,
docker run --interactive --tty --security-opt=\"apparmor:PROFILENAME\" centos /bin/bash
Alternatively, you can keep the docker's default apparmor profile"; fi

echo "## 5.2 Verify SELinux security options, if applicable (Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: SecurityOpt={{.HostConfig.SecurityOpt }}'
echo "The above command should return all the security options currently configured for the
containers."
echo "Remediation:
If SELinux is applicable for your Linux OS, use it. You may have to follow below set of steps:
1. Set the SELinux State.
2. Set the SELinux Policy.
3. Create or import a SELinux policy template for Docker containers.
4. Start Docker in daemon mode with SELinux enabled. For example,
docker daemon --selinux-enabled
5. Start your Docker container using the security options. For example,
docker run --interactive --tty --security-opt label=level:TopSecret centos
/bin/bash
I"

echo "## 5.3 Restrict Linux Kernel Capabilities within containers (Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: CapAdd={{.HostConfig.CapAdd }} CapDrop={{ .HostConfig.CapDrop }}'
echo "Verify that the added and dropped Linux Kernel Capabilities are in line with the ones needed for container process for each container instance."
if [ "$1" == "-m" ]; 
then echo "Remediation:
Execute the below command to add needed capabilities:
$> docker run --cap-add={\"Capability 1\",\"Capability 2\"} <Run arguments> <Container
Image Name or ID> <Command>
For example,
docker run --interactive --tty --cap-add={\"NET_ADMIN\",\"SYS_ADMIN\"} centos:latest
/bin/bash
Execute the below command to drop unneeded capabilities:131 | P a g e
$> docker run --cap-drop={\"Capability 1\",\"Capability 2\"} <Run arguments> <Container
Image Name or ID> <Command>
For example,
docker run --interactive --tty --cap-drop={\"SETUID\",\"SETGID\"} centos:latest /bin/bash
Alternatively,
You may choose to drop all capabilities and add only add the needed ones:
$> docker run --cap-drop=all --cap-add={\"Capability 1\",\"Capability 2\"} <Run arguments>
<Container Image Name or ID> <Command>
For example,
docker run --interactive --tty --cap-drop=all --cap-add={\"NET_ADMIN\",\"SYS_ADMIN\"}
centos:latest /bin/bash
I"; fi

echo "## 5.4 Do not use privileged containers (Scored)";
PTEST=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Privileged={{.HostConfig.Privileged }}' | grep Privileged=true)
if [[ -z $PTEST ]]; then echo "Ok"; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Do not run container with the --privileged flag.
For example, do not start a container as below:
docker run --interactive --tty --privileged centos /bin/bash"; fi

echo "## 5.5 Do not mount sensitive host system directories on containers (Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Volumes={{ .Mounts}}'
echo "The above commands would return the list of current mapped directories and whether
they are mounted in read-write mode for each container instance."

echo "## 5.6 Do not run ssh within containers (Scored)";
docker ps --quiet
echo "For each container instance, execute the below command:
docker exec INSTANCE_ID ps -el
Ensure that there is no process for SSH server."
if [ "$1" == "-m" ]; then echo "Remediation:
Uninstall SSH server from the container and use nsenter or any other commands such as
docker exec or docker attach to interact with the container instance.
docker exec --interactive --tty INSTANCE_ID sh
OR
docker attach INSTANCE_ID"; fi


echo "## 5.7 Do not map privileged ports within containers (Scored)";
docker ps --quiet | xargs docker inspect --format '{{ .Id }}: Ports={{.NetworkSettings.Ports }}'
echo "Review the list and ensure that container ports are not mapped to host port numbers below 1024"
if [ "$1" == "-m" ]; then echo "Remediation:
Do not map the container ports to privileged host ports when starting a container. Also,
ensure that there is no such container to host privileged port mapping declarations in the
Dockerfile."; fi

echo "## 5.8 Open only needed ports on container (Scored)";
docker ps --quiet | xargs docker inspect --format '{{ .Id }}: Ports={{.NetworkSettings.Ports }}'
echo "Review the list and ensure that the ports mapped are the ones that are really needed for
the container."
if [ "$1" == "-m" ]; then echo "Remediation:
Fix the Dockerfile of the container image to expose only needed ports by your
containerized application. You can also completely ignore the list of ports defined in the
Dockerfile by NOT using '-P' (UPPERCASE) or '--publish-all' flag when starting the
container. Use the '-p' (lowercase) or '--publish' flag to explicitly define the ports that
you need for a particular container instance.
For example,
docker run --interactive --tty --publish 5000 --publish 5001 --publish 5002 centos
/bin/bash"; fi

echo "## 5.9 Do not share the host's network namespace (Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: NetworkMode={{.HostConfig.NetworkMode }}'
echo "If the above command returns 'NetworkMode=host', it means '--net=host' option was
passed when container was started. This would be non-compliant. It should return bridge,
none, or container:\$Container_Instance to be compliant."
if [ "$1" == "-m" ]; then echo "Do not pass '--net=host' option when starting the container."; fi

echo "## 5.10 Limit memory usage for container (Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Memory={{.HostConfig.Memory }}' |  grep Memory=0
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Remediation:
Run the container with only as much memory as required. Always run the container using
the '--memory' argument. You should start the container as below:
$> docker run <Run arguments> --memory <memory-size> <Container Image Name or ID>
<Command>
For example,
docker run --interactive --tty --memory 256m centos /bin/bash
In the above example, the container is started with a memory limit of 256 MB.
Note: Please note that the output of the below command would return values in scientific
notation if memory limits are in place.
docker inspect --format='{{.Config.Memory}}' 7c5a2d4c7fe0 
For example, if the memory limit is set to 256 MB for the above container instance, the
output of the above command would be 2.68435456e+08 and NOT 256m. You should
convert this value using a scientific calculator or programmatic methods."; fi

echo "## 5.11 Set container CPU priority appropriately (Scored)144";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: CpuShares={{.HostConfig.CpuShares }}' | grep 'CpuShares=0\|CpuShares=1024'
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Remediation:
Manage the CPU shares between your containers. To do so start the container using the '--
cpu-shares' argument. You may start the container as below:
$> docker run <Run arguments> --cpu-shares <CPU shares> <Container Image Name or
ID> <Command>
For example,
docker run --interactive --tty --cpu-shares 512 centos /bin/bash
In the above example, the container is started with a CPU shares of 50% of what the other
containers use. So, if the other container has CPU shares of 80%, this container will have
CPU shares of 40%.145 | P a g e
Note: Every new container will have 1024 shares of CPU by default. However, this value is
shown as '0' if you run the command mentioned in the audit section.
Alternatively,
1. Navigate to /sys/fs/cgroup/cpu/system.slice/ directory.
2. Check your container instance ID using 'docker ps' command.
3. Now, inside the above directory (in step 1), you would have a directory by name
'docker-<Instance ID>.scope' for example 'docker-
4acae729e8659c6be696ee35b2237cc1fe4edd2672e9186434c5116e1a6fbed6.scope'.
Navigate to this directory.
4. You will find a file named 'cpu.shares'. Execute 'cat cpu.shares'. This will always
give you the CPU share value based on the system. So, even if there are no CPU
shares configured using '-c' or '--cpu-shares' argument in the 'docker run'
command, this file will have a value of '1024'.
If we set one container’s CPU shares to 512 it will receive half of the CPU time compared to
the other container. So, take 1024 as 100% and then do quick math to derive the number
that you should set for respective CPU shares. For example, use 512 if you want to set 50%
and 256 if you want to set 25%."; fi

echo "## 5.12 Mount container's root filesystem as read only (Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: ReadonlyRootfs={{.HostConfig.ReadonlyRootfs }}' | grep ReadonlyRootfs=false
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Remediation:
Add a '--read-only' flag to allow the container's root filesystem to be mounted as read
only. This can be used in combination with volumes to force a container's process to only
write to locations that will be persisted.
You should run the container as below:
$> docker run <Run arguments> --read-only -v <writable-volume> <Container Image Name
or ID> <Command>
For example,
docker run --interactive --tty --read-only --volume /centdata centos /bin/bash
This would run the container with read-only root filesystem and would use 'centdata' as
container volume for writing"; fi

echo "## 5.13 Bind incoming container traffic to a specific host interface (Scored)";
docker ps --quiet | xargs docker inspect --format '{{ .Id }}: Ports={{.NetworkSettings.Ports }}' |grep 0.0.0.0
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Remediation:
Bind the container port to a specific host interface on the desired host port.
For example,
docker run --detach --publish 10.2.3.4:49153:80 nginx
In the example above, the container port 80 is bound to the host port on 49153 and would
accept incoming connection only from 10.2.3.4 external interface."; fi

echo "## 5.14 Set the 'on-failure' container restart policy to 5 (Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}:RestartPolicyName={{ .HostConfig.RestartPolicy.Name }} MaximumRetryCount={{.HostConfig.RestartPolicy.MaximumRetryCount }}' | grep RestartPolicyName=always
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Remediation:
If a container is desired to be restarted of its own, then start the container as below:
$> docker run <Run arguments> --restart=on-failure:5 <Container Image Name or ID>
<Command>151 | P a g e
For example,
docker run --detach --restart=on-failure:5 nginx"; fi

echo "## 5.15 Do not share the host's process namespace (Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: PidMode={{.HostConfig.PidMode }}' | grep host
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Remediation:
Do not start a container with '--pid=host' argument.
For example, do not start a container as below:
docker run --interactive --tty --pid=host centos /bin/bash"; fi


echo "## 5.16 Do not share the host's IPC namespace (Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: IpcMode={{.HostConfig.IpcMode }}' | grep host
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Do not start a container with '--ipc=host' argument.
For example, do not start a container as below:
docker run --interactive --tty --ipc=host centos /bin/bash"; fi

echo "## 5.17 Do not directly expose host devices to containers (Not Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Devices={{.HostConfig.Devices }}'
echo "The above command would list out each device with below information:
 CgroupPermissions - For example, rwm
 PathInContainer - Device path within the container
 PathOnHost - Device path on the host
Verify that the host device is needed to be accessed from within the container and the
permissions required are correctly set. If the above command returns [], then the container
does not have access to host devices. This recommendation can be assumed to be
compliant."
if [ "$1" == "-m" ]; then echo "Remediation:
Do not directly expose the host devices to containers. If at all, you need to expose the host
devices to containers, use the correct set of permissions:
For example, do not start a container as below:
docker run --interactive --tty --device=/dev/tty0:/dev/tty0:rwm --
device=/dev/temp_sda:/dev/temp_sda:rwm centos bash
For example, share the host device with correct permissions:
docker run --interactive --tty --device=/dev/tty0:/dev/tty0:rw --
device=/dev/temp_sda:/dev/temp_sda:r centos bash"; fi

echo "## 5.18 Override default ulimit at runtime only if needed (Not Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Ulimits={{.HostConfig.Ulimits }}' | grep  'Ulimits=<no value>';
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Only override the default ulimit settings if needed.
For example, to override default ulimit settings start a container as below:
docker run --ulimit nofile=1024:1024 --interactive --tty centos /bin/bash"; fi

echo "## 5.19 Do not set mount propagation mode to shared (Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}:Propagation={{range $mnt := .Mounts}} {{json $mnt.Propagation}} {{end}}' | grep shared
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Do not mount volumes in shared mode propagation.
For example, do not start container as below:
docker run <Run arguments> --volume=/hostPath:/containerPath:shared <Container Image
Name or ID> <Command>"; fi

echo "## 5.20 Do not share the host's UTS namespace (Scored).162";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: UTSMode={{.HostConfig.UTSMode }}' | grep host
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Remediation:
Do not start a container with '--uts=host' argument.
For example, do not start a container as below:
docker run --rm --interactive --tty --uts=host rhel7.2"; fi

echo "## 5.21 Do not disable default seccomp profile (Scored) ..164";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: SecurityOpt={{.HostConfig.SecurityOpt }}'
echo "The above command should return \"<no value>\" or your modified seccomp profile. If it
returns [seccomp:unconfined], that means this recommendation is non-compliant and the
container is running without any seccomp profiles."
if [ "$1" == "-m" ]; then echo "Remediation:
By default, seccomp profiles are enabled. You do not need to do anything unless you want
to modify and use the modified seccomp profile."; fi

echo "## 5.22 Do not docker exec commands with privileged option (Scored)";
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Remediation:
Do not use --privileged option in docker exec command."; fi

echo "## 5.23 Do not docker exec commands with user option (Scored)";
ausearch -k docker | grep exec | grep user
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Remediation:
Do not use --user option in docker exec command."; fi

echo "## 5.24 Confirm cgroup usage (Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: CgroupParent={{.HostConfig.CgroupParent }}' | cut -d = -f2
echo "The above command would return the cgroup under which the containers are running. If it
is blank, it means containers are running under default docker cgroup. In that case, this
recommendation is compliant. If the containers are found to be running under cgroup
other than the one that was expected, this recommendation is non-compliant."
if [ "$1" == "-m" ]; then echo "Remediation:
Do not use --cgroup-parent option in docker run command unless needed"; fi


echo "## 5.25 Restrict container from acquiring additional privileges (Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: SecurityOpt={{.HostConfig.SecurityOpt }}' | grep no-new-privileges
if [ $? -eq 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Remediation:
Start a container as below:
docker run <run-options> --security-opt=no-new-privileges <IMAGE> <CMD>
For example,
docker run --rm -it --security-opt=no-new-privileges ubuntu bash"; fi


echo "## 5.26 Check container health at runtime (Scored)";
#docker ps --quiet | xargs docker inspect --format '{{ .Id }}: Health={{.State.Health.Status }}'
if [ "$1" == "-m" ]; then echo "Remediation:
Run the container using --health-cmd and the other parameters.
For example,
docker run -d --health-cmd='stat /etc/passwd || exit 1' nginx"; fi

echo "## 5.27 Ensure docker commands always get the latest version of the image (Not Scored)";
echo "Step 1: Open your image repository and list the image version history for the image you
are inspecting.
Step 2: Observe the status when the docker pull command is triggered.
If the status is shown as Image is up to date, it means that you are getting the cached
version of the image.
Step 3: Match the version of the image you are running with the latest version reported in
your repository which tells if you are running the cached version or the latest copy"
if [ "$1" == "-m" ]; then echo "Remediation:
Use proper version pinning mechanisms (the latest tag which is assigned by default is still
vulnerable to caching attacks) to avoid extracting the cached older versions. Version
pinning mechanisms should be used for base images, packages, and entire images too. You
can customize version pinning rules as per your requirements.
Impact:"; fi



echo "## 5.28 Use PIDs cgroup limit (Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: PidsLimit={{.HostConfig.PidsLimit }}' | grep PidsLimit=0
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Remediation:
Use --pids-limit flag while launching the container with an appropriate value.
For example,
docker run -it --pids-limit 100 <Image_ID>
In the above example, the number of processes allowed to run at any given time is set to
100. After a limit of 100 concurrently running processes is reached, docker would restrict
any new process creation."; fi

echo "## 5.29 Do not use Docker's default bridge docker0 (Not Scored)";
docker network ls --quiet | xargs xargs docker network inspect --format '{{ .Name }}:{{ .Options }}' | grep docker0
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Remediation:
Follow Docker documentation and setup a user-defined network. Run all the containers in
the defined network."; fi

echo "## 5.30 Do not share the host's user namespaces (Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: UsernsMode={{.HostConfig.UsernsMode }}'
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Remediation:
Do not share user namespaces between host and containers."; fi

echo "## 5.31 Do not mount the Docker socket inside any containers (Scored)";
docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Volumes={{ .Mounts}}' | grep docker.sock
if [ $? -ne 0 ]; then echo "Ok" ; else echo "Bad"; fi
if [ "$1" == "-m" ]; then echo "Remediation:
Ensure that no containers mount docker.sock as a volume."; fi


echo "## 6.1 Perform regular security audits of your host system and containers (Not Scored)";

echo "## 6.2 Monitor Docker containers usage, performance and metering (Not Scored)";
echo "docker stats $(docker ps --quiet)
The above commands would return CPU, memory and network statistics for every running
container.
"
if [ "$1" == "-m" ]; then echo "Remediation:
Use a software or a container for tracking container usage, reporting performance and
metering."; fi


echo "## 6.3 Backup container data (Not Scored)";
echo "Ask the system administrator whether container data volumes are regularly backed up.
Verify a copy of the backup and ensure that the organization's backup policy is followed.
Additionally, you can execute the below command for each container instance to list the
changed files and directories in the container᾿s filesystem. Ideally, nothing should be stored
on container's filesystem.
docker diff INSTANCE_ID
"
if [ "$1" == "-m" ]; then echo "Remediation:
You should follow your organization's policy for data backup. You can take backup of your
container data volume using '--volumes-from' parameter as below:
$> docker run <Run arguments> --volumes-from INSTANCE_ID -v [host-dir]:[containerdir] <Container Image Name or ID> <Command>
For example,
docker run --volumes-from 699ee3233b96 -v /mybackup:/backup centos tar cvf
/backup/backup.tar /exampledatatobackup
I"; fi

echo "## 6.4 Avoid image sprawl (Not Scored)";
echo "Step 1 Make a list of all image IDs that are currently instantiated by executing below
command:
docker images --quiet | xargs docker inspect --format '{{ .Id }}: Image={{
.Config.Image }}'
Step 2: List all the images present on the system by executing below command:
docker images
Step 3: Compare the list of image IDs populated from Step 1 and Step 2 and find out images
that are currently not being instantiated. If any such unused or old images are found,
discuss with the system administrator the need to keep such images on the system. If such
a need is not justified enough, then this recommendation is non-compliant."
if [ "$1" == "-m" ]; then echo "Remediation:
Keep the set of the images that you actually need and establish a workflow to remove old or
stale images from the host. Additionally, use features such as pull-by-digest to get specific
images from the registry.
Additionally, you can follow below set of steps to find out unused images on the system and
delete them.

Step 1 Make a list of all image IDs that are currently instantiated by executing below
command:187 | P a g e
docker images --quiet | xargs docker inspect --format '{{ .Id }}: Image={{
.Config.Image }}'
Step 2: List all the images present on the system by executing below command:
docker images
Step 3: Compare the list of image IDs populated from Step 1 and Step 2 and find out images
that are currently not being instantiated.
Step 4: Decide if you want to keep the images that are not currently in use. If not delete
them by executing below command:
docker rmi IMAGE_ID
";fi

echo "## 6.5 Avoid container sprawl (Not Scored)";
echo "
Execute docker info to find the total number of containers you have on the host:
docker info --format '{{ .Containers }}'
Now, execute the below commands to find the total number of containers that are actually
running or in the stopped state on the host.
docker info --format '{{ .ContainersStopped }}'
docker info --format '{{ .ContainersRunning }}'
If the difference between the number of containers that are stopped on the host and the
number of containers that are actually running on the host is large (say 25 or more), then
perhaps, the containers are sprawled on the host."
if [ "$1" == "-m" ]; then confirm " DANGER This will  execute docker container prune ARE YOU SURE? " && docker container prune ;fi