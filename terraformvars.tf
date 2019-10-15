# configure some variables first 
variable "nsx" {
    type = "map"
    description = "NSX Login Details"
}
variable "vsphere" {
    type = "map"
    description = "vSphere Details"
}
variable "nsx_data_vars" {
    type = "map"
    description = "Existing NSX vars for data sources"
}
variable "nsx_tag_scope" {
    type = "string"
    description = "Scope for the tag that will be applied to all resources"
}
variable "nsx_tag" {
    type = "string"
    description = "Tag, the value for the scope above"
}
variable "nsx_rs_vars" {
    type = "map"
    description = "NSX vars for the resources"
}
variable "web" {
    type = "map"
    description = "vsphere vars for the resources"
}
variable "app" {
    type = "map"
    description = "vsphere vars for the resources"
}
variable "db" {
    type = "map"
    description = "vsphere vars for the resources"
}
variable "app_listen_port" {
    type = "string"
    description = "TCP Port the App server listens on"
}
variable "db_listen_port" {
    type = "string"
    description = "TCP Port the App server listens on"
}

