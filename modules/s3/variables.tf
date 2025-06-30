# /modules/s3/variables.tf

variable "bucket_name" {
  description = "The name of the S3 bucket for the website."
  type        = string
}

variable "website_content_path" {
  description = "Local path to the website content to be uploaded."
  type        = string
}

variable "mime_types" {
  description = "A map of common file extensions to MIME types for S3 uploads."
  type        = map(string)
  default = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".woff" = "font/woff"
    ".woff2" = "font/woff2"
    ".ttf"  = "font/ttf"
    ".eot"  = "application/vnd.ms-fontobject"
  }
}
