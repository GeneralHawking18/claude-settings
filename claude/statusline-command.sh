#!/bin/bash

input=$(cat)

cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
model=$(echo "$input" | jq -r '.model.id // .model.display_name // empty')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
rl_5h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_5h_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

# claude-sonnet-4-6-20251022 -> Snt4.6, claude-opus-4-7 -> Ops4.7, claude-haiku-4-5 -> Hku4.5
shorten_model() {
    local id="$1"
    local ver=$(echo "$id" | grep -oE '[0-9]+(-[0-9]+)+' | head -1 | sed 's/-/./g' | grep -oE '^[0-9]+\.[0-9]+')
    case "$id" in
        *sonnet*) echo "Snt${ver}" ;;
        *opus*)   echo "Ops${ver}" ;;
        *haiku*)  echo "Hku${ver}" ;;
        *)        echo "$id" | sed -E 's/claude-//;s/-[0-9]{8}$//' ;;
    esac
}

make_bar() {
    local pct=$1 size=4
    local filled=$(printf "%.0f" "$(echo "scale=2; $pct * $size / 100" | bc)")
    local bar=""
    for i in $(seq 1 $size); do
        [ "$i" -le "$filled" ] && bar="${bar}█" || bar="${bar}░"
    done
    echo "$bar"
}

fmt_dur() {
    local ms=$1
    [ -z "$ms" ] || [ "$ms" = "null" ] || [ "$ms" = "0" ] && return
    local s=$((ms/1000)) m=$((ms/60000)) h=$((ms/3600000))
    if [ $h -gt 0 ]; then   printf '%dh%dm' "$h" "$(( (ms/60000) % 60 ))"
    elif [ $m -gt 0 ]; then printf '%dm%ds' "$m" "$(( s % 60 ))"
    else                    printf '%ds' "$s"
    fi
}

if [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
    sep=" │ "
    parts=""

    # ◆ Model
    model_s=$(shorten_model "$model")
    [ -n "$model_s" ] && parts="◆ ${model_s}"

    # $ Cost
    if [ -n "$cost" ] && [ "$cost" != "null" ]; then
        parts="${parts:+$parts$sep}\$ $(printf '%.2f' "$cost")"
    fi

    # ↕ Tokens in/out
    if [ -n "$total_in" ] && [ "$total_in" != "null" ]; then
        in_k=$(printf '%.0f' "$(echo "scale=1; $total_in/1000" | bc)")
        out_k=$(printf '%.0f' "$(echo "scale=1; ${total_out:-0}/1000" | bc)")
        parts="${parts:+$parts$sep}↕ ${in_k}k/${out_k}k"
    fi

    # ▣ Context bar
    ctx_bar=$(make_bar "$used_pct")
    ctx_fmt=$(printf "%.0f" "$used_pct")
    parts="${parts:+$parts$sep}▣ [${ctx_bar}]${ctx_fmt}%"

    # ↺ Cache efficiency
    if [ -n "$cache_read" ] && [ "$cache_read" != "null" ] && [ "$cache_read" -gt 0 ]; then
        total_input=$((cache_read + input_tokens))
        if [ $total_input -gt 0 ]; then
            cache_pct=$(echo "scale=0; $cache_read * 100 / $total_input" | bc)
            parts="${parts:+$parts$sep}↺ ${cache_pct}%"
        fi
    fi

    # ◉ Rate limit bar
    if [ -n "$rl_5h_pct" ] && [ -n "$rl_5h_resets" ] && [ "$rl_5h_resets" != "null" ]; then
        rl_bar=$(make_bar "$rl_5h_pct")
        rl_fmt=$(printf "%.0f" "$rl_5h_pct")
        resets_in=$(( rl_5h_resets - $(date +%s) ))
        if [ "$resets_in" -gt 0 ]; then
            rm=$(( resets_in / 60 ))
            reset_str=$(printf '%dh%dm' "$((rm/60))" "$((rm%60))")
        else
            reset_str="soon"
        fi
        parts="${parts:+$parts$sep}◉ [${rl_bar}]${rl_fmt}% ${reset_str}"
    fi

    # ▶ Duration
    dur=$(fmt_dur "$duration_ms")
    [ -n "$dur" ] && parts="${parts:+$parts$sep}▶ ${dur}"

    printf '%s' "$parts"
else
    [ -n "$model" ] && printf '◆ %s' "$(shorten_model "$model")" || printf 'Claude'
fi
