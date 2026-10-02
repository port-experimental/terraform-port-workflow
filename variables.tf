
variable "identifier" {
  description = "Unique identifier for the Port workflow."
  type        = string
}
variable "title" {
  description = "Display name of the Port workflow."
  type        = string
  default     = null
}
variable "description" {
  description = "Optional description of the Port workflow."
  type        = string
  default     = null
}
variable "icon" {
  description = "Optional Port icon identifier for the workflow."
  type        = string
  default     = null
}
variable "category" {
  description = "Optional workflow category, up to 40 characters."
  type        = string
  default     = null
}
variable "allow_anyone_to_view_runs" {
  description = "Whether all users can view workflow runs."
  type        = bool
  default     = true
}
variable "nodes" {
  description = "Workflow node definitions."
  type        = any
  nullable    = false
  validation {
    condition     = length(var.nodes) > 0
    error_message = "At least one workflow node is required."
  }
}
variable "connections" {
  description = "Directed connections between workflow nodes."
  type        = any
  default     = []
}