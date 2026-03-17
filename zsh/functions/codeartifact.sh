rl() {
	local domain="ramsey-solutions"
	local owner="058238361356"
	local region="us-east-1"
	local duration=43200
	local env_file="$HOME/.ramsey/env"

	local token
	token=$(aws codeartifact get-authorization-token \
		--profile rs-cicd \
		--domain "$domain" \
		--domain-owner "$owner" \
		--region "$region" \
		--duration-seconds "$duration" \
		--query authorizationToken \
		--output text 2>&1) || { echo "[ERROR] Failed to get CodeArtifact token: $token"; return 1; }

	mkdir -p "$HOME/.ramsey" && chmod 700 "$HOME/.ramsey"

	cat > "$env_file" <<EOF
# Token refreshed: $(date -u +%Y-%m-%dT%H:%M:%SZ) — expires ~12h — run 'rl' to refresh
export CODEARTIFACT_AUTH_TOKEN="$token"
export POETRY_HTTP_BASIC_CODEARTIFACT_USERNAME="aws"
export POETRY_HTTP_BASIC_CODEARTIFACT_PASSWORD="\${CODEARTIFACT_AUTH_TOKEN}"
export PIP_INDEX_URL="https://aws:\${CODEARTIFACT_AUTH_TOKEN}@${domain}-${owner}.d.codeartifact.${region}.amazonaws.com/pypi/pypi-aggregate/simple/"
export BUNDLE_RAMSEY___SOLUTIONS___058238361356__D__CODEARTIFACT__US___EAST___1__AMAZONAWS__COM="aws:\${CODEARTIFACT_AUTH_TOKEN}"
EOF
	chmod 600 "$env_file"

	source "$env_file"
	echo "CodeArtifact token refreshed. Expires in ~12h."
}
