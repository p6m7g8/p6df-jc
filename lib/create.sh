######################################################################
#<
#
# Function: p6_jc__debug(msg)
#
#  Args:
#	msg - 
#
#>
######################################################################
p6_jc__debug() {
    local msg="$1"

    p6_debug "p6_jc: $msg"
}

######################################################################
#<
#
# Function: str assertion64 = p6_jc_saml_login(auth)
#
#  Args:
#	auth - 
#
#  Returns:
#	str - assertion64
#
#>
######################################################################
p6_jc_saml_login() {
    local auth="$1"

    local dir=$(p6_transient_create "jc_cookie")
    local cookie_file=$(p6_jc_cookie_file_get "$dir")

    local xsrf=$(p6_jc_xsrf_get "$cookie_file")
    local assertion64=$(p6_jc_auth "$cookie_file" "$xsrf" "$auth")

    p6_transient_delete "$dir"

    p6_return_str "$assertion64"
}

######################################################################
#<
#
# Function: str xsrf = p6_jc_xsrf_get(cookie_file)
#
#  Args:
#	cookie_file - 
#
#  Returns:
#	str - xsrf
#
#>
######################################################################
p6_jc_xsrf_get() {
    local cookie_file="$1"

    local url=$(p6_jc_xsrf_url_get)

    p6_file_rmf "$cookie_file"

    local output=$(curl -sL -c $cookie_file $url)
    local xsrf=$(p6_echo "$output" | p6_json_key_2_value "xsrf" "-")
    p6_jc__debug "xsrf_get(): [xsrf=$xsrf]"

    p6_return_str "$xsrf"
}

######################################################################
#<
#
# Function: str assertion64 = p6_jc_auth(cookie_file, xsrf, auth)
#
#  Args:
#	cookie_file - 
#	xsrf - 
#	auth - 
#
#  Returns:
#	str - assertion64
#
#>
######################################################################
p6_jc_auth() {
    local cookie_file="$1"
    local xsrf="$2"
    local auth="$3"

    local url=$(p6_jc_auth_url_get)

    # XXX: login->email is intentional mapping p6 to idp
    local email=$(p6_obj_item_get "$auth" "login")
    local password=$(p6_obj_item_get "$auth" "password")
    local account_alias=$(p6_obj_item_get "$auth" "account_alias")

    local json=$(p6_aws_template_process \
		     "jc/auth.json" \
		     "EMAIL=$email" \
		     "PASSWORD=$password" \
		     "ACCOUNT=aws-${account_alias}")

    local dir=$(p6_transient_create "jc_auth")
    local file="$dir/file"
    p6_file_write "$file" "$json"

    curl -L -s \
	 -o $dir/response.html \
	 -b $cookie_file -c $cookie_file \
	 -H "X-Xsrftoken: $xsrf" \
	 -H "Content-Type: application/json" \
	 -d "@$file" \
	 $url

    # XXX: recode
    local assertion64=$(grep SAMLResponse $dir/response.html |sed -e 's,.*value=",,' -e 's,".*,,' | recode html)

    p6_transient_delete "$dir"

    p6_return_str "$assertion64"
}

######################################################################
#<
#
# Function: path dir/cookies.txt = p6_jc_cookie_file_get(dir)
#
#  Args:
#	dir - 
#
#  Returns:
#	path - dir/cookies.txt
#
#>
######################################################################
p6_jc_cookie_file_get() {
    local dir="$1"

    p6_return_path "$dir/cookies.txt"
}

######################################################################
#<
#
# Function: str https://console.jumpcloud.com/userconsole/xsrf = p6_jc_xsrf_url_get()
#
#  Returns:
#	str - https://console.jumpcloud.com/userconsole/xsrf
#
#>
######################################################################
p6_jc_xsrf_url_get() {

    p6_return_str "https://console.jumpcloud.com/userconsole/xsrf"
}

######################################################################
#<
#
# Function: str https://console.jumpcloud.com/userconsole/auth = p6_jc_auth_url_get()
#
#  Returns:
#	str - https://console.jumpcloud.com/userconsole/auth
#
#>
######################################################################
p6_jc_auth_url_get() {

    p6_return_str "https://console.jumpcloud.com/userconsole/auth"
}

######################################################################
#<
#
# Function: path  = p6_jc_app_create(org, account_id, cert_subject, cert_bits, cert_exp, saml_provider, saml_provider_email, role_full_path)
#
#  Args:
#	org - 
#	account_id - 
#	cert_subject - 
#	cert_bits - 
#	cert_exp - 
#	saml_provider - 
#	saml_provider_email - 
#	role_full_path - 
#
#  Returns:
#	path - 
#
#>
######################################################################
p6_jc_app_create() {
    local org="$1"
    local account_id="$2"
    local cert_subject="$3"
    local cert_bits="$4"
    local cert_exp="$5"
    local saml_provider="$6"
    local saml_provider_email="$7"
    local role_full_path="$8"

    local app="aws"

    local dir=$(p6_transient_create "tmp.jc")
    local key_file="$dir/${account_id}.key"

    p6_openssl_genrsa "$key_file" "$cert_bits"
    local crt_file="$dir/${account_id}.crt"

    p6_openssl_req_509 "$key_file" "$crt_file" "$cert_exp" "$cert_subject"

    local $saml_file=$(\
	jc_app.py \
		--key $key_file \
		--crt $crt_file \
		--org $org \
		--account_id $account_id \
		--role_path $role_full_path \
		--provider $saml_provider \
		--login $saml_provider_email
	\ )

    local dst_saml_file=$dir/${account_id}-${app}-${saml_provider}.xml
    p6_file_move "$saml_file" "$dst_saml_file"

    p6_return_path $dst_saml_file
}
