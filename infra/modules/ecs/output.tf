output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "service_name" {
  value = aws_ecs_service.this.name
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}

output "execution_role_arn" {
  value = aws_iam_role.execution.arn
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs_task.id
}