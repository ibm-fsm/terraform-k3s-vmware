resource "tls_private_key" "deployer" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.deployer.private_key_pem
  filename        = "${path.module}/id_rsa"
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content  = tls_private_key.deployer.public_key_openssh
  filename = "${path.module}/id_rsa.pub"
}

# --- 1. Create a Self-Signed CA (Certificate Authority) ---
# This acts as the "Root of Trust" for your lab.
resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem   = tls_private_key.ca.private_key_pem
  is_ca_certificate = true

  subject {
    common_name  = "k3s-lab-ca"
    organization = "My Lab"
  }

  validity_period_hours = 87600 # 10 years
  
  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

# --- 2. Create the LDAP Service Certificate ---
# This is the cert specifically for the OpenLDAP pod.
resource "tls_private_key" "ldap" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "ldap" {
  private_key_pem = tls_private_key.ldap.private_key_pem

  subject {
    common_name  = "ldap-service.openldap.svc.cluster.local"
    organization = "My Lab"
  }

  # SANs (Subject Alternative Names) are critical for K8s internal DNS
  dns_names = [
    "ldap-service",
    "ldap-service.openldap",
    "ldap-service.openldap.svc",
    "ldap-service.openldap.svc.cluster.local"
  ]
}

# --- 3. Sign the LDAP Cert with your CA ---
resource "tls_locally_signed_cert" "ldap" {
  cert_request_pem   = tls_cert_request.ldap.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}