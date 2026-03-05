provider "aws" {
  region = "us-east-1"
}

# Create the S3 bucket for haifa.work
resource "aws_s3_bucket" "website_bucket" {
  bucket = "haifa-work-storage" # Bucket names must be unique globally
}

# Set the bucket to act as a website
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }
}


# This resource disables the "Block Public Access" settings
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# This resource attaches a policy to allow public reading
resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website_bucket.arn}/*"
      },
    ]
  })

  # Ensure the public access block is removed BEFORE applying the policy
  depends_on = [aws_s3_bucket_public_access_block.public_access]
}

output "website_url" {
  value = aws_s3_bucket_website_configuration.website_config.website_endpoint
}
