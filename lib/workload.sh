# shellcheck shell=bash
# shellcheck disable=SC2034

declare -A SCENARIOS=(
    ["DYNAMIC"]="http://myblog.local/post/3/visiting-bali-a-journey-of-serenity-and-culture"
    ["STATIC"]="http://myblog.local/login"
    ["404_ERROR"]="http://myblog.local/this-is-not-real-page"
)

declare -A CONCURRENCY=(
  ["STATIC"]=10
  ["DYNAMIC"]=10
  ["404_ERROR"]=10
)
