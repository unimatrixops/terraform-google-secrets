

variable "admins" {
  default=[]
  type=list(string)
  description="The list of admins that maintain the secrets."
}


variable "resources" {
  default=[]
  description="The list of secrets to define."
}
