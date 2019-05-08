#!/usr/bin/env python

"""
jc_app.py

Setup Jump Cloud AWS Application
Will prompt for password interactively

Usage:
 jc_app.py --key=<key> --crt=<crt> --org=<org> --account_id=<account_id> --role_path=<role_path> --provider=<provider> --login=<login>

Options:
  --key=<key>               path to idp key
  --crt=<crt>               path to idp crt
  --org=<org>               aws org name
  --account_id=<account_id> aws account id
  --role_path=<role_path>   FULL path of role [no leading /] (i.e. path/name)
  --provider=<provider>     provider name
  --login=<login>           jump cloud admin login
"""
from docopt import docopt

import getpass
import json
import os
import sys
import time

from selenium import webdriver
from selenium.webdriver.common.keys import Keys

def login(args):
    """
    """

    passwd = getpass.getpass()

    browser = webdriver.Chrome()

    browser.get('https://console.jumpcloud.com/login')
    browser.find_element_by_xpath("/html/body/div/section/button/span").click()
    time.sleep(1)

    email = browser.find_element_by_name("email");
    password = browser.find_element_by_name("password");
    email.send_keys(args["--login"])
    password.send_keys(passwd)

    browser.find_element_by_xpath("/html/body/div/section/div[1]/div/div/form/button/span").click()
    time.sleep(2)

    return browser

def goto_applications(browser):
    """
    """

    browser.get('https://console.jumpcloud.com/#/applications')
    time.sleep(3)

    return

def add_application(browser, args):
    """
    """

    # Add(+)
    browser.find_element_by_xpath("/html/body/main/div[1]/div[2]/div/a/i").click()
    time.sleep(1)

    # AWS(configure)
    browser.find_element_by_xpath("/html/body/aside/div/div[2]/div/div[4]/div[10]/a").click()
    time.sleep(1)

    # Display Label
    display_label = browser.find_element_by_xpath("/html/body/aside/div/div[2]/div/div[2]/div[1]/div/div/input")
    display_label.clear()
    display_label.send_keys("AWS {}".format(args["--account_alias"]))

    # Key and Cert
    browser.find_element_by_xpath("/html/body/aside/div/div[2]/div/div[2]/div[3]/div[1]/div/input").send_keys(args["--key"])
    browser.find_element_by_xpath("/html/body/aside/div/div[2]/div/div[2]/div[3]/div[2]/div/input").send_keys(args["--crt"])

    # Role
    role = browser.find_element_by_xpath("/html/body/aside/div/div[2]/div/div[2]/div[3]/div[3]/div/div/div[2]/div[2]/div[2]/input")
    role.clear()
    role.send_keys("arn:aws:iam::{}:role/{},arn:aws:iam::{}:saml-provider/{}".format(args["--account_id"], args["--role_path"], args["--account_id"], args["--provider"]))

    # RoleSessionName
    browser.find_element_by_xpath("/html/body/aside/div/div[2]/div/div[2]/div[3]/div[3]/div/div/a").click()

    att_name = browser.find_element_by_xpath("/html/body/aside/div/div[2]/div/div[2]/div[3]/div[3]/div/div/div/div[2]/div[3]/div[1]/input")
    att_name.send_keys("https://aws.amazon.com/SAML/Attributes/RoleSessionName")

    att_val = browser.find_element_by_xpath("/html/body/aside/div/div[2]/div/div[2]/div[3]/div[3]/div/div/div/div[2]/div[3]/div[2]/input")
    att_val.send_keys("SSO-User")

    # IDP URL
    idp_url = browser.find_element_by_xpath("/html/body/aside/div/div[2]/div/div[2]/div[4]/div/div/input")
    idp_url.clear()
    idp_url.send_keys("aws-{}".format(args["--account_alias"]))

    # Activate
    browser.find_element_by_xpath("/html/body/aside/div/div[3]/button").click()
    time.sleep(1)

    # Confirm
    browser.find_element_by_xpath("/html/body/div[8]/div/div/div[3]/a[2]").click()
    time.sleep(1)

    return

def download_saml_metadata_xml(browser, args):
    """
    """

    goto_applications(browser)

    # Application
    browser.find_element_by_xpath("/html/body/main/div/div[4]/div[{}]/a[1]".format(args["--pos"]+2)).click()
    time.sleep(1)

    # Export Metadata
    browser.find_element_by_xpath("/html/body/aside/div/div[3]/a[1]").click()
    time.sleep(1)

    # XXX: MacOS
    home = os.path.expanduser("~")
    os.rename("{}/Downloads/JumpCloud-aws-metadata.xml".format(home), "/tmp/{}-AWS-JumpCloud.xml".format(args["--account_alias"]))

    return

def account_map_get(args):
    """
    """

    home = os.path.expanduser("~")
    map_file  = home + '/.aws/map-' + args["--org"]
    with open(map_file, 'r') as afile:
        account_map = json.load(afile)

    return account_map

def aws_account_id_to_name(args):
    """
    """

    account_map = account_map_get(args)

    return account_map[args["--account_id"]]

def account_ord(args):
    """
    """

    account_map = account_map_get(args)
    inv_map = dict(zip(account_map.values(), account_map.keys()))

    i = 2
    for key in sorted(inv_map):
        if key == args["--account_alias"]:
            return i

        i += 1

def main(args):
    """
    """

    # logic
    args["--account_alias"] = aws_account_id_to_name(args)
    args["--pos"] = account_ord(args)

    # init
    browser = login(args)

    # /applications
    goto_applications(browser)

    # Add IDP
    add_application(browser, args)

    # Download SAML
    download_saml_metadata_xml(browser, args)

    # Quit Driver
    browser.quit()

    print("/tmp/{}-AWS-JumpCloud.xml".format(args["--account_alias"]))

    return

if __name__ == '__main__':
    arguments = docopt(__doc__, options_first=True, version="0.0.1")
    sys.exit(main(arguments))
