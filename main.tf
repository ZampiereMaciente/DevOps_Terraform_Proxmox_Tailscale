terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc10"
    }
  }
}
# Test Hook

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}

module "container_app" {
  source = "./modules/proxmox_lxc"

  hostname    = "debian-app"
  target_node = var.proxmox_node
  template_id = "Template-Container-Debian"
  cores       = 1
  memory      = 512
}

module "container_db" {
  source = "./modules/proxmox_lxc"

  hostname    = "debian-db"
  target_node = var.proxmox_node
  template_id = "Template-Container-Debian"
  cores       = 2
  memory      = 1024
}