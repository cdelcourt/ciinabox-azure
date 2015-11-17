# ciinabox Azure

ciinabox (CI in a Box) pronounced ciin a box is a set of automation for building
and managing a bunch of CI tools in Azure.

Right Now ciinabox supports deploying:

 * jenkins
 * private docker registry
 * chef server

## Setup

requires docker 1.6+ and docker-machine 0.5+
just install docker toolbox https://www.docker.com/docker-toolbox

1. docker-machine create -d virtualbox ciinabox
2. eval $(docker-machine env ciinabox)
3. docker pull base2/ciinabox-azure
4. mkdir /somepath/ciinaboxes
5. cd /somepath/ciinaboxes
6. docker run --rm -it -v `pwd`:/opt/ciinabox/ciinaboxes base2/ciinabox-azure

## Getting Started

1. Initialize/Create a new ciinabox environment
  ```bash
  $ ./ciinabox init
  Enter the name of ypur ciinabox:
  myciinabox
  ```
  You can override the default ciinaboxes directory by setting the CIINABOXES_DIR environment variable. Also the DNS domain you entered about must already exist in Azure DNS

2. check that your new ciinabox is the current active one and login to azure
  ```bash
  $ ./ciinabox login
  # Enable active ciinabox by executing or override ciinaboxes base directory:
  export CIINABOXES_DIR="ciinaboxes/"
  export CIINABOX="myciinabox"
  # or run
  eval $(./ciinabox login[myciinabox])
  ```

9. Create/Lanuch ciinabox environment
  ```bash
  $ rake ciinabox:create
  Starting updating of ciinabox environment
  # checking status using
  $ rake ciinabox:status
  allday ciinabox is in state: CREATE_IN_PROGRESS
  # When your ciinabox environment is ready the status will be
  allday ciinabox is alive!!!!
  ECS cluster private ip:10.xx.xx.xx
  ```
  You can access jenkins using http://jenkins.myciinabox.com
