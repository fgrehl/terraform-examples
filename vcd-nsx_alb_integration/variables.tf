variable "vsphere_server" { type = string }
variable "vsphere_user" { type = string }
variable "vsphere_password" { type = string }
variable "vc_datacenter" { type = string }
variable "vc_cluster" { type = string }
variable "vc_datastore" { type = string }
variable "vc_contentlib" { type = string }

variable "nsx_manager" { type = string }
variable "nsx_user" { type = string }
variable "nsx_password" { type = string }
variable "nsx_overlay_tz" { type = string }
variable "nsx_edgecluster" { type = string }
variable "nsx_tier0" { type = string }

variable "alb_username" { type = string }
variable "alb_tenant" { type = string }
variable "alb_password" { type = string }
variable "alb_controller" { type = string }
variable "alb_version" { type = string }
variable "alb_se_cidr" { type = string }

variable "vcd_user" { type = string }
variable "vcd_pass" { type = string }
variable "vcd_url" { type = string }
