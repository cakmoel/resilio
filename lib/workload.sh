# shellcheck shell=bash
# shellcheck disable=SC2034

# Base URL constants - change here to update all test targets
BASE_URL_DYNAMIC="http://myblog.local"
BASE_URL_STATIC="http://myblog.local"
BASE_URL_ERROR="http://myblog.local"

# URL path patterns
DYNAMIC_PATH="/post/3/visiting-bali-a-journey-of-serenity-and-culture"
STATIC_PATH="/login"
ERROR_PATH="/this-is-not-real-page"

declare -A SCENARIOS=(
    ["DYNAMIC"]="${BASE_URL_DYNAMIC}${DYNAMIC_PATH}"
    ["STATIC"]="${BASE_URL_STATIC}${STATIC_PATH}"
    ["404_ERROR"]="${BASE_URL_ERROR}${ERROR_PATH}"
)

declare -A CONCURRENCY=(
  ["STATIC"]=10
  ["DYNAMIC"]=10
  ["404_ERROR"]=10
)
