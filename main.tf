#-------------------------------------------------------------------------------
#
#   SECRET MANAGER (GOOGLE)
#
#   Defines secrets using Google Secret Manager.
#
#-------------------------------------------------------------------------------


terraform {
  required_providers {
    google = {
      version = "3.88.0"
    }
  }
}


locals {
  resources = {
    for x in var.resources:
      "${x.project}/${x.name}" => merge(x, {
        replication = try(x.replication, ["europe-west4"])
      })
  }
}


resource "google_secret_manager_secret" "secrets" {
  for_each  = local.resources
  project   = each.value.project
  secret_id = each.value.name
  labels    = try(each.value.labels, {})

  replication {
    user_managed {
      dynamic "replicas" {
        for_each = each.value.replication
        content {
          location = replicas.value
        }
      }
    }
  }
}


data "google_iam_policy" "default" {
  for_each  = local.resources

  binding {
    role    = "roles/secretmanager.admin"
    members = try(each.value.admins, var.admins)
  }

  binding {
    role    = "roles/secretmanager.secretAccessor"
    members = try(each.value.consumers, [])
  }

  binding {
    role    = "roles/secretmanager.secretVersionAdder"
    members = try(each.value.editors, [])
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  for_each  = local.resources
  project   = google_secret_manager_secret.secrets[each.key].project
  secret_id = google_secret_manager_secret.secrets[each.key].secret_id
  policy_data = data.google_iam_policy.default[each.key].policy_data
}
