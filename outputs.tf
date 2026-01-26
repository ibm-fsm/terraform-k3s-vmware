output "vm_ip_addresses" {
  description = "The IP address of the vSphere virtual machine"
  value       = module.k3s_linux.vm_ip_addresses
}

output "haproxy_ip_address" {
  description = "The IP address of the haproxy virtual machine"
  value       = module.k3s_linux.haproxy_ip_address
}
