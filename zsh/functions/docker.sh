function launch_container() {
    docker run -it \
        --entrypoint="" \
        -e POETRY_HTTP_BASIC_JFROG_PASSWORD=${POETRY_HTTP_BASIC_JFROG_PASSWORD} \
        -e POETRY_HTTP_BASIC_JFROG_USERNAME=${POETRY_HTTP_BASIC_JFROG_USERNAME} \
        -e POETRY_HTTP_BASIC_ARTIFACTORY_PASSWORD=${POETRY_HTTP_BASIC_ARTIFACTORY_PASSWORD} \
        -e POETRY_HTTP_BASIC_ARTIFACTORY_USERNAME=${POETRY_HTTP_BASIC_ARTIFACTORY_USERNAME} \
        -e BUNDLE_RAMSEYSOLUTIONS__JFROG__IO=$BUNDLE_RAMSEYSOLUTIONS__JFROG__IO \
        -e ARTIFACTORY_TOKEN=$ARTIFACTORY_TOKEN \
        -e ARTIFACTORY_USERNAME=$ARTIFACTORY_USERNAME \
        -v $PWD:/app \
        -v $HOME/.npmrc:/root/.npmrc \
        -v $HOME/.aws:/root/.aws \
        -v $HOME/.claude:/root/.claude \
        -v $HOME/.claude.json:/root/.claude.json \
        -w /app \
        $1 \
        bash
}

function dockerlogs() {
    local -A tracked_containers
    trap 'kill $(jobs -p) 2>/dev/null; return' INT TERM HUP

    while true; do
        for cid in $(docker ps --filter "ancestor!=mcp/sonarqube" -q 2>/dev/null); do
            if [[ -z "${tracked_containers[$cid]}" ]]; then
                tracked_containers[$cid]=1
                docker logs -f --tail 100 "$cid" 2>&1 | sed "s/^/[$(docker inspect --format '{{.Name}}' "$cid" | sed 's/^\///')]] /" &
            fi
        done
        sleep 5
    done
}
