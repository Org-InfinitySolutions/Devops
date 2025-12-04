# --- Configuração das Variáveis ---

variable "allowed_ips" {
  description = "Lista de endereços IP públicos para regras de SSH e PAINEL RABBITMQ"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "Nome da chave pem para acesso SSH"
  type        = string
  default     = "test-key"
}

variable "ami_webserver" {
  description = "AMI personalizada para o servidor Nginx (Load Balancer)"
  type        = string
  default     = "ami-0f3cade4c31bdf6d1"
}

variable "ami_frontend" {
  description = "AMI personalizada para o servidor frontend"
  type        = string
  default     = "ami-03f1ea56c1897eb78"
}

variable "ami_backend" {
  description = "AMI personalizada para o servidor Backend"
  type        = string
  default     = "ami-0b2eca8907f641af4"
}

variable "ami_database" {
  description = "AMI personalizada para o servidor de Banco de Dados"
  type        = string
  default     = "ami-0f37af81dcd61e39f"
}

variable "ami_rabbitmq" {
  description = "AMI personalizada para o servidor RabbitMQ"
  type        = string
  default     = "ami-023a87b2e219ff393"
}

variable "bucket_publico" {
  description = "Nome do bucket S3 de arquivos públicos"
  type        = string
  default     = "infinitysolutions-arquivos-publicos"
}

variable "bucket_privado" {
  description = "Nome do bucket S3 de arquivos privados"
  type        = string
  default     = "infinitysolutions-arquivos-privados"
}