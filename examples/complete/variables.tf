variable "region" {
  type        = string
  description = "The region you plan to use in regular operations. In the module, referred to as the \"blue\" region."
}

variable "green_region" {
  type        = string
  default     = null
  description = "The region you plan to use when the regular region has problems. In the module, referred to as the \"green\" region."
}

