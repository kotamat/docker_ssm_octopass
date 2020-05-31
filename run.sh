#!/bin/bash

# setup octopass
cat <<CONF > /etc/octopass.conf
Token           = "${GITHUB_TOKEN}"
Organization    = "${GITHUB_ORGANIZATION}"
Team            = "${GITHUB_TEAM}"
Home            = "/home/%s"
Shell           = "/bin/bash"
Syslog          = false
CONF

cat <<CONF >> /etc/ssh/sshd_config
AuthorizedKeysCommand   /usr/bin/octopass
AuthorizedKeysCommandUser   root
UsePAM yes
PasswordAuthentication no
CONF

cat <<CONF | cat - /etc/pam.d/sshd > temp && mv temp /etc/pam.d/sshd
auth    requisite   pam_exec.so quiet   expose_authtok  /usr/bin/octopass   pam
auth    optional    pam_unix.so not_set_pass    use_first_pass  nodelay
session required    pam_mkhomedir.so    skel=/etc/skel/	umask=0022
CONF

sed -i 's/^passwd:.\+$/passwd:     files octopass sss/' /etc/nsswitch.conf
sed -i 's/^shadow:.\+$/shadow:     files octopass sss/' /etc/nsswitch.conf
sed -i 's/^group:.\+$/group:     files octopass sss/' /etc/nsswitch.conf

service ssh start

# setup ssm agent
amazon-ssm-agent -register -code "${SSM_AGENT_CODE}" -id "${SSM_AGENT_ID}" -region "${AWS_DEFAULT_REGION}" 
amazon-ssm-agent