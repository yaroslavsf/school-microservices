variable "authentik_url" {
  type    = string
  default = "http://host.docker.internal:9000"
}

variable "authentik_token" {
  type      = string
  sensitive = true
}

variable "base_domain" {
  type    = string
  default = "localhost"
}
