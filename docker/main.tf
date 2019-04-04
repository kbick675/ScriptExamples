# Resource to download docker image

resource "docker_image" "image_id" {
    name = "ghost:latest"
}

resource "docker_container" "container_id" {
    name = "blog"
    image = "${docker_container.container_id.latest}"
    ports {
        internal = "2365"
        external = "80"
    }
}

# taint a resource/mark a resource for updating
## terraform taint docker_container.container_id
# untaint a resource
## terraform untaint docker_container.container_id


