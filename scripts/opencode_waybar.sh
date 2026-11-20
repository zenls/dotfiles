#!/usr/bin/env bash
# OpenCode 2 status streamed directly to Waybar. No service or shared cache.
SCRIPT_DIR=$(cd -- "${BASH_SOURCE[0]%/*}" && pwd)
OC_REGISTRY=${XDG_STATE_HOME:-$HOME/.local/state}/opencode/service.json
OC_PROC=/proc
OC_WORKDIR='' OC_URL='' OC_CONNECTION='' OC_STREAM_PID='' OC_LAST=''
OC_DIRTY=true

render_widget() {
    jq -c '
        def color: {waiting:"#f9e2af",working:"#f38ba8",idle:"#a6e3a1",unavailable:"#a6adc8"}[.state];
        def dot: "<span foreground=\"" + color + "\">●</span>";
        def status_label: {waiting:"WAIT",working:"RUN",idle:"IDLE",unavailable:"ERR"}[.state];
        def short($n): tostring | gsub("[\u0000-\u001f\u007f]"; " ") |
            if length > $n then .[0:($n-1)] + "…" else . end;
        . as $entries |
        {text:($entries | map(dot) | join(" ")), class:"sessions",
         tooltip:(if ($entries|length) == 0 then "" else
             "<span font_family=\"JetBrainsMono Nerd Font\">┌ OC · \($entries|length)\n" +
             ($entries | to_entries | map(
                 (if .key == ($entries|length)-1 then "└ " else "├ " end) +
                 (.value | dot + " " + (.project|short(28)|@html) + " ▸ " + status_label +
                   (if .permissions > 0 then " !\(.permissions)" else "" end) +
                   (if .forms > 0 then " ?\(.forms)" else "" end)) + "\n" +
                 (if .key == ($entries|length)-1 then "  " else "│ " end) +
                 (.value | (if .error != "" then .error else .title end) | short(64) | @html)
             ) | join("\n")) + "</span>" end)}'
}

discover_clients() {
    local pid cwd explicit server arg term caller standalone i
    local -a argv
    while IFS= read -r pid; do
        [[ $pid =~ ^[0-9]+$ && -r $OC_PROC/$pid/environ ]] || continue
        mapfile -d '' -t argv < "$OC_PROC/$pid/cmdline" 2>/dev/null || continue
        [[ ${#argv[@]} -gt 0 ]] || continue
        # The shared service can inherit VS Code's environment from its parent.
        # It is not itself an editor client.
        case ${argv[1]:-} in
            serve|service|api|auth|run|session|mcp|models|stats|debug|plugin|upgrade|update|reload|pair|acp|mini|uninstall) continue ;;
        esac
        term='' caller=''
        while IFS= read -r -d '' arg; do
            case $arg in
                TERM_PROGRAM=*) term=${arg#*=} ;;
                OPENCODE_CALLER=*) caller=${arg#*=} ;;
            esac
        done < "$OC_PROC/$pid/environ" 2>/dev/null
        [[ $term == vscode || $caller == vscode ]] || continue
        cwd=$(readlink -- "$OC_PROC/$pid/cwd" 2>/dev/null) || continue
        [[ $cwd == /* ]] || continue
        explicit='' server='' standalone=false
        for ((i = 1; i < ${#argv[@]}; i++)); do
            arg=${argv[i]}
            case $arg in
                -s|--session) explicit=${argv[++i]:-} ;;
                --session=*) explicit=${arg#*=} ;;
                --server) server=${argv[++i]:-} ;;
                --server=*) server=${arg#*=} ;;
                --standalone) standalone=true ;;
                --prompt|--log-level) ((i++)) ;;
                --help|-h|--version|-v|--completions) standalone=true ;;
                -*) ;;
                *)
                    if [[ $arg == /* ]]; then cwd=$arg
                    else cwd=$(realpath -m -- "$cwd/$arg"); fi ;;
            esac
        done
        jq -cn --arg directory "${cwd%/}/" \
            --arg session "$explicit" --arg server "$server" --argjson standalone "$standalone" \
            '{directory:($directory|rtrimstr("/")|if . == "" then "/" else . end),
              session:$session,server:$server,standalone:$standalone}'
    done < <(pgrep -u "$UID" -x 'opencode|opencode2' || true)
}

api_get() {
    [[ -n $OC_URL ]] || return 1
    curl --config "$OC_WORKDIR/auth.conf" --noproxy '*' --silent --show-error --fail \
        --connect-timeout 1 --max-time 2 "$OC_URL$1" 2>/dev/null
}

project_session() {
    local directory=$1 response cursor='' next encoded all='[]' count
    encoded=$(jq -rn --arg d "$directory" '$d|@uri')
    while :; do
        response=$(api_get "/api/session?directory=$encoded&parentID=null&archived=false&limit=100&order=desc${cursor:+&cursor=$cursor}") || return 1
        jq -e '.data|type == "array"' >/dev/null 2>&1 <<< "$response" || return 1
        all=$(jq -cn --argjson a "$all" --argjson b "$response" '$a + $b.data')
        count=$(jq '.data|length' <<< "$response")
        (( count < 100 )) && break
        next=$(jq -r '.cursor.next // empty | @uri' <<< "$response")
        [[ -n $next && $next != "$cursor" ]] || break
        cursor=$next
    done
    # Viewed sessions can be older than the first page of the recency list.
    jq -c 'sort_by([.time.viewed // .time.created // 0, .time.updated // 0]) |
        if length > 0 then [last] else [] end' <<< "$all"
}

collect_client() {
    local client=$1 active=$2 active_info=$3
    local directory explicit server sessions info session_id permissions forms records='[]' error=''
    directory=$(jq -r .directory <<< "$client")
    explicit=$(jq -r .session <<< "$client")
    server=$(jq -r .server <<< "$client")
    if [[ $(jq -r .standalone <<< "$client") == true || ( -n $server && ${server%/} != "$OC_URL" ) ]]; then
        error='This client does not use the registered background service'
    elif [[ $active == null ]]; then
        error='OpenCode API unavailable'
    fi
    sessions='[]'
    if [[ -z $error ]]; then
        if [[ -n $explicit ]]; then
            if info=$(api_get "/api/session/$explicit") && jq -e '.data.id|strings' >/dev/null <<< "$info"; then
                sessions=$(jq -c '[.data]' <<< "$info")
                directory=$(jq -r '.data.location.directory' <<< "$info")
            else
                error='Cannot read the requested session'
            fi
        else
            # The server is shared. Never choose its globally newest session.
            if ! sessions=$(project_session "$directory"); then
                error='Cannot list project sessions'
                sessions='[]'
            fi
        fi
        # Include active work in this project, including agent child sessions.
        sessions=$(jq -cn --argjson primary "$sessions" --argjson running "$active_info" \
            --arg directory "$directory" --arg explicit "$explicit" '
            ($primary + [$running[] | select(.location.directory == $directory) |
              select($explicit == "" or .id == $explicit or .parentID == $explicit)]) | unique_by(.id)')
        while IFS= read -r info; do
            [[ -n $info ]] || continue
            session_id=$(jq -r .id <<< "$info")
            if ! permissions=$(api_get "/api/session/$session_id/permission") ||
                ! jq -e '.data|type == "array"' >/dev/null 2>&1 <<< "$permissions"; then
                error='Cannot read pending permissions'; permissions='{"data":[]}'
            fi
            if ! forms=$(api_get "/api/session/$session_id/form") ||
                ! jq -e '.data|type == "array"' >/dev/null 2>&1 <<< "$forms"; then
                error='Cannot read pending forms'; forms='{"data":[]}'
            fi
            records=$(jq -cn --argjson records "$records" --argjson info "$info" \
                --argjson permissions "$permissions" --argjson forms "$forms" --argjson active "$active" '
                $records + [{info:$info,permissions:$permissions.data,forms:$forms.data,
                  working:($active != null and ($active|has($info.id)))}]')
        done < <(jq -c '.[]' <<< "$sessions")
    fi
    jq -cn --argjson client "$client" --argjson records "$records" --arg directory "$directory" \
        --arg error "$error" -f "$SCRIPT_DIR/opencode_waybar.jq"
}

stop_stream() {
    exec 3<&-
    if [[ -n $OC_STREAM_PID ]]; then
        kill "$OC_STREAM_PID" 2>/dev/null || true
        wait "$OC_STREAM_PID" 2>/dev/null || true
        OC_STREAM_PID=''
    fi
}

load_connection() {
    local connection
    connection=$(jq -ce '{url,password,pid,id} | select((.url|type) == "string" and
        (.password|type) == "string")' "$OC_REGISTRY" 2>/dev/null) || connection=''
    [[ $connection == "$OC_CONNECTION" ]] && return
    stop_stream
    OC_CONNECTION=$connection OC_URL='' OC_DIRTY=true
    if [[ -n $connection ]]; then
        OC_URL=$(jq -r .url <<< "$connection")
        if [[ $OC_URL =~ ^http://(127\.0\.0\.1|localhost|\[::1\]):[0-9]+/?$ ]]; then
            OC_URL=${OC_URL%/}
            jq -r '"user = " + (("opencode:" + .password)|@json)' <<< "$connection" > "$OC_WORKDIR/auth.conf"
        else OC_URL=''; fi
    fi
}

start_stream() {
    local event
    local -a filters=()
    for event in location.shutdown session.created session.deleted session.renamed session.moved \
        session.viewed session.archived session.unarchived session.status session.idle \
        session.execution.started session.execution.succeeded session.execution.failed \
        session.execution.interrupted permission.asked permission.replied form.created form.replied form.cancelled; do
        filters+=(--data-urlencode "types=$event")
    done
    exec 3< <(exec curl --config "$OC_WORKDIR/auth.conf" --noproxy '*' -sNf \
        --connect-timeout 1 --speed-limit 1 --speed-time 45 \
        --get "${filters[@]}" "$OC_URL/api/event" 2>/dev/null)
    OC_STREAM_PID=$!
}

emit() {
    local output
    output=$(render_widget <<< "$1") || return 1
    if [[ $output != "$OC_LAST" ]]; then
        printf '%s\n' "$output" || exit 0
        OC_LAST=$output
    fi
}

refresh() {
    local clients=$1 active=null info active_info='[]' id client result rows='[]'
    info=$(api_get /api/session/active)
    if jq -e '.data|type == "object"' >/dev/null 2>&1 <<< "$info"; then
        active=$(jq -c .data <<< "$info")
        while IFS= read -r id; do
            if info=$(api_get "/api/session/$id") && jq -e '.data.id|strings' >/dev/null <<< "$info"; then
                active_info=$(jq -cn --argjson a "$active_info" --argjson b "$info" '$a + [$b.data]')
            else active=null; break; fi
        done < <(jq -r 'keys[]' <<< "$active")
    fi
    while IFS= read -r client; do
        [[ -n $client ]] || continue
        result=$(collect_client "$client" "$active" "$active_info") || result=$(collect_client "$client" null '[]')
        rows=$(jq -cn --argjson a "$rows" --argjson b "$result" '$a + $b') || return 1
    done <<< "$clients"
    emit "$(jq -c 'group_by(.id) | map(sort_by({waiting:3,unavailable:2,working:1,idle:0}[.state]) | last)' <<< "$rows")"
}

cleanup() {
    stop_stream
    [[ -z $OC_WORKDIR ]] || rm -rf -- "$OC_WORKDIR"
}

main() {
    local clients='' previous='' line rc next_scan=0 next_sync=0 next_update=0 next_connect=0 retry=2
    umask 077
    OC_WORKDIR=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/waybar-opencode.XXXXXX") || return 1
    trap cleanup EXIT
    trap 'exit 0' INT TERM
    if [[ ${1:-} != --once ]]; then emit '[]' || return 1; fi
    while :; do
        if (( SECONDS >= next_scan )); then
            clients=$(discover_clients | jq -sc 'unique_by([.directory,.session,.server,.standalone])[]')
            [[ $clients != "$previous" ]] && { OC_DIRTY=true; previous=$clients; }
            load_connection
            next_scan=$((SECONDS + 2))
        fi
        if [[ -z $clients ]]; then
            stop_stream
            emit '[]' || return 1
        else
            if [[ ${1:-} != --once && -n $OC_URL && -z $OC_STREAM_PID ]] && (( SECONDS >= next_connect )); then
                start_stream
            fi
            if { $OC_DIRTY && (( SECONDS >= next_update )); } || (( SECONDS >= next_sync )); then
                OC_DIRTY=false
                refresh "$clients" || return 1
                next_update=$((SECONDS + 1)) next_sync=$((SECONDS + 30))
            fi
        fi
        [[ ${1:-} == --once ]] && return 0
        if [[ -n $OC_STREAM_PID ]]; then
            IFS= read -r -t 1 line <&3; rc=$?
            if (( rc == 0 )); then
                # The server filters events; token/reasoning deltas never reach this stream.
                [[ $line == data:* ]] && { OC_DIRTY=true; retry=2; }
            elif (( rc == 1 )); then
                stop_stream
                OC_DIRTY=true next_connect=$((SECONDS + retry))
                (( retry < 16 )) && retry=$((retry * 2))
            fi
        else sleep 1; fi
    done
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    case ${1:-} in
        ''|--once) main "${1:-}" ;;
        *) printf 'Usage: %s [--once]\n' "$0" >&2; exit 2 ;;
    esac
fi
