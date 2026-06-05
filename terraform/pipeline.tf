# AWS CI/CD Pipeline for CloudFormation Deployment

resource "aws_codecommit_repository" "cfn_repo" {
  repository_name = "devops-lab-cfn"
  description     = "Repository for CloudFormation template storage and deployment"
}

# 1. S3 Artifact Store Bucket
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket        = "devops-pipeline-artifacts-${random_string.suffix.result}"
  force_destroy = true
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# 2. AWS Academy Pre-created IAM Role
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# ==============================================================================
# NOTE: The CodeBuild and CodePipeline resources below represent the standard production
# design for Lab 2 Part 2. However, they are commented out here because AWS Academy sandbox
# policies (explicit deny on codebuild:CreateProject via policy Pvoclabs2) block their
# creation. The pipeline has been successfully migrated to GitHub Actions (deploy-cfn.yml)
# for cloud testing and verification.
# ==============================================================================

# # 3. CodeBuild Project for CloudFormation Validation
# resource "aws_codebuild_project" "cfn_build" {
#   name          = "cfn-validation-tests"
#   description   = "Static linting and testing for CloudFormation template"
#   build_timeout = "10"
#   service_role  = data.aws_iam_role.lab_role.arn
# 
#   artifacts {
#     type = "CODEPIPELINE"
#   }
# 
#   environment {
#     compute_type                = "BUILD_GENERAL1_SMALL"
#     image                       = "aws/codebuild/standard:7.0"
#     type                        = "LINUX_CONTAINER"
#     image_pull_credentials_type = "CODEBUILD"
#   }
# 
#   source {
#     type      = "CODEPIPELINE"
#     buildspec = "cloudformation/buildspec.yml"
#   }
# }
# 
# # 4. CodePipeline Definition
# resource "aws_codepipeline" "cfn_pipeline" {
#   name     = "cloudformation-deployment-pipeline"
#   role_arn = data.aws_iam_role.lab_role.arn
# 
#   artifact_store {
#     location = aws_s3_bucket.pipeline_artifacts.bucket
#     type     = "S3"
#   }
# 
#   stage {
#     name = "Source"
# 
#     action {
#       name             = "Source"
#       category         = "Source"
#       owner            = "AWS"
#       provider         = "CodeCommit"
#       version          = "1"
#       output_artifacts = ["source_output"]
# 
#       configuration = {
#         RepositoryName = aws_codecommit_repository.cfn_repo.repository_name
#         BranchName     = "main"
#       }
#     }
#   }
# 
#   stage {
#     name = "Test"
# 
#     action {
#       name             = "LintAndValidate"
#       category         = "Test"
#       owner            = "AWS"
#       provider         = "CodeBuild"
#       input_artifacts  = ["source_output"]
#       output_artifacts = ["test_output"]
#       version          = "1"
# 
#       configuration = {
#         ProjectName = aws_codebuild_project.cfn_build.name
#       }
#     }
#   }
# 
#   stage {
#     name = "Deploy"
# 
#     action {
#       name            = "DeployCloudFormationStack"
#       category        = "Deploy"
#       owner           = "AWS"
#       provider        = "CloudFormation"
#       input_artifacts = ["source_output"]
#       version         = "1"
# 
#       configuration = {
#         ActionMode     = "CREATE_UPDATE"
#         StackName      = "Devops-Lab1-Stack"
#         TemplatePath   = "source_output::cloudformation/main.yaml"
#         RoleArn        = data.aws_iam_role.lab_role.arn
#         Capabilities   = "CAPABILITY_NAMED_IAM,CAPABILITY_AUTO_EXPAND"
#       }
#     }
#   }
# }




