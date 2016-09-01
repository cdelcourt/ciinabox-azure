# ciinabox Azure

ciinabox (CI in a Box) pronounced ciin a box is a set of automation for building
and managing a bunch of CI tools in Azure.

![http://azuredeploy.net/deploybutton.png](https://azuredeploy.net/?repository=https://github.com/base2services/ciinabox-azure)

Right Now ciinabox supports deploying:

 * jenkins
 * private docker registry
 * chef server

## Setup

Requires an Azure subscription.

## Getting Started

1. Ensure you are logged into the correct Azure subscription in your browser and then click the 'Deploy to Azure' button above.

2. Fill in the parameters for the environment. It is recommended to deploy to a new resource group rather than an existing one.

3. Once the deployment shows as 'Successful', it may take a few more minutes for Docker to complete pulling the images and for Jenkins to start

4. You will be able to access Jenkins using the URL that you've placed in Step 2 in the 'ciinaboxDomain' parameter
