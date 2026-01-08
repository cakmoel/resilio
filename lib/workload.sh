# shellcheck shell=bash
# shellcheck disable=SC2034

declare -A SCENARIOS=(
  ["404_Error"]="http://myblog.local/this-page-is-not-real"
  ["Static"]="http://myblog.local/login"
  ["Dynamic"]="http://myblog.local/post/4/code-like-a-pro-6-python-tips-every-beginner-must-know"
  ["API_Endpoint"]="http://myblog.local/api/v1/status"
)

declare -A CONCURRENCY=(
  ["404_Error"]=50
  ["Static"]=50
  ["Dynamic"]=25
  ["API_Endpoint"]=50
)
