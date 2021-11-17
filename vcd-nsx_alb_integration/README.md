# NSX-T Advanced Load Balancer Integation in VMware Cloud Director
Terraform manifest to integrate NSX-ALB in Cloud Director.

Reference: https://www.virten.net/2021/11/nsx-alb-integration-in-vmware-cloud-director-10-3-with-terraform/

## Prerequisites
See this article for prerequisites and manual steps: https://www.virten.net/2021/10/getting-started-with-nsx-advanced-load-balancer-integration-in-vmware-cloud-director-10-3/

- vCenter, ESX, Cloud Director and NSX-T installed and configured.
- NSX-T: Tier-0 Gateway configured with any kind of external connection.
- Cloud Director: Network Pool, Tier-0 Gateway (External Network) and Provider VDC ready to host tenants.
- ALB Controller deployed and basic configuration done.
- ALB Controller default certificate replaced.
- ALB Controller certificate must be trusted by VCD.

## Versions used
- VMware Cloud Director 10.3.1
- NSX-T 3.1.3.1
- NSX-T Advanced Loadbalancer 21.1.1

## Usage
Fill out terraforms.tfvars and deploy.

```
# terraform init
# terraform plan
# terraform apply

Plan: 14 to add, 0 to change, 0 to destroy.
avi_cloudconnectoruser.nsx: Creating...
avi_cloudconnectoruser.vcenter: Creating...
vsphere_content_library.library: Creating...
vcd_nsxt_alb_controller.alb: Creating...
avi_cloudconnectoruser.nsx: Creation complete after 1s [id=https://avi.virten.lab/api/cloudconnectoruser/cloudconnectoruser-299be94d-63cb-4596-90a5-f7a7be209c21]
nsxt_policy_dhcp_server.alb: Creating...
nsxt_policy_tier1_gateway.dummy: Creating...
nsxt_policy_dhcp_server.alb: Creation complete after 0s [id=ae5ff22f-1721-4c41-ae71-6b86a903dfad]
nsxt_policy_tier1_gateway.alb: Creating...
vsphere_content_library.library: Creation complete after 1s [id=84cfb378-b65b-4986-abd3-d6ca008030a7]
nsxt_policy_tier1_gateway.dummy: Creation complete after 0s [id=693a4050-4893-4cd9-a6eb-c48d0fee0e8b]
nsxt_policy_segment.dummy: Creating...
nsxt_policy_tier1_gateway.alb: Creation complete after 2s [id=adaaf508-aea8-4a46-990f-7dad161cc932]
nsxt_policy_segment.alb_se: Creating...
nsxt_policy_segment.dummy: Creation complete after 2s [id=042a102d-7c95-498e-92be-e88748454c03]
avi_cloudconnectoruser.vcenter: Creation complete after 3s [id=https://avi.virten.lab/api/cloudconnectoruser/cloudconnectoruser-0150f1a8-bf05-412a-a725-7e1fcfbaa014]
nsxt_policy_segment.alb_se: Creation complete after 1s [id=744084fd-d5e3-475c-8365-f38d7887a79c]
avi_cloud.nsx: Creating...
vcd_nsxt_alb_controller.alb: Creation complete after 4s [id=urn:vcloud:loadBalancerController:576465c0-d17f-4371-b403-348faa52d268]
avi_cloud.nsx: Creation complete after 0s [id=https://avi.virten.lab/api/cloud/cloud-cbbbe754-2530-45f4-826e-e128b3a4b9c8]
data.vcd_nsxt_alb_importable_cloud.nsx: Reading...
avi_vcenterserver.vcenter: Creating...
avi_vcenterserver.vcenter: Creation complete after 0s [id=https://avi.virten.lab/api/vcenterserver/vcenterserver-0c490604-829b-42a9-8806-746de39672f3]
avi_serviceenginegroup.sseg_01: Creating...
avi_serviceenginegroup.sseg_01: Creation complete after 0s [id=https://avi.virten.lab/api/serviceenginegroup/serviceenginegroup-db12208a-df82-4ed5-adb0-fcb3875bf7fd]
data.vcd_nsxt_alb_importable_cloud.nsx: Read complete after 1s [id=cloud-cbbbe754-2530-45f4-826e-e128b3a4b9c8]
vcd_nsxt_alb_cloud.nsx: Creating...
vcd_nsxt_alb_cloud.nsx: Creation complete after 3s [id=urn:vcloud:loadBalancerCloud:24f3165d-4473-4223-8f2f-65896f5aec13]
vcd_nsxt_alb_service_engine_group.sseg_01: Creating...
vcd_nsxt_alb_service_engine_group.sseg_01: Creation complete after 3s [id=urn:vcloud:serviceEngineGroup:e197845d-4aed-406c-9398-b899ba39c65b]

Apply complete! Resources: 14 added, 0 changed, 0 destroyed.
```
