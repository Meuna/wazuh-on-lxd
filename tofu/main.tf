terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "2.5.0"
    }
  }
}

provider "lxd" {
}

variable "ssh_pub_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

resource "lxd_project" "wazuh" {
  name        = "wazuh"
  description = "Wazuh PoC"
  config = {
    "features.storage.volumes" = true
    "features.images"          = false
    "features.networks"        = false
    "features.profiles"        = true
    "features.storage.buckets" = true
  }
}

resource "lxd_network" "wazuh" {
  name = "wazuh"

  config = {
    "ipv4.nat"     = "true"
    "ipv6.address" = "none"
    "dns.domain"   = "wazuh.local"
  }
}

resource "lxd_storage_pool" "wazuh" {
  project = lxd_project.wazuh.name
  name    = "wazuh"
  driver  = "dir"
}

resource "lxd_profile" "wazuh" {
  project = lxd_project.wazuh.name
  name    = "wazuh"

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = lxd_network.wazuh.name
    }
  }

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = lxd_storage_pool.wazuh.name
      path = "/"
    }
  }

  config = {
    "cloud-init.user-data" : templatefile("cloud-init.yaml.tftpl", { ssh_pub = file(var.ssh_pub_path) })
  }
}

resource "lxd_instance" "wazuh" {
  project  = lxd_project.wazuh.name
  name     = "wazuh"
  image    = "ubuntu:24.04"
  type     = "virtual-machine"
  profiles = [lxd_profile.wazuh.name]
  limits = {
    memory = "4GiB"
  }
  device {
    type = "disk"
    name = "root"

    properties = {
      pool = lxd_storage_pool.wazuh.name
      path = "/"
      size = "50GiB"
    }
  }
}

resource "lxd_instance" "wazuh_client" {
  project  = lxd_project.wazuh.name
  name     = "wazuh-client"
  image    = "ubuntu:24.04"
  type     = "virtual-machine"
  profiles = [lxd_profile.wazuh.name]
}

resource "lxd_instance" "syslog_client" {
  project  = lxd_project.wazuh.name
  name     = "syslog-client"
  image    = "ubuntu:24.04"
  type     = "virtual-machine"
  profiles = [lxd_profile.wazuh.name]
}
