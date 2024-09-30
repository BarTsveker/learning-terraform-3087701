# outputs.tf

output "load_balancer_dns" {
  value = aws_lb.web_server_lb.dns_name
  description = "DNS name of the load balancer"
}

# ... (Other outputs you might need)