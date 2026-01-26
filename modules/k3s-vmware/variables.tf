variable "rhsm_username" {
  type        = string
  description = "The username for your Red Hat Subscription Management account."
}

variable "rhsm_password" {
  type        = string
  description = "The password for your Red Hat Subscription Management account."
}

// vSphere Credentials

variable "vsphere_hostname" {
  type        = string
  description = "The fully qualified domain name or IP address of the vCenter Server instance."
}

variable "vsphere_username" {
  type        = string
  description = "The username to login to the vCenter Server instance."
  sensitive   = true
}

variable "vsphere_password" {
  type        = string
  description = "The password for the login to the vCenter Server instance."
  sensitive   = true
}

variable "vsphere_datacenter" {
  type        = string
  description = "The name of the vSphere Datacenter into which resources will be created."
}

variable "vsphere_cluster" {
  type        = string
  description = "The vSphere Cluster into which resources will be created."
}

variable "vsphere_datastore" {
  type        = string
  description = "The vSphere Datastore into which resources will be created."
}

variable "vsphere_network" {
  type        = string
  description = "The name of the target vSphere network segment."
}

variable "template_name" {
  type = string
}

variable "secondary_disk_size" {
  type        = number
  default     = 30
  description = "How big we want our disk in case we don't like defaults."
}

variable "nameservers" {
  type    = list(any)
  default = []
}

variable "vsphere_folder" {
  type        = string
  description = "The name of the target vSphere folder."
}

variable "vsphere_resource_pool" {
  type        = string
  description = "The name of the target vSphere resource pool."
}

variable "k3s_server_count" {
  type    = number
  default = 3
}

variable "k3s_agent_count" {
  type    = number
  default = 3
}

variable "cpu_pool" {
  type        = number
  description = "The total number of vCPUs to allocate across the entire cluster (Servers + Agents). Used to calculate per-node CPU."
  default     = 24
}

variable "mem_pool_gb" {
  type        = number
  description = "The total amount of Memory (in GB) to allocate across the entire cluster. Used to calculate per-node RAM."
  default     = 48
}

variable "install_k3s" {
  type        = string
  description = "Set to 'true' to install K3s. If set to 'true', 'accept_license' must also be 'true'."
  default     = "true"
}

variable "common_prefix" {
  type    = string
  default = "my"
}

variable "subnet_cidr" {
  type        = string
  default     = "192.168.252.0/24"
  description = "Subnet CIDR for the cluster."
}

variable "haproxy_ip" {
  type        = string
  default     = "192.168.252.9"
  description = "IP address for the haproxy."
}

variable "k3s_server_ips" {
  type        = list(string)
  default     = ["192.168.252.10", "192.168.252.11", "192.168.252.12"]
  description = "IP addresses for the k3s server nodes."
  validation {
    # The condition checks that the length of the list is exactly
    # equal to the value of the k3s_server_count variable.
    condition = length(var.k3s_server_ips) == var.k3s_server_count
    # The error message includes the expected number of items.
    error_message = "The list must contain exactly ${var.k3s_server_count} values."
  }
}

variable "base_domain" {
  type    = string
  default = "gym.lan"
}

variable "run_observers" {
  type        = bool
  default     = true
  description = "Run VMware vCenter and kubernetes observers post install"
}

// Private registry variables

variable "use_private_registry" {
  default     = false
  type        = bool
  description = "Use a private registry, something other than cp.icr.io"
}

variable "private_registry_host" {
  default     = ""
  type        = string
  description = "DNS or IP of private registry hosting the container images"

  validation {
    condition     = !(var.use_private_registry && trimspace(var.private_registry_host) == "")
    error_message = "private_registry_host must not be empty when use_private_registry is true."
  }
}

variable "private_registry_repo" {
  default     = ""
  type        = string
  description = "Repository name, to be appended to host:port when building registry URL (e.g. host:port/repo)"
}

variable "private_registry_port" {
  default     = 5000
  type        = number
  description = "Port number for private registry"
}

variable "private_registry_user" {
  default     = "registryuser"
  type        = string
  description = "Login user for private registry"
}

variable "private_registry_user_password" {
  default     = "registryuserpassword"
  type        = string
  description = "Login user password for private registry"
}

variable "private_registry_skip_tls" {
  default     = true
  type        = bool
  description = "Skip TLS verification for private registry"
}
