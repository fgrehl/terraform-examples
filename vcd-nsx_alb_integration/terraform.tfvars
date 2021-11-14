# vCenter variables
vsphere_server   = "vcenter.virten.lab"
vsphere_user     = "administrator@vsphere.local"
vsphere_password = ""
vc_datacenter    = "Datacenter"
vc_cluster       = "NUCluster"
vc_datastore     = "bort-red01"
vc_contentlib    = "NSX-ALB" # Content Library is created by TF

# NSX-T Manager variables
nsx_manager     = "nsx1.virten.lab"
nsx_user        = "admin"
nsx_password    = ""
nsx_overlay_tz  = "nsx-overlay-transportzone"
nsx_edgecluster = "edgeCluster1"
nsx_tier0       = "tier0-k8s"

# NSX-T ALB variables
alb_username   = "admin"
alb_tenant     = "admin"
alb_password   = ""
alb_controller = "avi.virten.lab"
alb_version    = "21.1.1"
alb_se_cidr    = "10.99.4.0/24" # SE Tier-0 and Segment is created by TF.

# Cloud Director variables
vcd_user = "administrator"
vcd_pass = ""
vcd_url  = "vcloud.virten.lab"
