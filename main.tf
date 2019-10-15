# Configure the VMware NSX-T Provider
provider "nsxt" {
    host = "${var.nsx["ip"]}"
    username = "${var.nsx["user"]}"
    password = "${var.nsx["password"]}"
    allow_unverified_ssl = true
}

# nsx data sources
data "nsxt_transport_zone" "overlay_tz" {
    display_name = "${var.nsx_data_vars["transport_zone"]}"
}

data "nsxt_logical_tier0_router" "tier0_router" {
  display_name = "${var.nsx_data_vars["t0_router_name"]}"
}

# Configure the VMware vSphere Provider
provider "vsphere" {
    user           = "${var.vsphere["vsphere_user"]}"
    password       = "${var.vsphere["vsphere_password"]}"
    vsphere_server = "${var.vsphere["vsphere_ip"]}"
    allow_unverified_ssl = true
}

# data source for my vSphere Data Center
data "vsphere_datacenter" "dc" {
  name = "${var.vsphere["dc"]}"
}

# Datastore data source
data "vsphere_datastore" "datastore" {
  name          = "${var.vsphere["datastore"]}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

# data source for my cluster's default resource pool
data "vsphere_resource_pool" "pool" {
  name          = "${var.vsphere["resource_pool"]}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

# Data source for the template I am going to use to clone my VM from
data "vsphere_virtual_machine" "template" {
    name = "${var.vsphere["vm_template"]}"
    datacenter_id = "${data.vsphere_datacenter.dc.id}"
}


# Create MyApp NSX-T Logical Switch
resource "nsxt_logical_switch" "MyApp-LS" {
    admin_state = "UP"
    description = "Segment created by Terraform"
    display_name = "MyApp-L2-Segment"
    transport_zone_id = "${data.nsxt_transport_zone.overlay_tz.id}"
    replication_mode = "MTEP"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}


# Create T1 router
resource "nsxt_logical_tier1_router" "tier1_router" {
  description                 = "Tier1 router provisioned by Terraform"
  display_name                = "${var.nsx_rs_vars["t1_router_name"]}"
  # failover_mode               = "PREEMPTIVE"
  # edge_cluster_id             = "${data.nsxt_edge_cluster.edge_cluster1.id}"
  enable_router_advertisement = true
  advertise_connected_routes  = true
  # advertise_static_routes     = true
  # advertise_nat_routes        = true
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create a port on the T0 router. We will connect the T1 router to this port
resource "nsxt_logical_router_link_port_on_tier0" "link_port_tier0" {
  description       = "LogicalRouterLinkPortOnTIER0 provisioned by Terraform"
  display_name      = "RLP-on-T0"
  logical_router_id = "${data.nsxt_logical_tier0_router.tier0_router.id}"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create a T1 uplink port and connect it to T0 router
resource "nsxt_logical_router_link_port_on_tier1" "link_port_tier1" {
  description                   = "LogicalRouterLinkPortOnTIER1 provisioned by Terraform"
  display_name                  = "RLP-on-T1"
  logical_router_id             = "${nsxt_logical_tier1_router.tier1_router.id}"
  linked_logical_router_port_id = "${nsxt_logical_router_link_port_on_tier0.link_port_tier0.id}"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create a switchport on MyApp logical switch
resource "nsxt_logical_port" "logical_port2" {
  admin_state       = "UP"
  description       = "logical port provisioned by Terraform"
  display_name      = "MyAppLSLPtoT1"
  logical_switch_id = "${nsxt_logical_switch.MyApp-LS.id}"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create downlink port on the T1 router and connect it to the switchport we created earlier
resource "nsxt_logical_router_downlink_port" "downlink_port2" {
  description                   = "Logical Router Downlink Port provisioned by Terraform"
  display_name                  = "Downlink Router Port to MyApp-LS"
  logical_router_id             = "${nsxt_logical_tier1_router.tier1_router.id}"
  linked_logical_switch_port_id = "${nsxt_logical_port.logical_port2.id}"
  ip_address                    = "${var.nsx_rs_vars["ip"]}/${var.nsx_rs_vars["mask"]}"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
}

# Create NSGROUP with dynamic membership criteria
# all Virtual Machines with the specific tag and scope
resource "nsxt_ns_group" "nsgroup" {
  description  = "NSGroup provisioned by Terraform"
  display_name = "terraform-demo-sg-all-vms"
  membership_criteria {
    target_type = "VirtualMachine"
    scope       = "${var.nsx_tag_scope}"
    tag         = "${var.nsx_tag}"
  }
    tag {
	scope = "${var.nsx_tag_scope}"
	tag = "${var.nsx_tag}"
    }
}

# Create Web NSGROUP
resource "nsxt_ns_group" "webnsgroup" {
  description  = "NSGroup provisioned by Terraform"
  display_name = "web-terraform-demo-sg"
  membership_criteria {
    target_type = "VirtualMachine"
    scope       = "tier"
    tag         = "web"
  }
    tag {
	scope = "${var.nsx_tag_scope}"
	tag = "${var.nsx_tag}"
    }
}

# Create App NSGROUP
resource "nsxt_ns_group" "appnsgroup" {
  description  = "NSGroup provisioned by Terraform"
  display_name = "app-terraform-demo-sg"
  membership_criteria {
    target_type = "VirtualMachine"
    scope       = "tier"
    tag         = "app"
  }
    tag {
	scope = "${var.nsx_tag_scope}"
	tag = "${var.nsx_tag}"
    }
}

# Create DB NSGROUP
resource "nsxt_ns_group" "dbnsgroup" {
  description  = "NSGroup provisioned by Terraform"
  display_name = "db-terraform-demo-sg"
  membership_criteria {
    target_type = "VirtualMachine"
    scope       = "tier"
    tag         = "db"
  }
    tag {
	scope = "${var.nsx_tag_scope}"
	tag = "${var.nsx_tag}"
    }
}

# Create custom NSService for App service that listens on port 3000
resource "nsxt_l4_port_set_ns_service" "app" {
  description       = "L4 Port range provisioned by Terraform"
  display_name      = "App Service"
  protocol          = "TCP"
  destination_ports = ["${var.app_listen_port}"]
    tag {
	scope = "${var.nsx_tag_scope}"
	tag = "${var.nsx_tag}"
    }
}

# Create custom NSService for App service that listens on port 27017
resource "nsxt_l4_port_set_ns_service" "db" {
  description       = "L4 Port range provisioned by Terraform"
  display_name      = "DB Service"
  protocol          = "TCP"
  destination_ports = ["${var.db_listen_port}"]
    tag {
	scope = "${var.nsx_tag_scope}"
	tag = "${var.nsx_tag}"
    }
}

# Create data sources for some NSServices that we need to create FW rules
data "nsxt_ns_service" "http" {
  display_name = "HTTP"
}

data "nsxt_ns_service" "ssh" {
  display_name = "SSH"
}

# Create a Firewall Section
# All rules of this section will be applied to the VMs that are members of the NSGroup we created earlier
resource "nsxt_firewall_section" "firewall_section" {
  description  = "FS provisioned by Terraform"
  display_name = "Terraform Demo FW Section"
    tag {
	scope = "${var.nsx_tag_scope}"
	tag = "${var.nsx_tag}"
    }
  applied_to {
    target_type = "NSGroup"
    target_id   = "${nsxt_ns_group.nsgroup.id}"
  }

  section_type = "LAYER3"
  stateful     = true

# Allow communication to my VMs only on the ports we defined earlier as NSService
  rule {
    display_name = "Allow SSH"
    description  = "In going rule"
    action       = "ALLOW"
    logged       = false
    ip_protocol  = "IPV4"
    destination { 
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.nsgroup.id}"
    }
    service {
      target_type = "NSService"
      target_id   = "${data.nsxt_ns_service.ssh.id}"
    }
  }

  rule {
    display_name = "Allow HTTP"
    description  = "In going rule"
    action       = "ALLOW"
    logged       = false
    ip_protocol  = "IPV4"
    destination {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.webnsgroup.id}"
    }
    service {
      target_type = "NSService"
      target_id   = "${data.nsxt_ns_service.http.id}"
    }
  }
  
  rule {
    display_name = "Allow Web to App"
    description  = "In going rule"
    action       = "ALLOW"
    logged       = false
    ip_protocol  = "IPV4"
    source {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.webnsgroup.id}"
    }
    destination {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.appnsgroup.id}"
    }
    service {
      target_type = "NSService"
      target_id   = "${nsxt_l4_port_set_ns_service.app.id}"
    }
  }
  rule {
    display_name = "Allow App to DB"
    description  = "In going rule"
    action       = "ALLOW"
    logged       = false
    ip_protocol  = "IPV4"
    source {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.appnsgroup.id}"
    }
    destination {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.dbnsgroup.id}"
    }
    service {
      target_type = "NSService"
      target_id   = "${nsxt_l4_port_set_ns_service.db.id}"
    }
  }

# Allow all communication from my VMs to everywhere
  rule {
    display_name = "Allow out"
    description  = "Out going rule"
    action       = "ALLOW"
    logged       = false
    ip_protocol  = "IPV4"

    source {
      target_type = "NSGroup"
      target_id   = "${nsxt_ns_group.nsgroup.id}"
    }
  }

# REJECT everything that is not explicitelly allowed above and log a message
  rule {
    display_name = "Deny ANY"
    description  = "Default Deny the traffic"
    action       = "REJECT"
    logged       = true
    ip_protocol  = "IPV4"
  }
}

# Data source for the logical switch we created earlier
# we need that as we cannot refer directly to the logical switch from the vm resource below
data "vsphere_network" "terraform_ls" {
    name = "${nsxt_logical_switch.MyApp-LS.display_name}"
    datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

# Clone a VM from the template above and attach it to the newly created logical switch
resource "vsphere_virtual_machine" "dbvm" {
    name             = "${var.db["vm_name"]}"
    resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
    datastore_id     = "${data.vsphere_datastore.datastore.id}"
    num_cpus = 1
    memory   = 2048
    guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
    scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"
    # Attach the VM to the network data source that refers to the newly created logical switch
    network_interface {
      network_id = "${data.vsphere_network.terraform_ls.id}"
    }
    disk {
        label = "${var.db["vm_name"]}.vmdk"
        size = 16
        thin_provisioned = true
    }
    clone {
        template_uuid = "${data.vsphere_virtual_machine.template.id}"

        # Guest customization to supply hostname and ip addresses to the guest
        customize {
            linux_options {
                host_name = "${var.db["vm_name"]}"
                domain = "${var.db["domain"]}"
            }
            network_interface {
                ipv4_address = "${var.db["ip"]}"
                ipv4_netmask = "${var.db["mask"]}"
            }
            ipv4_gateway = "${var.db["gw"]}"
            dns_suffix_list = ["cpod-jfc.az-lab.shwrfr.com"]
            dns_server_list = ["172.20.4.1"]
        }
    }
    connection {
      type = "ssh",
      agent = "false"
      host = "${var.db["ip"]}"
        user = "${var.db["user"]}"
        password = "${var.db["pass"]}"
        script_path = "/root/tf.sh"
    }
    provisioner "remote-exec" {
      inline = [
        "sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4",
        "echo 'deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.0 multiverse' | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list",
        "sudo apt-get update",
	"sudo apt-get install -y mongodb-org",
	"sudo sed -ie 's/bindIp.*$/&,${var.db["ip"]}/g' /etc/mongod.conf",
	"sudo systemctl enable mongod",
	"sudo systemctl start mongod",
        ]
    }
}

resource "nsxt_vm_tags" "vm1_tags" {
    instance_id = "${vsphere_virtual_machine.dbvm.id}"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
    tag {
        scope = "tier"
        tag = "db"
    }
    tag {
        scope = "os"
        tag = "ubuntu1604"
    }
}

# Clone a VM from the template above and attach it to the newly created logical switch
resource "vsphere_virtual_machine" "appvm" {
    name             = "${var.app["vm_name"]}"
    resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
    datastore_id     = "${data.vsphere_datastore.datastore.id}"
    num_cpus = 1
    memory   = 2048
    guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
    scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"
    # Attach the VM to the network data source that refers to the newly created logical switch
    network_interface {
      network_id = "${data.vsphere_network.terraform_ls.id}"
    }
    disk {
        label = "${var.app["vm_name"]}.vmdk"
        size = 16
        thin_provisioned = true
    }
    clone {
        template_uuid = "${data.vsphere_virtual_machine.template.id}"

        # Guest customization to supply hostname and ip addresses to the guest
        customize {
            linux_options {
                host_name = "${var.app["vm_name"]}"
                domain = "${var.app["domain"]}"
            }
            network_interface {
                ipv4_address = "${var.app["ip"]}"
                ipv4_netmask = "${var.app["mask"]}"
            }
            ipv4_gateway = "${var.app["gw"]}"
            dns_suffix_list = ["cpod-jfc.az-lab.shwrfr.com"]
            dns_server_list = ["172.20.4.1"]
        }
    }
    connection {
      type = "ssh",
      agent = "false"
      host = "${var.app["ip"]}"
        user = "${var.app["user"]}"
        password = "${var.app["pass"]}"
        script_path = "/root/tf.sh"
    }
    provisioner "remote-exec" {
      inline = [
        "curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -",
	"sudo apt-get install -y nodejs",
	"git clone https://gitlab.com/adeleporte/testapp-app.git",
	"cd testapp-app",
	"npm install",
        "npm install forever -g",
        "forever start -c 'npm start' ./",
        ]
    }
}

resource "nsxt_vm_tags" "vm2_tags" {
    instance_id = "${vsphere_virtual_machine.appvm.id}"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
    tag {
        scope = "tier"
        tag = "app"
    }
    tag {
        scope = "os"
        tag = "ubuntu1604"
    }
}

# Clone a VM from the template above and attach it to the newly created logical switch
resource "vsphere_virtual_machine" "webvm" {
    name             = "${var.web["vm_name"]}"
    resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
    datastore_id     = "${data.vsphere_datastore.datastore.id}"
    num_cpus = 1
    memory   = 2048
    guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
    scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"
    # Attach the VM to the network data source that refers to the newly created logical switch
    network_interface {
      network_id = "${data.vsphere_network.terraform_ls.id}"
    }
    disk {
        label = "${var.web["vm_name"]}.vmdk"
        size = 16
        thin_provisioned = true
    }
    clone {
        template_uuid = "${data.vsphere_virtual_machine.template.id}"

        # Guest customization to supply hostname and ip addresses to the guest
        customize {
            linux_options {
                host_name = "${var.web["vm_name"]}"
                domain = "${var.web["domain"]}"
            }
            network_interface {
                ipv4_address = "${var.web["ip"]}"
                ipv4_netmask = "${var.web["mask"]}"
            }
            ipv4_gateway = "${var.web["gw"]}"
            dns_suffix_list = ["cpod-jfc.az-lab.shwrfr.com"]
            dns_server_list = ["172.20.4.1"]
        }
    }
    connection {
      type = "ssh",
      agent = "false"
      host = "${var.web["ip"]}"
        user = "${var.web["user"]}"
        password = "${var.web["pass"]}"
        script_path = "/root/tf.sh"
    }
    provisioner "remote-exec" {
      inline = [
        "curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -",
        "sudo apt-get install -y nodejs",
        "git clone https://gitlab.com/adeleporte/testapp-web.git",
        "cd testapp-web",
        "npm install",
	"npm install forever -g",
        "forever start node_modules/@angular/cli/bin/ng serve --disable-host-check --proxy-config proxy.conf.json",
        ]
    }
}

resource "nsxt_vm_tags" "vm3_tags" {
    instance_id = "${vsphere_virtual_machine.webvm.id}"
    tag {
        scope = "${var.nsx_tag_scope}"
        tag = "${var.nsx_tag}"
    }
    tag {
        scope = "tier"
        tag = "web"
    }
    tag {
        scope = "os"
        tag = "ubuntu1604"
    }
}
