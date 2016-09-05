#!/bin/bash

export REGION=$1
export AZURE_TAG_ROLE=$2
export ENVIRONMENT_TYPE=$3
export ORG_NAME=$4
export PAGERDUTY_API_KEY=$5

export HOME=/root


#If npm doesn't exist, install npm and Azure CLI
rpm -qa | grep -qw "epel-release" || yum install -y epel-release
rpm -qa | grep -qw nodejs || curl --silent --location https://rpm.nodesource.com/setup_4.x | bash - && yum install -y nodejs && npm install -g azure-cli
rpm -qa | grep -qw python-pip || yum install -y python-pip
rpm -qa | grep -qw chef || yum install -y https://packages.chef.io/stable/el/7/chefdk-0.17.17-1.el7.x86_64.rpm

eval "$(/opt/chefdk/bin/chef shell-init bash)"

if [ -f /etc/profile.d/env.sh ]; then
  source /etc/profile.d/env.sh
fi

# Mount data volume - sdc because sdb = temporary SSD storage
echo '/dev/sdc   /data        ext4    defaults,nofail 0   2' >> /etc/fstab
rm -rf /data && mkdir -p /data
mount /data && echo \"Data volume already formatted\" || mkfs -F -t ext4 /dev/sdc
mount -a && echo 'Mounting Data volume' || echo 'Failed to mount Data volume'

# Install docker - disabled for now while icinga recipe includes docker install
#docker ps || curl -fsSL https://get.docker.com/ | sh
#service docker start

# Install git
yum -y install git

# Prepare directories
mkdir -p /etc/chef/cookbooks/base2-icinga2-docker
chmod -R 777 /etc/chef

cat <<EOT > /etc/chef/override.json
{
  "base2": {
    "environment": {
      "platform": "azure"
    },
    "icinga2": {
      "pagerduty": {
        "api_key": "$PAGERDUTY_API_KEY"
      },
      "org": "$ORG_NAME"
    }
  }
}
EOT

# Install cookbook
git clone https://github.com/base2Services/base2-icinga2-docker-cookbook.git /etc/chef/cookbooks/base2-icinga2-docker

# Install RVM for later version of ruby/gem than CentOS base repo provides
#curl -sSL https://get.rvm.io | bash
#source /etc/profile.d/rvm.sh
#rvm install 2.3.1

# Install Ruby from Repo and enable
#yum -y install centos-release-scl-rh centos-release-scl
#yum --enablerepo=centos-sclo-rh -y install rh-ruby23
#scl enable rh-ruby23 bash

# Install berkshelf for cookbook dependancies
#gem install berkshelf

cd /etc/chef/cookbooks/base2-icinga2-docker
berks install
berks vendor /etc/chef/cookbooks/

#Disable SELinux that prevents issues with the icinga container
cp /etc/sysconfig/selinux /etc/sysconfig/selinux.bak
cat /etc/sysconfig/selinux.bak | sed s/"SELINUX=enforcing"/"SELINUX=disabled"/g > /etc/sysconfig/selinux
setenforce 0

# Run chef
cd /etc/chef
/opt/chefdk/bin/chef-client --local-mode -j /etc/chef/override.json -o "recipe[base2-icinga2-docker::install],recipe[base2-icinga2-docker::run]" > /etc/chef/bootstrap.log
