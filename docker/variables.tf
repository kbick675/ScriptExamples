variable "vsphere_server" {
    description = "vsphere server for the environment - EXAMPLE: vcenter01.hosted.local"
    default = "phvccl01.vcaantech.com"
}
 
variable "vsphere_user" {
    description = "vsphere server for the environment - EXAMPLE: vsphereuser"
    default = "administrator@vcsa65.local"
}
 
variable "vsphere_password" {
    description = "vsphere server password for the environment"
    default = "password"
}
 
variable "virtual_machine_dns_servers" {
  type    = "list"
  default = ["10.1.149.10", "9.9.9.9"]
}