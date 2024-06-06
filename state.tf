terraform {
  cloud {
    organization = "ldryt-infra"
    workspaces {
      name = "main"
    }
  }
}
