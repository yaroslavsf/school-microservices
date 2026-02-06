#!/usr/bin/env bash
set -euo pipefail

# allow: ./script.sh path/to/.env
ENV_FILE="${ENV_FILE:-.env}"
if [[ "${1-}" != "" ]]; then
  ENV_FILE="$1"
fi

COMPOSE_FILE="${COMPOSE_FILE:-infra/docker-compose.yml}"

ADMIN_USERNAME="${AK_ADMIN_USERNAME:-akadmin}"
ADMIN_EMAIL="${AK_ADMIN_EMAIL:-admin@local}"
ADMIN_PASSWORD="${AK_ADMIN_PASSWORD:-admin}"

# Wait until authentik is live (no curl inside authentik container needed)
echo "▶ Waiting for authentik /-/health/live/ ..."
for i in {1..180}; do
  if docker run --rm --network mvp-microservices-platform_internal curlimages/curl:8.6.0 \
      -fsS http://authentik-server:9000/-/health/live/ >/dev/null 2>&1; then
    echo "✔ authentik is live"
    break
  fi
  [[ "$i" -eq 180 ]] && { echo "❌ authentik didn't become live"; exit 1; }
  sleep 2
done

echo "▶ Creating/updating admin: ${ADMIN_USERNAME} (${ADMIN_EMAIL}) and printing token..."

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" exec -T authentik-server \
  sh -lc '
set -euo pipefail

PY="/ak-root/.venv/bin/python"

# pick manage.py location (your trace shows /manage.py)
if [ -f /manage.py ]; then
  MANAGE=/manage.py
elif [ -f /authentik/manage.py ]; then
  MANAGE=/authentik/manage.py
else
  echo "❌ manage.py not found at /manage.py or /authentik/manage.py"
  exit 1
fi

# run django shell, avoid interactive wrapper noise if supported
"$PY" "$MANAGE" shell -c "
import os, secrets
from django.apps import apps
from django.contrib.auth.hashers import make_password
from authentik.core.models import User

username   = os.environ.get(\"AK_ADMIN_USERNAME\", \"'"$ADMIN_USERNAME"'\")
email      = os.environ.get(\"AK_ADMIN_EMAIL\", \"'"$ADMIN_EMAIL"'\")
password   = os.environ.get(\"AK_ADMIN_PASSWORD\", \"'"$ADMIN_PASSWORD"'\")
token_name = os.environ.get(\"AK_ADMIN_TOKEN_NAME\", \"bootstrap\")

# 1) Ensure admin user exists
u, _ = User.objects.get_or_create(username=username, defaults={\"email\": email})
u.email = email
u.is_active = True
u.is_superuser = True
# is_staff in authentik 2025.12.x is a property -> DO NOT SET IT
u.password = make_password(password)
u.save()

# 2) Find a token model dynamically (works across versions)
TokenModel = None
token_field = None
for m in apps.get_models():
    name = (m.__name__ or \"\").lower()
    if \"token\" not in name:
        continue
    fields = {f.name: f for f in m._meta.get_fields() if hasattr(f, \"name\")}
    if \"user\" not in fields:
        continue
    candidate_fields = [n for n in (\"key\",\"token\",\"value\") if n in fields]
    if not candidate_fields:
        continue
    try:
        rel = fields[\"user\"]
        if not hasattr(rel, \"related_model\") or rel.related_model is not User:
            continue
    except Exception:
        continue
    TokenModel = m
    token_field = candidate_fields[0]
    break

if TokenModel is None:
    print(\"ERROR: token model not found in this authentik build\")
    raise SystemExit(2)

# 3) Reuse existing token if present, else create new
model_fields = {f.name for f in TokenModel._meta.get_fields() if hasattr(f, \"name\")}
name_field = None
for opt in (\"name\",\"identifier\",\"description\"):
    if opt in model_fields:
        name_field = opt
        break

qs = TokenModel.objects.filter(user=u)
if name_field:
    obj = (qs.filter(**{name_field: token_name}).order_by(\"pk\").first()
           or qs.order_by(\"pk\").first())
else:
    obj = qs.order_by(\"pk\").first()

if obj:
    token_value = getattr(obj, token_field)
else:
    token_value = secrets.token_urlsafe(32)
    kwargs = {\"user\": u, token_field: token_value}
    if name_field:
        kwargs[name_field] = token_name
    TokenModel.objects.create(**kwargs)

print(token_value)
"
'
