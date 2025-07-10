variable "appId" {
  description = "Azure Service Principal Application ID"
  type        = string
  sensitive   = true
}

variable "password" {
  description = "Azure Service Principal Password/Secret"
  type        = string
  sensitive   = true
}

variable "tenantId" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "subscriptionId" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}
