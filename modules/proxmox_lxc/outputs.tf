output "lxc_id" {
  description = "ID numérico gerado no Proxmox para o Container"
  value       = proxmox_lxc.container.id
}