# define environment variables with their default values
INFO_V2_TABLE_NAME="${INFO_V2_TABLE_NAME:-watch-info-v2-watches}"
INFO_V2_FUN_ROLE="${INFO_V2_FUN_ROLE:-watch-info-v2-fun-role}"
INFO_V2_FUN_CREATE="${INFO_V2_FUN_CREATE:-watch-info-v2-create}"
INFO_V2_FUN_READ="${INFO_V2_FUN_READ:-watch-info-v2-read}"
INFO_V2_API_ROLE="${INFO_V2_API_ROLE:-watch-info-v2-api-role}"
INFO_V2_API_STAGE="${INFO_V2_API_STAGE:-v2}"

# configure AWS CLI
export AWS_DEFAULT_OUTPUT="json"
export AWS_PAGER=""
