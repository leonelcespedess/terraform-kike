# Esto permite que CloudFront acceda al bucket S3 de forma segura sin hacerlo público.
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.bucket_name}"
}

#CREAR EL BUCKET S3
resource "aws_s3_bucket" "site_bucket" {
  bucket = var.bucket_name
}

#CONFIGURAR EL BUCKET PARA ALOJAMIENTO WEB ESTÁTICO
resource "aws_s3_bucket_website_configuration" "site_config" {
  bucket = aws_s3_bucket.site_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# 4. DEFINIR Y APLICAR LA POLÍTICA DEL BUCKET
# Esta política permite el acceso de lectura SOLAMENTE a la OAI de CloudFront.
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.site_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# 5. SUBIR LOS ARCHIVOS DEL SITIO WEB AL BUCKET
# Terraform buscará todos los archivos en la ruta especificada.
resource "aws_s3_object" "site_files" {
  for_each = fileset(var.website_content_path, "**/*.*")

  bucket       = aws_s3_bucket.site_bucket.id
  key          = each.value
  source       = "${var.website_content_path}/${each.value}"
  etag         = filemd5("${var.website_content_path}/${each.value}")
  content_type = lookup(var.mime_types, regex("\\.[^.]+$", each.value), "application/octet-stream")
}

# 6. CREAR LA DISTRIBUCIÓN DE CLOUDFRONT
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.site_bucket.bucket_regional_domain_name
    origin_id   = "S3-${var.bucket_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Distribution for ${var.bucket_name}"
  default_root_object = "index.html"
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.bucket_name}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }


  viewer_certificate {
    cloudfront_default_certificate = true
  }
}