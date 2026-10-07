function dockerlogs() {
    local -A tracked_containers
    trap 'kill $(jobs -p) 2>/dev/null; return' INT TERM HUP

    while true; do
        for cid in $(docker ps -q 2>/dev/null); do
            if [[ -z "${tracked_containers[$cid]}" ]]; then
                tracked_containers[$cid]=1
                docker logs -f --tail 100 "$cid" 2>&1 | sed "s/^/[$(docker inspect --format '{{.Name}}' "$cid" | sed 's/^\///')]] /" &
            fi
        done
        sleep 5
    done
}
