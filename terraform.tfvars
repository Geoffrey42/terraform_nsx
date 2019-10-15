nsx = {
    ip  = "nsx-mgr-01.cpod-jfc.az-lab.shwrfr.com"
    user = "admin"
    password = "VMware1!VMware1!"
}
vsphere{
    vsphere_user = "administrator@cpod-jfc.az-lab.shwrfr.com"
    vsphere_password = "pdrmFcIYTUc3Ebq!"
    vsphere_ip = "vcsa.cpod-jfc.az-lab.shwrfr.com"
    dc = "cPod-JFC"
    datastore = "Datastore"
    resource_pool = "Compute/Resources"
    vm_template = "ubuntu"
}
nsx_data_vars = {
    transport_zone  = "tz-overlay"
    t0_router_name = "2ND-T0"
}
nsx_tag_scope = "poc"
nsx_tag = "terraform-demo"
nsx_rs_vars = {
    t1_router_name = "terraform_t1_router"
    ip = "192.168.168.1"
    mask = "24"
}
web = {
    ip = "192.168.168.11"
    gw = "192.168.168.1"
    mask = "24"
    vm_name = "web"
    domain = "cpod-jfc.az-lab.shwrfr.com"
    dns_server_list = "172.20.4.1"
    user = "root" # Credentails to access the VM
    pass = "VMware1!"
}

app = {
    ip = "192.168.168.12"
    gw = "192.168.168.1"
    mask = "24"
    vm_name = "app"
    domain = "cpod-jfc.az-lab.shwrfr.com"
    dns_server_list = "172.20.4.1"
    user = "root"
    pass = "VMware1!"
}

db = {
    ip = "192.168.168.13"
    gw = "192.168.168.1"
    mask = "24"
    vm_name = "db"
    domain = "cpod-jfc.az-lab.shwrfr.com"
    dns_server_list = "172.20.4.1"
    user = "root"
    pass = "VMware1!"
}
app_listen_port = "3000"
db_listen_port = "27017"

