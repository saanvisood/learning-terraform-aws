variable "open_webui_user" {
  description = "Username to access Open WebUI"
  default     = "admin@demo.gs"
}

variable "openai_base" {
  description = "Optional base URL to use OpenAI API with Open WebUI"
  default     = "https://api.openai.com/v1"
}

variable "openai_key" {
  description = "Optional API key to use OpenAI API with Open WebUI"
  default     = ""
  sensitive   = true
}
