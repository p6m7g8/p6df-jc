######################################################################
#<
#
# Function:
#	unkown  = p6_jc_app_create(org, account_id, cert_subject, cert_bits, cert_exp, saml_provider, saml_provider_email, role_full_path)
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
#	unkown -
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
