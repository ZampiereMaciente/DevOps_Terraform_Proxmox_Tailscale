variable "target_node" {
  type        = string
  description = "Nó do Proxmox onde o LXC será criado"
}

variable "hostname" {
  type        = string
  description = "Hostname do container LXC"
}

variable "template_id" {
  type        = string
  description = "VMID ou Nome do Template LXC a ser clonado"
}

variable "cores" {
  type        = number
  default     = 1
  description = "Quantidade de vCPUs"
}

variable "memory" {
  type        = number
  default     = 512
  description = "Memória RAM em MB"
}