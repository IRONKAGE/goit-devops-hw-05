variable "environment" {
  type        = string
  description = "Ідентифікатор середовища (dev/prod). Використовується для префіксів імен ресурсів та ізоляції стейту."
}

variable "project_name" {
  type        = string
  default     = "ironkage"
  description = "Глобальна назва проєкту для іменування інфраструктурних компонентів."
}
