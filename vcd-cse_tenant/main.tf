terraform {
  required_providers {
    vcd = { source = "vmware/vcd" }
  }
}

provider "vcd" {
  user                 = var.vcd_user
  password             = var.vcd_pass
  auth_type            = "integrated"
  url                  = "https://${var.vcd_url}/api"
  org                  = "System"
  allow_unverified_ssl = true
}

resource "vcd_org" "cse" {
  name             = "cse"
  full_name        = "cse"
  is_enabled       = "true"
  delete_recursive = "true"
  delete_force     = "true"
  vapp_lease {
    maximum_runtime_lease_in_sec          = 0
    power_off_on_runtime_lease_expiration = false
    maximum_storage_lease_in_sec          = 0
    delete_on_storage_lease_expiration    = false
  }
  vapp_template_lease {
    maximum_storage_lease_in_sec       = 0
    delete_on_storage_lease_expiration = false
  }
}

resource "vcd_org_vdc" "cse" {
  name                       = "cse"
  org                        = vcd_org.cse.name
  allocation_model           = "Flex"
  network_pool_name          = var.network_pool
  provider_vdc_name          = var.provider_vdc
  elasticity                 = "false"
  include_vm_memory_overhead = "false"
  network_quota              = 10
  compute_capacity {
    cpu {
      allocated = "10000"
      limit     = "0"
    }
    memory {
      allocated = "10240"
      limit     = "0"
    }
  }
  storage_profile {
    name    = var.storage_class
    enabled = true
    limit   = 0
    default = true
  }
  enabled                  = true
  enable_thin_provisioning = true
  delete_force             = true
  delete_recursive         = true
}

resource "vcd_catalog" "cse" {
  org              = "cse"
  name             = "cse"
  delete_recursive = "true"
  delete_force     = "true"
}

data "vcd_external_network_v2" "t0" {
  name = var.tier0
}

resource "vcd_nsxt_edgegateway" "egw" {
  org                 = "cse"
  vdc                 = "cse"
  name                = "t1-cse"
  external_network_id = data.vcd_external_network_v2.t0.id
  subnet {
    gateway       = tolist(data.vcd_external_network_v2.t0.ip_scope)[0].gateway
    prefix_length = tolist(data.vcd_external_network_v2.t0.ip_scope)[0].prefix_length
    primary_ip    = var.primary_ip
    allocated_ips {
      start_address = var.primary_ip
      end_address   = var.primary_ip
    }
  }
}

resource "vcd_nsxt_firewall" "allow_all" {
  org             = "cse"
  vdc             = "cse"
  edge_gateway_id = vcd_nsxt_edgegateway.egw.id
  rule {
    action      = "ALLOW"
    name        = "allow all IPv4 traffic"
    direction   = "IN_OUT"
    ip_protocol = "IPV4"
  }
}

resource "vcd_nsxt_nat_rule" "snat" {
  org              = "cse"
  vdc              = "cse"
  edge_gateway_id  = vcd_nsxt_edgegateway.egw.id
  name             = "0/0"
  rule_type        = "SNAT"
  external_address = tolist(vcd_nsxt_edgegateway.egw.subnet)[0].primary_ip
  internal_address = "0.0.0.0/0"
}

resource "vcd_network_routed_v2" "cse-builder" {
  org             = "cse"
  vdc             = "cse"
  name            = "cse-builder"
  edge_gateway_id = vcd_nsxt_edgegateway.egw.id
  gateway         = "192.168.0.1"
  prefix_length   = 24
  dns1            = "8.8.8.8"
  static_ip_pool {
    start_address = "192.168.0.10"
    end_address   = "192.168.0.100"
  }
}
