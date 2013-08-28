Hiera data mapper backend

# motivation

The current behavior of the Puppet Data Bindings create a 1-1 mapping between class parameter
and hiera keys.

ie:

    class one($verbose) {...}

    class two($verbose) {...}

For the above example, the user would have to specify verbose twice in their hiera-store,
even if it always points to the same value.

    #common.yaml
    one::verbose: true
    two::verbose: true

The problem with this type of hiera file is that it puts the burden of knowing
how class parameters map to values in hiera to the end user. It also results in
a ton of duplicate configuration and does not really express end user configuration.

Another way to accomplish the same behavior is to wrap classes one and two with
another class that knows how to direct data points to values:

    class composer(hiera('verbose', false)) {
      class { 'one':
        verbose => $verbose
      }
      class { 'two':
        verbose => $verbose
      }
    }

This method is what I had tended towards in the past. It requires that a ton of code
be created for large complex configurations.

The above example was chosen for simplicity. A more practical example may be the ip
address of a host that multiple class interfaces require as a part of their configuration.

# hiera data mapper

The data mapper is a hiera based implementation of the above mentioned data-mapping.

## configuring the data mapper

The data mapping backend requires the following thigns are configured
in your hiera.yaml

### backend

Select the data_mapper backend

    :backends:
      - data_mapper


### hierarchy

At the moment, the data backend uses the same hierarchy as hiera to
resolve it's data mappings.

    :hierarchy:
      # this hierarchy is just used for
      - "%{hostname}"
      - "%{scenario}"
      - "%{role}"
      - common

### yaml

The data mapper backend still reiles on yaml for its actual lookups so
the yaml backend still needs to be configured with its datadir.

    :yaml:
       :datadir: /Users/danbode/dev/hiera_data_mappings/hiera_data/

### data_mapper

The data_mapper section contains the key datadir which tells hiera
what directory to look in to find data mappings.

    :data_mapper:
       # this should be contained in a module
       :datadir: /Users/danbode/dev/hiera_data_mappings/data_mappings

This maps to files from the hierarchy (just like regular hiera).

## Usage example

Imagine that N number of services all need to utilize the same service
for authentication:

    class auth_service($bind_address) {...}
    class service_one($auth_host) {...}
    class service_two($auth_host) {...}
    class service_three($auth_host) {...}

* Decide that all of this data actually needs to be set to the same value.

* Create a data mapping hierarchy:

in the file: /etc/hiera/data_mappings/common.yaml

Add the following configuration:

    auth_host:
      service::one::auth_host
      service::two::auth_host
      service::three::auth_host
      auth_service::bind_address

This configuration indicates that all of these values will be mapped to the hiera
value of auth_host.

* Add auth_host to regular hiera yaml

in the file: /etc/hiera/hiera_data/common.yaml

     auth_host: 10.0.0.4
