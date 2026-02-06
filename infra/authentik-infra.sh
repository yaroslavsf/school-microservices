#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
TF_DIR="$ROOT_DIR/infra/authentik"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ .env not found in project root"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [[ -z "${AUTHENTIK_API_TOKEN:-}" ]]; then
  echo "❌ AUTHENTIK_API_TOKEN is not set in .env"
  exit 1
fi

echo "▶ Running terraform for authentik..."

# 🔴 FIX for Git Bash on Windows
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"

docker run --rm \
  --network mvp-microservices-platform_internal \
  -v "$TF_DIR:/workspace" \
  -w /workspace \
  -e TF_VAR_authentik_url="http://authentik-server:9000" \
  -e TF_VAR_authentik_token="$AUTHENTIK_API_TOKEN" \
  -e TF_VAR_base_domain="${BASE_DOMAIN:-localhost}" \
  hashicorp/terraform:1.7.5 \
  apply -auto-approve


echo "✔ Terraform apply finished"
