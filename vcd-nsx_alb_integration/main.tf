terraform {
  required_providers {
    avi = {
      source  = "vmware/avi"
      version = "21.1.1"
    }
    vsphere = { source = "hashicorp/vsphere" }
    nsxt    = { source = "vmware/nsxt" }
    vcd     = { source = "vmware/vcd" }

  }
}

provider "avi" {
  avi_username   = var.alb_username
  avi_tenant     = var.alb_tenant
  avi_password   = var.alb_password
  avi_controller = var.alb_controller
  avi_version    = var.alb_version
}

provider "nsxt" {
  host                 = var.nsx_manager
  username             = var.nsx_user
  password             = var.nsx_password
  allow_unverified_ssl = true
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

provider "vcd" {
  user                 = var.vcd_user
  password             = var.vcd_pass
  auth_type            = "integrated"
  url                  = "https://${var.vcd_url}/api"
  org                  = "System"
  allow_unverified_ssl = true
}


# vCenter: Create Content Library
# Step 2 in https://www.virten.net/2021/10/getting-started-with-nsx-advanced-load-balancer-integration-in-vmware-cloud-director-10-3/
data "vsphere_datacenter" "dc" { name = var.vc_datacenter }
data "vsphere_compute_cluster" "cluster" {
  name          = var.vc_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_datastore" "datastore" {
  name          = var.vc_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Create Content Library
resource "vsphere_content_library" "library" {
  name            = var.vc_contentlib
  storage_backing = [data.vsphere_datastore.datastore.id]
}

# NSX-T Create SE Management Network with DHCP
# Step 3 in https://www.virten.net/2021/10/getting-started-with-nsx-advanced-load-balancer-integration-in-vmware-cloud-director-10-3/
data "nsxt_policy_transport_zone" "overlay" {
  display_name = var.nsx_overlay_tz
}
data "nsxt_policy_edge_cluster" "ec" {
  display_name = var.nsx_edgecluster
}
data "nsxt_policy_tier0_gateway" "t0" {
  display_name = var.nsx_tier0
}

# Create DHCP Server Profile for Service Engine Network
resource "nsxt_policy_dhcp_server" "alb" {
  display_name      = "alb-management"
  edge_cluster_path = data.nsxt_policy_edge_cluster.ec.path
}

# Create Tier-1 Gateway and Segment for Service Engines. The upstream Tier-0 must exist and the configured network must be routable from the ALB Controller.
resource "nsxt_policy_tier1_gateway" "alb" {
  display_name              = "tier1-alb"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.ec.path
  tier0_path                = data.nsxt_policy_tier0_gateway.t0.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]
  dhcp_config_path          = nsxt_policy_dhcp_server.alb.path
}
resource "nsxt_policy_segment" "alb_se" {
  display_name        = "seg-${cidrhost(var.alb_se_cidr, 0)}-alb-se"
  connectivity_path   = nsxt_policy_tier1_gateway.alb.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay.path
  subnet {
    cidr        = "${cidrhost(var.alb_se_cidr, 1)}/${split("/", var.alb_se_cidr)[1]}"
    dhcp_ranges = ["${cidrhost(var.alb_se_cidr, 10)}-${cidrhost(var.alb_se_cidr, 100)}"]
  }
}

# Dummy Tier-1 and Segment, required for the initial NSX-T Cloud configuration in NSX-ALB.
resource "nsxt_policy_tier1_gateway" "dummy" {
  display_name              = "tier1-dummy"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.ec.path
  tier0_path                = data.nsxt_policy_tier0_gateway.t0.path
  route_advertisement_types = []
}
resource "nsxt_policy_segment" "dummy" {
  display_name        = "seg-alb-dummy"
  connectivity_path   = nsxt_policy_tier1_gateway.dummy.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay.path
  subnet {
    cidr = "10.255.255.1/24"
  }
}

# NSX-ALB: Create NSX-T Cloud
# Step 4 in https://www.virten.net/2021/10/getting-started-with-nsx-advanced-load-balancer-integration-in-vmware-cloud-director-10-3/

# ALB Users for vCenter and NSX-T
resource "avi_cloudconnectoruser" "vcenter" {
  name = var.vsphere_server
  vcenter_credentials {
    username = var.vsphere_user
    password = var.vsphere_password
  }
  lifecycle { ignore_changes = [vcenter_credentials] }
}
resource "avi_cloudconnectoruser" "nsx" {
  name = var.nsx_manager
  nsxt_credentials {
    username = var.nsx_user
    password = var.nsx_password
  }
  lifecycle { ignore_changes = [nsxt_credentials] }
}

# Create NSX-T Cloud
resource "avi_cloud" "nsx" {
  name            = var.nsx_manager
  vtype           = "CLOUD_NSXT"
  dhcp_enabled    = true
  obj_name_prefix = split(".", var.nsx_manager)[0]
  nsxt_configuration {
    nsxt_url             = var.nsx_manager
    nsxt_credentials_ref = avi_cloudconnectoruser.nsx.id
    management_network_config {
      transport_zone = data.nsxt_policy_transport_zone.overlay.path
      tz_type        = "OVERLAY"
      overlay_segment {
        tier1_lr_id = nsxt_policy_tier1_gateway.alb.path
        segment_id  = nsxt_policy_segment.alb_se.path
      }
    }
    data_network_config {
      transport_zone = data.nsxt_policy_transport_zone.overlay.path
      tz_type        = "OVERLAY"
      tier1_segment_config {
        segment_config_mode = "TIER1_SEGMENT_MANUAL"
        manual {
          tier1_lrs {
            tier1_lr_id = nsxt_policy_tier1_gateway.dummy.path
            segment_id  = nsxt_policy_segment.dummy.path
          }
        }
      }
    }
  }
}
resource "avi_vcenterserver" "vcenter" {
  name = var.vsphere_server
  content_lib {
    id = vsphere_content_library.library.id
  }
  vcenter_url             = var.vsphere_server
  vcenter_credentials_ref = avi_cloudconnectoruser.vcenter.id
  cloud_ref               = avi_cloud.nsx.id
}

# NSX-ALB: Create Service Engine Group
# Step 5 in https://www.virten.net/2021/10/getting-started-with-nsx-advanced-load-balancer-integration-in-vmware-cloud-director-10-3/

resource "avi_serviceenginegroup" "sseg_01" {
  name           = "${split(".", var.nsx_manager)[0]}-seg-01"
  se_name_prefix = split(".", var.nsx_manager)[0]
  ha_mode        = "HA_MODE_SHARED" # (Elastic HA N+M Buffer)
  algo           = "PLACEMENT_ALGO_PACKED"
  max_se         = 10
  max_vs_per_se  = 10
  cloud_ref      = avi_cloud.nsx.id
  vcenters {
    vcenter_ref = avi_vcenterserver.vcenter.id
    nsxt_datastores {
      include = true
      ds_ids  = [data.vsphere_datastore.datastore.id]
    }
    nsxt_clusters {
      include     = true
      cluster_ids = [data.vsphere_compute_cluster.cluster.id]
    }
  }
}

# Add ALB Controller and Service Engine Group to Cloud Director
# Step 6 in https://www.virten.net/2021/10/getting-started-with-nsx-advanced-load-balancer-integration-in-vmware-cloud-director-10-3/

# Add NSX-T ALB Controller to VCD. Must use a valid and trusted certificate.
resource "vcd_nsxt_alb_controller" "alb" {
  name         = var.alb_controller
  url          = "https://${var.alb_controller}"
  username     = var.alb_username
  password     = var.alb_password
  license_type = "ENTERPRISE"
}

# Helper Datasoure to grab Cloud ID and Network Pool for NSX-T Cloud
data "vcd_nsxt_alb_importable_cloud" "nsx" {
  name          = avi_cloud.nsx.name
  controller_id = vcd_nsxt_alb_controller.alb.id
}

# Import ALB NSX-T Cloud
resource "vcd_nsxt_alb_cloud" "nsx" {
  name                = var.nsx_manager
  controller_id       = vcd_nsxt_alb_controller.alb.id
  importable_cloud_id = data.vcd_nsxt_alb_importable_cloud.nsx.id
  network_pool_id     = data.vcd_nsxt_alb_importable_cloud.nsx.network_pool_id
}

# Import Service Engine Group as Shared SEG
resource "vcd_nsxt_alb_service_engine_group" "sseg_01" {
  name                                 = "${split(".", var.nsx_manager)[0]}-seg-01"
  alb_cloud_id                         = vcd_nsxt_alb_cloud.nsx.id
  importable_service_engine_group_name = "${split(".", var.nsx_manager)[0]}-seg-01"
  reservation_model                    = "SHARED"
  sync_on_refresh                      = false
}
