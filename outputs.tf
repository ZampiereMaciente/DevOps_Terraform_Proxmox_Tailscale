output "lxc_app_id" {
  description = "ID do Container de Aplicação"
  value       = module.container_app.lxc_id
}

output "lxc_db_id" {
  description = "ID do Container de Banco de Dados"
  value       = module.container_db.lxc_id
}