### init.zsh:
- p6_jc_init(dir)
- p6df::modules::jc::deps()
- p6df::modules::jc::external::brew()
- p6df::modules::jc::init()
- p6df::modules::jc::version()

### create.sh:
- path  = p6_jc_app_create(org, account_id, cert_subject, cert_bits, cert_exp, saml_provider, saml_provider_email, role_full_path)
- path dir/cookies.txt = p6_jc_cookie_file_get(dir)
- str assertion64 = p6_jc_auth(cookie_file, xsrf, auth)
- str assertion64 = p6_jc_saml_login(auth)
- str https://console.jumpcloud.com/userconsole/auth = p6_jc_auth_url_get()
- str https://console.jumpcloud.com/userconsole/xsrf = p6_jc_xsrf_url_get()
- str xsrf = p6_jc_xsrf_get(cookie_file)

