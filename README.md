# Introduction

![CI](https://github.com/ionos-cloud/puppet-module/workflows/CI/badge.svg) 
[![Puppet Forge Version](https://img.shields.io/puppetforge/v/ionoscloud/ionoscloud)](https://forge.puppet.com/modules/ionoscloud/ionoscloud) 
[![Gitter](https://badges.gitter.im/ionos-cloud/sdk-general.png)](https://gitter.im/ionos-cloud/sdk-general)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=puppet-module&metric=alert_status)](https://sonarcloud.io/dashboard?id=puppet-module)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=puppet-module&metric=bugs)](https://sonarcloud.io/dashboard?id=puppet-module)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=puppet-module&metric=sqale_rating)](https://sonarcloud.io/dashboard?id=puppet-module)
[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=puppet-module&metric=reliability_rating)](https://sonarcloud.io/dashboard?id=puppet-module)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=puppet-module&metric=security_rating)](https://sonarcloud.io/dashboard?id=puppet-module)
[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=puppet-module&metric=vulnerabilities)](https://sonarcloud.io/dashboard?id=puppet-module)


![Alt text](.github/IONOS.CLOUD.BLU.svg?raw=true "Title")

---
### Warning: API Basic Authentication Deprecation Notice
Effective March 15, 2024, IONOS account holders using 2-Factor Authentication will no longer be able to utilize Basic Authentication for accessing our APIs, SDKs, and all related tools. Token creation and deletion via APIs and ionosCTL will also be restricted.

Affected users are required to switch to token-based authorization. These tokens will be accessible through our new Token Manager in the Data Center Designer, launching at the beginning of February 2024. More information can be found [here](https://docs.ionos.com/cloud/getting-started/basic-tutorials/deprecation-basic-authentication/basic-authentication-deprecation-faqs).

---

## Overview

The Ionoscloud Puppet module allows a multi-server cloud environment using Ionoscloud resources to be deployed automatically from a Puppet manifest file.

This module utilizes the IONOS Cloud [Cloud API](https://devops.ionoscloud.com/api/cloud/) via the [Ionoscloud Ruby SDK](https://github.com/ionos-cloud/sdk-ruby) to manage resources within a virtual data center. A Puppet manifest file can be used to describe the desired infrastructure configuration including networks, servers, CPU cores, memory, and their relationships as well as states. That infrastructure can then be easily and automatically deployed using Puppet.

## Getting Started

Before you begin you will need to have [signed-up for a Ionoscloud account](https://devops.ionoscloud.com/signup). The credentials you establish during sign-up will be used to authenticate against the Ionoscloud Cloud API.

### Requirements

* Puppet 6.x or greater
* Ruby 2.0 or greater
* Ionoscloud Ruby SDK (ionoscloud)
* Ionoscloud account

## Installation

There are multiple ways that Puppet and Ruby can be installed on an operating system (OS).

For users who already have a system with Puppet and Ruby installed, the following three easy steps should get the Ionoscloud Puppet module working. **Note:** You may need to prefix `sudo` to the commands in steps one and two.

1. Install the Ionoscloud Ruby SDK using `gem`.

        gem install ionoscloud

2. Install the module.

        puppet module install ionoscloud-ionoscloud

3. Set the environment variables for authentication.

        export IONOS_USERNAME="user@example.com"
        export IONOS_PASSWORD="secretpassword"

      or

        export IONOS_TOKEN="<token>"

**Note:** Be aware that setting the token makes the username and password be ignored, in order to use the username and password one must unset the token value.

A situation could arise in which you have installed a Puppet release that contains a bundled copy of Ruby, but you already had Ruby installed. In that case, you will want to be sure to specify the `gem` binary that comes with the bundled version of Ruby. This avoids a situation in which you inadvertently install the *ionoscloud* library but it is not available to the Ruby install that Puppet is actually using.

To demonstrate this on a CentOS 7 server, these steps could be followed.

**Note:** You may need to prefix `sudo` to the commands in steps one through three.

1. Install Puppet using the official Puppet Collection.

        rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm

        yum install puppet-agent

2. Install the Ionoscloud Ruby SDK using `gem`. **Note:** We are supplying the full path to the `gem` binary.

        /opt/puppetlabs/puppet/bin/gem install ionoscloud

3. Install the Puppet module. **Note:** We are supplying the full path to the `puppet` binary.

        /opt/puppetlabs/puppet/bin/puppet module install ionoscloud-ionoscloud

4. Set the environment variables for authentication.

        export IONOS_USERNAME="user@example.com"
        export IONOS_PASSWORD="secretpassword"

      or

        export IONOS_TOKEN="<token>"

## Usage

A Puppet manifest uses a domain specific language, or DSL. This language allows resources and their states to be declared. Puppet will then build the resources and set the states as described in the manifest. The following snippet describes a simple LAN resource.

    lan { 'public':
      ensure => present,
      public => true,
      datacenter_id => '2dbf0e6b-3430-46fd-befd-6d08acd96557'
    }

A LAN named `public` will have public Internet access enabled and will reside in the defined virtual data center.

**Note**: It is important that resource names be unique within the manifest. This includes both similar and different resource types. For example, a LAN resource named `public` will conflict with a server resource named `public`.

To provide a data center ID, you can create a data center within the module as follows:

    datacenter { 'myDataCenter' :
      ensure      => present,
      location    => 'de/fra',
      description => 'test data center'
    }

Afterwards, get the data center ID using the puppet resource command:

    puppet resource datacenter [myDataCenter]

which should return output similar to this:

    datacenter { 'myDataCenter':
      ensure      => 'present',
      description => 'test data center',
      id          => '4af72f13-221d-499d-88ea-48713173e12f',
      location    => 'de/fra',
    }

The returned *id* value of *4af72f13-221d-499d-88ea-48713173e12f* may be used elsewhere in our manifest to identify this virtual data center.

A data center name can be used instead. You may find this more convenient than using a data center ID. Please refer to the next section for an example.

If you have already created your data center, LAN and server resources, you may connect them with a new NIC resource using their names or IDs.

    $datacenter_name = 'testdc1'
    $server_name = 'worker1'
    $lan_name = 'public1'

    nic { 'testnic':
      datacenter_name   => $datacenter_name,
      server_name => $server_name,
      nat => false,
      dhcp => true,
      lan => $lan_name,
      ips => ['78.137.103.102', '78.137.103.103', '78.137.103.104'],
      firewall_active => true,
      firewall_rules => [
        {
          name => 'SSH',
          protocol => 'TCP',
          port_range_start => 22,
          port_range_end => 22
        }
      ]
    }

**Note**: Using the Ionoscloud Puppet module to manage your Ionoscloud resources ensures uniqueness of the managed instances. The Ionoscloud Cloud API allows the creation of multiple virtual data centers having the same name.

If you attempt to manage LAN and server resources using data center names, the module will throw an error when more than one virtual data center with the same name is detected. The same is true if you attempt to remove virtual data centers by non-unique names.

### Verification

Once you have composed a manifest, it is good to have Puppet validate the syntax. The Puppet accessory `parser` can check for syntax errors. To validate a manifest named `init.pp` run:

    puppet parser validate init.pp

If the manifest validates successfully, no output is returned. If there is an issue, you should get some output indicating what is invalid:

    Error: Could not parse for environment production: Syntax error at '}' at init.pp:8:2

That error message indicates we should take a look at a curly brace located on line 8 column 2 of `init.pp`.

To have puppet go ahead and apply the manifest run:

    puppet apply init.pp


### Testing

```text
$ rspec spec/unit/
```

Bugs & feature requests can be open on the repository issues: [https://github.com/ionos-cloud/puppet-module/issues/new/choose](https://github.com/ionos-cloud/puppet-module/issues/new/choose)
