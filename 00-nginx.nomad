job "nginx" {

  datacenters = ["customer"]

  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "5m"
    progress_deadline = "10m"
    auto_revert = false
    canary = 0
  }

  group "nginx" {
    count = 1

    restart {
      attempts = 3
      interval = "10m"
      delay = "3m"
      mode = "fail"
    }

    reschedule {
      attempts = 6
      interval = "1h"
      delay = "1m"
      delay_function = "exponential"
      max_delay = "5m"
      unlimited = false
    }

    task "nginx" {
      template {
        change_mode = "noop"
        destination = "local/nginx.conf"
        data = <<EOH
worker_processes  auto;

error_log /var/log/nginx/error.log warn;

events {
    worker_connections  1024;
}

http {
    server {
        access_log /var/log/nginx/access.log combined;
        listen       8090;
        server_name  localhost;

        # disable any limits to avoid HTTP 413 for large image uploads
        client_max_body_size 0;

        # required to avoid HTTP 411: see Issue #1486 (https://github.com/moby/moby/issues/1486)
        chunked_transfer_encoding on;

        #models server
        location /content/ {

                sendfile on;
                root   /home/devops/;
                autoindex on;
        }
        
    }

}

EOH
      }

      driver = "docker"

      config {
        image = "nginx"
        network_mode = "host"
        volumes = [
          "local/nginx.conf:/etc/nginx/nginx.conf",
	  "/var/local/content:/home/devops/content"
        ]
      }

      resources {
        cpu = 200
        network {
          port "http" {
          static = "8090"
          }
        }
      }

      service {
        name = "nginx"
        port = "http"
      }
    }
  }
}
