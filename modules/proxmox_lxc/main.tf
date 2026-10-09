terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc10"
    }
  }
}

resource "proxmox_lxc" "container" {
  target_node = var.target_node
  hostname    = var.hostname
  clone       = var.template_id

  cores  = var.cores
  memory = var.memory

  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }
}