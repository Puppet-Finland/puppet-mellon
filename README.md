# mellon

This is a Puppet module for managing Apache
[mod_auth_mellon](https://github.com/latchset/mod_auth_mellon), which "is an
authentication module for Apache. It authenticates the user against a SAML 2.0
IdP, and grants access to directories depending on attributes received from the
IdP."


## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with mellon](#setup)
    * [What mellon affects](#what-mellon-affects)
    * [Setup requirements](#setup-requirements)
1. [Usage - Configuration options and additional functionality](#usage)
    * [Getting the SP metadata from Keycloak](#getting-the-sp-metadata-from-keycloak)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This module allows creating one or more Apache2 Locations that are protected by
mod_auth_mellon. Each Location is completely isolated from each other, meaning
each will have its own IDP metadata, SP metadata, SP private key and SP certificate.

You might use this to, for example, protect Prometheus and Alertmanager running
on the same node while using different SAML settings (e.g. MellonCond) for
each. 

## Setup

### What mellon affects

This module creates the Location entries and installs the files required by
Mellon.

### Setup requirements

You need puppetlabs/apache, puppetlabs/concat and puppetlabs/stdlib to make use
of this module.

## Usage

And example of how configure Mellon to protect Prometheus and Alertmanager:

    ::mellon::config { 'alertmanager':
        subdir         => 'alertmanager',
        location       => '/alertmanager',
        idp_metadata   => $idp_metadata,
        sp_metadata    => $sp_metadata_alertmanager,
        sp_private_key => $sp_private_key_alertmanager,
        sp_cert        => $sp_cert_alertmanager,
        melloncond     => $melloncond_alertmanager,
      }
  
    ::mellon::config { 'prometheus':
      subdir         => 'prometheus',
      location       => '/prometheus',
      idp_metadata   => $idp_metadata,
      sp_metadata    => $sp_metadata_prometheus,
      sp_private_key => $sp_private_key_prometheus,
      sp_cert        => $sp_cert_prometheus,
      melloncond     => $melloncond_prometheus,
    }

The values (above) would generally come via lookups from Hiera. The IDP
metadata is always the same per-IDP. For details on the SP metadata see below.

The base Mellon setup is quite useless as-is. On top of it you want at least
one HTTPS VirtualHost with a suitable reverse proxy configuration. For example,
something like this, filling in the missing parameters as needed:

    $proxy_pass = [ { 'path' => '/alertmanager', 'url' => 'http://localhost:9093' },
                    { 'path' => '/prometheus',   'url' => 'http://localhost:9090/prometheus' }, ],
    
    $request_headers = ['set X-Forwarded-Proto "https"','set X-Forwarded-Port "443"']

    # https://github.com/Puppet-Finland/puppet-sslcert
    include ::sslcert
    
    ::sslcert::set { 'example.org':
      bundlefile => 'mybundle',
    }
    
    include ::apache::mod::headers
    include ::apache::mod::rewrite
    
    ::apache::vhost { $site_name:
      servername      => $site_name,
      port            => '80',
      docroot         => $doc_root,
      redirect_status => 'permanent',
      redirect_dest   => "https://${site_name}/",
    }
    
    ::apache::vhost { "${site_name}-ssl":
      servername      => $site_name,
      port            => '443',
      docroot         => $doc_root,
      proxy_pass      => $proxy_pass,
      request_headers => $request_headers,
      ssl             => true,
      ssl_cert        => $cert_path,
      ssl_key         => $key_path,
      ssl_chain       => $chain_path,
    }

### Getting the SP metadata from Keycloak

First create a Keycloak client for you mellon configuration. Then export the SP
metadata from the "Installation" tab. The metadata needs to be modified to
include the correct URLs - by default they're undefined. After that you can add
it to hiera(-eyaml).

## Limitations

Creation of VirtualHosts, reverse proxies and TLS/SSL is outside of
the scope of this module.

## Development

If find bugs or soom for improvement in this module please file a issue, or
better yet, issue a PR.
