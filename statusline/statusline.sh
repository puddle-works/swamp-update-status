#!/bin/sh
input=$(cat)

swamp_ver=""
if [ -f ~/.claude/.swamp-version ]; then
  swamp_ver=$(tr -d '\n' < ~/.claude/.swamp-version | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi

echo "$input" | jq -r --arg swamp "$swamp_ver" '
  def fmt_time_left(reset):
    if reset == null then null else
      (reset - now) as $s |
      if $s <= 0 then "0m"
      else
        ($s / 86400 | floor) as $d |
        (($s % 86400) / 3600 | floor) as $h |
        (($s % 3600) / 60 | floor) as $m |
        if $d > 0 then "\($d)d \($h)h"
        elif $h > 0 then "\($h)h \($m)m"
        else "\($m)m"
        end
      end
    end;

  (.model.display_name // .model.id // "unknown") as $model |
  (.context_window.total_input_tokens // 0 | if . >= 1000 then (. / 1000 | round | tostring) + "k" else tostring end) as $tokens |
  (.context_window.used_percentage // 0 | round) as $ctx_pct |
  (.rate_limits.five_hour.used_percentage) as $sess_pct |
  (fmt_time_left(.rate_limits.five_hour.resets_at)) as $sess_reset |
  (.rate_limits.seven_day.used_percentage) as $week_pct |
  (fmt_time_left(.rate_limits.seven_day.resets_at)) as $week_reset |

  [
    "🤖 \($model)",
    (if $sess_pct then "📊 \($sess_pct|round)% 5h" + (if $sess_reset then " (\($sess_reset) left)" else "" end) else empty end),
    (if $week_pct then "📅 \($week_pct|round)% wk" + (if $week_reset then " (\($week_reset) left)" else "" end) else empty end),
    "🧠 \($tokens) (\($ctx_pct)%)",
    (if $swamp != "" then "🐊 SC \($swamp)" else empty end)
  ] | join(" | ")
'
