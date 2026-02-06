terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      # Под твой стек 2024.8.x логично зафиксировать 2024.8.x
      version = ">= 2024.8"
    }
  }
}

provider "authentik" {
  url   = var.authentik_url
  token = var.authentik_token
}

# --- flows (стандартные) ---
data "authentik_flow" "authn" { slug = "default-authentication-flow" }
data "authentik_flow" "authz" { slug = "default-provider-authorization-implicit-consent" }
data "authentik_flow" "invalidate" { slug = "default-provider-invalidation-flow" }

data "authentik_flow" "default_invalidation" {
  slug = "default-provider-invalidation-flow"
}

# --- groups ---
resource "authentik_group" "shop_admin" { name = "shop-admin" }
resource "authentik_group" "shop_user"  { name = "shop-user"  }

# --- providers (Forward Auth single app) ---
resource "authentik_provider_proxy" "py" {
  name               = "py-service-forward-auth"
  mode               = "forward_single" # proxy | forward_single | forward_domain :contentReference[oaicite:1]{index=1}
  external_host      = "http://py.${var.base_domain}"
  authentication_flow = data.authentik_flow.authn.id
  authorization_flow  = data.authentik_flow.authz.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id
}

resource "authentik_provider_proxy" "js" {
  name               = "js-service-forward-auth"
  mode               = "forward_single"
  external_host      = "http://js.${var.base_domain}"
  authentication_flow = data.authentik_flow.authn.id
  authorization_flow  = data.authentik_flow.authz.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id
}

resource "authentik_provider_proxy" "grafana" {
  name               = "grafana-forward-auth"
  mode               = "forward_single"
  external_host      = "http://grafana.${var.base_domain}"
  authentication_flow = data.authentik_flow.authn.id
  authorization_flow  = data.authentik_flow.authz.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id
}

# --- applications ---
resource "authentik_application" "py" {
  name              = "Product Service"
  slug              = "py-service"
  protocol_provider = authentik_provider_proxy.py.id
}

resource "authentik_application" "js" {
  name              = "Order Service"
  slug              = "js-service"
  protocol_provider = authentik_provider_proxy.js.id
}

resource "authentik_application" "grafana" {
  name              = "Grafana"
  slug              = "grafana"
  protocol_provider = authentik_provider_proxy.grafana.id
}

# --- bindings (RBAC) ---
# Минимальный RBAC: py/js -> shop-user, grafana -> shop-admin
resource "authentik_policy_binding" "py_allow_shop_user" {
  target = authentik_application.py.uuid
  group  = authentik_group.shop_user.id
  order  = 0
}

resource "authentik_policy_binding" "js_allow_shop_user" {
  target = authentik_application.js.uuid
  group  = authentik_group.shop_user.id
  order  = 0
}

resource "authentik_policy_binding" "grafana_allow_shop_admin" {
  target = authentik_application.grafana.uuid
  group  = authentik_group.shop_admin.id
  order  = 0
}

# --- outpost (manual, для твоего authentik-proxy контейнера) ---
resource "authentik_outpost" "traefik_forward_auth" {
  name = "traefik-forward-auth"
  type = "proxy"

  protocol_providers = [
    authentik_provider_proxy.py.id,
    authentik_provider_proxy.js.id,
    authentik_provider_proxy.grafana.id,
  ]
}
