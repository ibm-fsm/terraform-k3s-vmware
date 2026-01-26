# Depoy k3s on vSphere

Deploy in under 60 minutes a k3s cluster on vSphere.

## Requirements

* [Terraform](https://www.terraform.io/) - Terraform is an open-source infrastructure as code software tool that provides a consistent CLI workflow to manage hundreds of cloud services. Terraform codifies cloud APIs into declarative configuration files.
* vSphere account - Access to vSphere with the proper authorization to create VMs

---

## IBM TechZone Access to vSphere

If you are an IBMer or Business Parter, you can request access to vSphere through IBM TechZone.

[VMware on IBM Cloud Environments](https://techzone.ibm.com/collection/tech-zone-certified-base-images/journey-vmware-on-ibm-cloud-environments)

Select `Request vCenter access (OCP Gym)`

---

## Pre flight checklist

### 🛠️ Preparing a RHEL Template for Terraform on vSphere

An existing RHEL VM template needs to be created. See the [Packer RHEL 8 & 9 for VMware vSphere](https://github.com/ibm-client-engineering/packer-rhel-vsphere/) project for instructions on building a VM template in vSphere.

### ✅ Install Terraform

> 💡 **Tip:** If you're connecting to vSphere through a **WireGuard VPN**, you might experience **timeouts or connectivity issues**.  
> In such cases, consider running your Terraform commands from a **bastion host** that resides **within the same network or environment** as vSphere.  
> This can help avoid VPN-related latency or firewall restrictions that interfere with the connection.

To install **Terraform** from a **RHEL 8** bastion host, follow these steps:

---
Open a terminal and run:

```bash
sudo yum install -y yum-utils git bind-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum install -y terraform

```

Check the installed version:

```bash
terraform -version
```

### Configure Networking

#### Required Static IPs

There are 4 static IP addresses that are needed.

> 💡 **Important:** The `my` prefix here is the default established in `terraform.tfvars` by `common_prefix`. 
> If you wish to use a different prefix, change the values below and the `common_prefix` variable value.
> Also, the subnet is controlled by the `subnet_cidr` value in the variables, default is `192.168.252.0/24`.

| Type         | Hostname       | IP               | FQDN                  |
|--------------|----------------|------------------|------------------------|
| `haproxy`    | `my-haproxy`      | `192.168.252.9`  | `my-haproxy.gym.lan`      |
| `k3s server` | `my-k3s-server-0` | `192.168.252.10` | `my-k3s-server-0.gym.lan` |
| `k3s server` | `my-k3s-server-1` | `192.168.252.11` | `my-k3s-server-1.gym.lan` |
| `k3s server` | `my-k3s-server-2` | `192.168.252.12` | `my-k3s-server-2.gym.lan` |

The example table above assumes the `base_domain` is set to `gym.lan`

#### 🛠️ How to Set Static IPs in pfSense

1. **Log in to pfSense** via the web UI (usually at `https://192.168.252.1`, default user is `admin`).
2. Navigate to:  
   **Services** → **DNS Forwarder**.
3. Scroll down to **Host Overrides**.
4. For each device:
   - Click **Add**.
   - Set the **IP address** (from the table above).
   - Set the **Hostname** (e.g., `my-haproxy`).
   - Set the **Domain** to `gym.lan` (or appropriate base domain) to form the FQDN.
   - Click **Save**.
5. Click **Apply Changes** at the top of the page.

---

#### 🔁 Verifying DNS Resolution

To ensure the FQDNs resolve correctly:

- Test resolution using:

```bash
nslookup my-haproxy.gym.lan
```

#### 🧭 Enable DNS Forwarder Static Mapping Registration in pfSense

To ensure that your static DHCP mappings (like `my-k3s-agent-0.gym.lan`, etc.) are resolvable via DNS, you need to enable a specific setting in pfSense:

##### ✅ Steps

1. Log in to the **pfSense Web UI**.
2. Navigate to:  
   **Services** → **DNS Forwarder**.
3. Scroll down to the **General DNS Forwarder Options** section.
4. Check the box for: **Register DHCP leases in DNS forwarder**
5. Click **Save** and then **Apply Changes**.

> 💡 This setting controls whether hostnames assigned to static DHCP clients are automatically added to the DNS forwarder or resolver so they can be resolved locally.

### Clone the repository

Clone this repository to your **bastion host**. This will allow you to configure and run terraform.

From the bastion host, run:

```bash
git clone https://github.com/ibm-fsm/terraform-k3s-vmware.git
cd terraform-k3s-vmware

```

### Configure Private Registry (Optional)

If you want to do an offline installation, you can configure a private registry using [Artifactory](https://github.com/ibm-client-engineering/terraform-artifactory-vmware) and follow the product instructions for mirroring the images.

### Define Terraform variables

There is a file called `terraform.tfvars.example`. Copy this file to `terraform.tfvars` and set variables here according to your needs.

```bash
cp terraform.tfvars.example terraform.tfvars
```

<details>
<summary>IBM TechZone Tip</summary>
Use the following commands to configure some of the variables in an IBM TechZone environment.

---

Install `yq`
```shell
sudo curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq
yq --version
```

---

```shell
# Define the source YAML file path
YAML_FILE=~/vmware-ipi.yaml

# --- Update vsphere.pkrvars.hcl ---
echo "Updating vsphere.pkrvars.hcl..."
vsphere_hostname=$(yq e '.vsphere_hostname' "$YAML_FILE")
vsphere_username=$(yq e '.vsphere_username' "$YAML_FILE")
vsphere_password=$(yq e '.vsphere_password' "$YAML_FILE")
vsphere_datacenter=$(yq e '.vsphere_datacenter' "$YAML_FILE")
vsphere_cluster=$(yq e '.vsphere_cluster' "$YAML_FILE")
vsphere_datastore=$(yq e '.vsphere_datastore' "$YAML_FILE")
vsphere_network=$(yq e '.vsphere_network' "$YAML_FILE")
vsphere_folder=$(yq e '.vsphere_folder' "$YAML_FILE")
vsphere_resource_pool=$(yq e '.vsphere_resource_pool' "$YAML_FILE")

# Perform in-place substitutions using sed.
# The 'sed' commands handle the replacement of the existing values.
sed -i \
    -e "s|vsphere_hostname\s*=\s*\".*\"|vsphere_hostname = \"$vsphere_hostname\"|" \
    -e "s|vsphere_username\s*=\s*\".*\"|vsphere_username = \"$vsphere_username\"|" \
    -e "s|vsphere_password\s*=\s*\".*\"|vsphere_password = \"$vsphere_password\"|" \
    -e "s|vsphere_datacenter\s*=\s*\".*\"|vsphere_datacenter = \"$vsphere_datacenter\"|" \
    -e "s|vsphere_cluster\s*=\s*\".*\"|vsphere_cluster = \"$vsphere_cluster\"|" \
    -e "s|vsphere_datastore\s*=\s*\".*\"|vsphere_datastore = \"$vsphere_datastore\"|" \
    -e "s|vsphere_network\s*=\s*\".*\"|vsphere_network = \"$vsphere_network\"|" \
    -e "s|vsphere_folder\s*=\s*\".*\"|vsphere_folder = \"$(echo "$vsphere_folder" | sed -E 's|^/IBMCloud/vm/||')\"|" \
    -e "s|template_name\s*=\s*\".*\"|template_name = \"$(echo "$vsphere_folder" | sed -E 's|^/IBMCloud/vm/||')/linux-rhel-9.4-master\"|" \
    -e "s|vsphere_resource_pool\s*=\s*\".*\"|vsphere_resource_pool = \"$(echo "$vsphere_resource_pool" | sed -E 's|^/IBMCloud/host/ocp-gym/Resources/Cluster Resource Pool/Gym Member Resource Pool/||')\"|" \
    terraform.tfvars

echo "All variables have been updated successfully."
```

</details>

**vSphere Connection and Environment**:

You can skip this section if you used the TechZone tip above.

These variables define the connection details for your vSphere server and the specific environment where the virtual machines will be deployed.

* `base_domain`: The root domain for your cluster. The cluster's domain will be a subdomain of this value (default is `gym.lan`).

* `vsphere_hostname`: The fully qualified domain name (FQDN) of your vSphere server.

* `vsphere_username`: The username for accessing the vSphere server.

* `vsphere_password`: The password for the vSphere user.

* `vsphere_cluster`: The name of the vSphere cluster where the VMs will be deployed.

* `vsphere_datacenter`: The name of the vSphere data center.

* `vsphere_datastore`: The name of the vSphere data store where the VM disks will be located.

* `vsphere_network`: The name of the VM network segment for the cluster nodes.

* `vsphere_folder`: The path to the vSphere folder where the VMs will be created.

* `vsphere_resource_pool`: The name of the resource pool to use for the VMs. Use only the name of the resource pool, not the full path.

**Environment and Template**:

* `template_name`: The path and name of the base VM template used to clone the new cluster nodes. This template should be a RHEL image that is supported by k3s.

* `subnet_cidr`: The CIDR block for the cluster's subnet (default is `192.168.252.0/24`).

* `common_prefix`: The prefix used for all hostnames and identifiers (default is `my`).

* `haproxy_ip`: The IP address of the HAProxy server (default is `192.168.252.9`).

* `k3s_server_ips`: The static IP addresses of the 3 server nodes (default is `["192.168.252.10", "192.168.252.11", "192.168.252.12"]`)

**Red Hat Subscription Manager Credentials**:

Ensure that the account used has a valid RedHat subscription.

* `rhsm_username`: The username for your Red Hat Subscription Management (RHSM) account. This is typically your login to the Red Hat Customer Portal.

* `rhsm_password`: The password for your RHSM account.

**K3s Configuration**:

These variables control the installation of K3s.

* `k3s_agent_count`: The number of K3s agent nodes to create in the cluster.

* `install_k3s`: A boolean value to enable or disable the K3s installation.

**Private Registry Configuration (Optional)**:

These variables are used if you are pulling container images from a private registry instead of the public default registry.

* `use_private_registry`: A boolean to enable the use of a private registry.

* `private_registry_host`: The hostname of the private registry.

* `private_registry_port`: The port number for the private registry.

* `private_registry_repo`: The name of the repository in the private registry.

* `private_registry_user`: The username for logging into the private registry.

* `private_registry_user_password`: The password for the private registry user.

## Deploy

We are now ready to deploy our infrastructure. First we must initialize terraform.

```shell
terraform init
```

Expected output:

```
Initializing the backend...
Initializing modules...
Initializing provider plugins...
- Reusing previous version of hashicorp/cloudinit from the dependency lock file
- Reusing previous version of hashicorp/tls from the dependency lock file
- Reusing previous version of vmware/vsphere from the dependency lock file
- Reusing previous version of hashicorp/local from the dependency lock file
- Reusing previous version of hashicorp/random from the dependency lock file
- Using previously-installed hashicorp/tls v4.1.0
- Using previously-installed vmware/vsphere v2.15.0
- Using previously-installed hashicorp/local v2.5.3
- Using previously-installed hashicorp/random v3.7.2
- Using previously-installed hashicorp/cloudinit v2.3.7

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Now that we are initialized, we ask terraform to plan the execution with: 

```shell
terraform plan
```

If everything is ok the output should be something like this:

```
...skip

Plan: 18 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + haproxy_ip_address = (known after apply)
  + vm_ip_addresses    = [
      + (known after apply),
      + (known after apply),
      + (known after apply),
    ]
```

now we can deploy our resources with:

```shell
terraform apply
```

Sample output:
```
...skip

Plan: 18 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + haproxy_ip_address = (known after apply)
  + vm_ip_addresses    = [
      + (known after apply),
      + (known after apply),
      + (known after apply),
    ]

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

...skip

Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

Outputs:

haproxy_ip_address = "192.168.252.9"
vm_ip_addresses = [
  "192.168.252.10",
  "192.168.252.11",
  "192.168.252.12",
]
```

### Check progress of installation

You can ssh to any of the server nodes found in the output of `vm_ip_addresses` using `clouduser`. The following command opens an SSH session with `my-k3s-server-0`.

```bash
sed -i '/^my-k3s-/d' ~/.ssh/known_hosts && ssh -o StrictHostKeyChecking=no -i ./modules/k3s-vmware/id_rsa clouduser@my-k3s-server-0
```

> 💡 **Tip:** The default password for clouduser is `mypassword`

Optionally, change to the root user on the server node.

```bash
sudo su -
```

List the nodes:
```bash
kubectl get nodes
```

Sample output:
```
NAME                   STATUS   ROLES                       AGE     VERSION
my-k3s-agent-0.gym.lan    Ready    worker                      5m38s   v1.31.7+k3s1
my-k3s-agent-1.gym.lan    Ready    worker                      5m38s   v1.31.7+k3s1
my-k3s-agent-2.gym.lan    Ready    worker                      5m38s   v1.31.7+k3s1
my-k3s-agent-3.gym.lan    Ready    worker                      5m37s   v1.31.7+k3s1
my-k3s-agent-4.gym.lan    Ready    worker                      5m39s   v1.31.7+k3s1
my-k3s-agent-5.gym.lan    Ready    worker                      5m41s   v1.31.7+k3s1
my-k3s-server-0.gym.lan   Ready    control-plane,etcd,master   5m56s   v1.31.7+k3s1
my-k3s-server-1.gym.lan   Ready    control-plane,etcd,master   5m21s   v1.31.7+k3s1
my-k3s-server-2.gym.lan   Ready    control-plane,etcd,master   5m10s   v1.31.7+k3s1
```

List all pods:
```
kubectl get pods -A
```

List all pods that are in unhealthy state:
```
kubectl get pods -A | grep -vE 'Completed|([0-9]+)/\1'
```

Follow the launch template script output (as `root`):
```
tail -f /var/log/cloud-init-output.log
```
This can be run from any node, it will show the verbose output of the launch scripts found in this repo under `cloudinit` for the appropriate node or instance type.

## Destroy

To destroy all resources, run the following command.

```
terraform destroy -auto-approve
```