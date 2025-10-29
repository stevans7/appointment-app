resource "aws_ecr_repository" "appointment_app" {
  name                 = "appointment-app"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
}
