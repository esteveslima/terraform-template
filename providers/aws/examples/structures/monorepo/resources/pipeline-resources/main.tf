# Resources for pipeline and builds(cache, logs, artifacts, etc)

locals {

}



###############################   Data sources   ###############################






###############################   Application   ###############################



##### Setup pipeline code source connection(Github)

#TODO: create s3 module
resource "aws_s3_bucket" "codepipeline_s3_bucket" {
  bucket = "${local.project}-${local.environment}-bucket"
  acl    = "private"

  tags = {
    Name = "${local.project}-${local.environment}"
  }
}
