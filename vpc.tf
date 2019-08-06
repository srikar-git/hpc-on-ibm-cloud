variable "ssh_key" {}

locals {
     BASENAME = "hpc-cluster" 
     ZONE     = "${var.region}-1"
   }

resource ibm_is_vpc "vpc" {
  name = "${local.BASENAME}-vpc"
}

resource ibm_is_security_group "sg" {
  name = "${local.BASENAME}-sg"
  vpc  = "${ibm_is_vpc.vpc.id}"
}

# allow all incoming network traffic on port 22
resource "ibm_is_security_group_rule" "ingress_ssh_all" {
  group     = "${ibm_is_security_group.sg.id}"
  direction = "ingress"
  remote    = "0.0.0.0/0"                       

  tcp = {
    port_min = 22
    port_max = 22
  }
}

resource ibm_is_subnet "subnet" {
  name = "${local.BASENAME}-subnet"
  vpc  = "${ibm_is_vpc.vpc.id}"
  zone = "${local.ZONE}"
  total_ipv4_address_count = 256
}

data ibm_is_image "ubuntu" {
  name = "ubuntu-18.04-amd64"
}

data ibm_is_ssh_key "ssh_key_id" {
  name = "${var.ssh_key}"
}

resource ibm_is_instance "master1" {
  name    = "${local.BASENAME}-master1"
  vpc     = "${ibm_is_vpc.vpc.id}"
  zone    = "${local.ZONE}"
  keys    = ["${data.ibm_is_ssh_key.ssh_key_id.id}"]
  image   = "${data.ibm_is_image.ubuntu.id}"
  profile = "cc1-2x4"

  primary_network_interface = {
    subnet          = "${ibm_is_subnet.subnet.id}"
    security_groups = ["${ibm_is_security_group.sg.id}"]
  }
}

resource ibm_is_instance "master2" {
  name    = "${local.BASENAME}-master2"
  vpc     = "${ibm_is_vpc.vpc.id}"
  zone    = "${local.ZONE}"
  keys    = ["${data.ibm_is_ssh_key.ssh_key_id.id}"]
  image   = "${data.ibm_is_image.ubuntu.id}"
  profile = "cc1-2x4"

  primary_network_interface = {
    subnet          = "${ibm_is_subnet.subnet.id}"
    security_groups = ["${ibm_is_security_group.sg.id}"]
  }
}

resource ibm_is_instance "compute1" {
  name    = "${local.BASENAME}-compute1"
  vpc     = "${ibm_is_vpc.vpc.id}"
  zone    = "${local.ZONE}"
  keys    = ["${data.ibm_is_ssh_key.ssh_key_id.id}"]
  image   = "${data.ibm_is_image.ubuntu.id}"
  profile = "cc1-2x4"

  primary_network_interface = {
    subnet          = "${ibm_is_subnet.subnet.id}"
    security_groups = ["${ibm_is_security_group.sg.id}"]
  }
}

resource ibm_is_floating_ip "fipmaster" {
  name   = "${local.BASENAME}-fipmaster"
  target = "${ibm_is_instance.master1.primary_network_interface.0.id}"
}

resource ibm_is_floating_ip "fipcompute" {
  name   = "${local.BASENAME}-fipcompute"
  target = "${ibm_is_instance.compute1.primary_network_interface.0.id}"
}

output sshcommand {
  value = "ssh root@${ibm_is_floating_ip.fipmaster.address}"
}

output sshcommandcompute {
  value = "ssh root@${ibm_is_floating_ip.fipcompute.address}"
}
