variable "REGISTRY" {}

variable "SERVICE" {}

group "default" {
  targets = ["slim", "full"]
}

target "slim" {
  dockerfile = "Dockerfile"
  target = "slim"
  tags = ["${REGISTRY}/${SERVICE}_slim"]
}

target "full" {
  dockerfile = "Dockerfile"
  target = "full"
  tags = ["${REGISTRY}/${SERVICE}_full"]
}