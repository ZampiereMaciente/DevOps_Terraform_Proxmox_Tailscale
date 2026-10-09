variable "proxmox_api_url" {
  type        = string
  description = "URL do endpoint da API do Proxmox VE"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Token ID de autenticação do Proxmox"
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Secret key do Token do Proxmox"
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "Nome do nó alvo no Proxmox"
}