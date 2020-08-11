job "relational-db" {
  priority = 90

  datacenters = [
    "customer"
  ]

  type = "service"

  meta {
    CONSUL_HOST = "127.0.0.1"
    CONSUL_PORT = 8500
    POSTGRESQL_DB_NAME = "bunzi"
  }

  group "postgresql" {
    count = 1

    restart {
      attempts = 2
      interval = "3m"
      delay = "90s"
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

    task "postgresql" {
      driver = "docker"

      config {
        image = "bitnami/postgresql:11.4.0"
        advertise_ipv6_address = false
        network_mode = "host"
        mounts = [
          {
            type = "volume"
            target = "/bitnami/postgresql"
            source = "postgresql-data"
            readonly = false
          }
        ]
      }

      resources {
        memory = 512
        cpu = 270
        network {
          mbits = 10
          port "postgresql" {
            static = "5432"
          }
        }
      }

      env {
        POSTGRESQL_PORT_NUMBER = "${NOMAD_PORT_postgresql}"
        POSTGRESQL_POSTGRES_PASSWORD = "password1"
        POSTGRESQL_USERNAME = "getvisibility"
        POSTGRESQL_PASSWORD = "password2"
        POSTGRESQL_DATABASE = "${NOMAD_META_POSTGRESQL_DB_NAME}"
      }

      service {
        name = "postgresql"
        port = "postgresql"
        check {
          name = "PostgreSQL pg_isready check"
          type = "script"
          initial_status = "passing"
          command = "pg_isready"
          # The options for username and dbname are not verified by the `is ready` check
          args = [
            "-d", "${NOMAD_META_POSTGRESQL_DB_NAME}",
            "-h", "${NOMAD_IP_postgresql}",
            "-U", "gv",
            "-p", "${NOMAD_HOST_PORT_postgresql}"
          ]
          interval = "70s"
          timeout = "10s"
          check_restart {
            limit = 2
            grace = "120s"
          }
        }
      }
    }
  }
}
