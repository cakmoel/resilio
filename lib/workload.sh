# shellcheck shell=bash
# shellcheck disable=SC2034

declare -A SCENARIOS=(
  ["STATIC"]="http://example.com/login"
  ["DYNAMIC"]="http://example.com/post/3/any-url-path"
  ["404_ERROR"]="http://example.com/this-is-not-real-page"
)

declare -A CONCURRENCY=(
  ["STATIC"]=10
  ["DYNAMIC"]=10
  ["404_ERROR"]=10
)
