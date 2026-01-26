module "k3s_linux" {

  source = "./modules/k3s-vmware/"

  # -----------------------------------
  # VSPHERE CONNECTION / LOCATION VARS
  # -----------------------------------
  vsphere_username      = var.vsphere_username
  vsphere_password      = var.vsphere_password
  vsphere_hostname      = var.vsphere_hostname
  vsphere_datacenter    = var.vsphere_datacenter
  vsphere_cluster       = var.vsphere_cluster
  vsphere_datastore     = var.vsphere_datastore
  vsphere_network       = var.vsphere_network
  vsphere_folder        = var.vsphere_folder
  vsphere_resource_pool = var.vsphere_resource_pool
  template_name         = var.template_name

  # -----------------------------------
  # RHEL VARS
  # -----------------------------------
  rhsm_username = var.rhsm_username
  rhsm_password = var.rhsm_password

  # -----------------------------------
  # CLUSTER & NAMING VARS
  # -----------------------------------
  common_prefix    = var.common_prefix
  k3s_server_count = var.k3s_server_count
  k3s_agent_count  = var.k3s_agent_count
  install_k3s      = var.install_k3s
  base_domain      = var.base_domain

  # -----------------------------------
  # NETWORK CONFIGURATION VARS
  # -----------------------------------
  subnet_cidr    = var.subnet_cidr
  haproxy_ip     = var.haproxy_ip
  k3s_server_ips = var.k3s_server_ips

  # -----------------------------------
  # PRIVATE REGISTRY CONFIGURATION VARS
  # -----------------------------------
  use_private_registry           = var.use_private_registry
  private_registry_host          = var.private_registry_host
  private_registry_repo          = var.private_registry_repo
  private_registry_port          = var.private_registry_port
  private_registry_user          = var.private_registry_user
  private_registry_user_password = var.private_registry_user_password
  private_registry_skip_tls      = var.private_registry_skip_tls
}