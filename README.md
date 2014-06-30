# ForemanAbrt

This plugin allows your Foreman instance to receive bug reports generated on
your hosts by [ABRT](https://github.com/abrt/abrt) (Automatic Bug Reporting
Tool). These reports can be inspected and eventually forwarded to the ABRT
server.

## Overview

1. Whenever a bug is caught by ABRT on the managed host, it is sent to the Smart
   proxy instead of being sent directly to the ABRT server.
2. The Smart proxy receives the report and stores it to the disk. Stored
   reports are then sent to Foreman every 30 minutes (by means of cron job).
   The proxy may optionally:
   - Forward the report to an ABRT server immediately after being received.
     Server's response is discarded.
   - Aggregate stored reports prior to sending them to the Foreman. Only one
     instance of set of similar reports from a host is sent, together with
     number of the reports in the set.
3. Foreman receives the aggregated report and stores it to the database. The
   reports can be inspected and forwarded to the ABRT server. If the server
   responds with additional information about the report, such as links to bug
   trackers or suggested solutions, it is displayed alongside the report.

```

 +--------------+  ureport   +-------------+  aggregated ureports   +---------+
 | Managed host | ---------> | Smart proxy | ---------------------> | Foreman |
 +--------------+            +-------------+                        +---------+
                                    :                                  :  ^
                                    :                          ureport :  :
                                    :                                  :  : server response
                                    :                                  V  :
                                    :          ureport            +-------------+
                                    + - - - - - - - - - - - - - ->| ABRT server |
                                                                  +-------------+

```

## Installation

To be able to see ABRT bug reports in your Foreman instance, you need to
install the plugin itself, set up the ABRT support in your smart proxies and
configure your hosts to send the bug reports to their smart proxy.

### Installing the Foreman plugin

To install the Foreman plugin, follow the [plugin installation
instructions](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Plugin).

### Setting up smart proxies

Currently you have to install modified version of smart-proxy from [git
repository](https://github.com/mmilata/smart-proxy/tree/foreman_abrt_plugin)
(note the `foreman_abrt_plugin` branch). Once smart-proxy [supports
plugins](https://github.com/theforeman/smart-proxy/pull/150), the ABRT support
code will be rewritten as a plugin.

- Clone the git repository on your smart-proxy host and check out the
  `foreman_abrt_plugin` branch. XXX satyr gem

  ```
  ~$ git clone https://github.com/mmilata/smart-proxy.git
  ~$ cd smart-proxy
  ~/smart-proxy$ git checkout foreman_abrt_plugin
  ```

- If you want to use the report aggregation (reports are grouped on the proxy
  and the same reports are sent only once), you have to install the satyr ruby
  gem:

  ```
  ~# yum install satyr
  ~# gem install satyr
  ```

- Use tito to build the smart-proxy package, then install it. Replace `.f19`
  with the correct tag for your distribution.

  ```
  ~/smart-proxy$ tito tag --keep-version --no-auto-changelog
  ~/smart-proxy$ tito build --offline --test --rpm --dist=.f19 --output=build/
  ~/smart-proxy# yum install build/noarch/*.rpm
  ```

- Edit `/etc/foreman-proxy/settings.yml` to configure the proxy. Assuming the
  proxy runs on `f19-smartproxy.tld` and the Foreman instance on
  `f19-foreman.tld`, the file should contain these lines:

  ```
  # URL of your foreman instance
  :foreman_url: https://f19-foreman.tld
  # certificates used for communication with foreman
  :foreman_ssl_ca: /var/lib/puppet/ssl/certs/ca.pem
  :foreman_ssl_cert: /var/lib/puppet/ssl/certs/f19-smartproxy.tld.pem
  :foreman_ssl_key: /var/lib/puppet/ssl/private_keys/f19-smartproxy.tld.pem
  # enable ABRT proxy
  :abrtproxy: true
  # to enable report aggregation, uncomment following line:
  #:abrtproxy_aggregate_reports: true
  ```

- Start the smart-proxy.

  ```
  ~# systemctl start foreman-proxy
  ```

### Configuring hosts to send bug reports to Foreman

- Make sure that ABRT is installed and running.
  ```
  ~# yum install abrt-cli
  ~# systemctl start abrtd
  ~# systemctl start abrt-ccpp
  ```

- Configure ABRT reporting destination -
  `/etc/libreport/plugins/ureport.conf` should contain following:

  ```
  # URL of your foreman-proxy, with /abrt path.
  URL = https://f19-smartproxy.tld:8443/abrt
  # Do not verify server certificate.
  SSLVerify = no
  # This asks puppet config for the path to the ceritificates. you can
  # explicitly provide path by using /path/to/cert:/path/to/key on the
  # right hand side.
  SSLClientAuth = puppet
  ```

- Enable autoreporting by running the following command:

  ```
  ~# abrt-auto-reporting enabled
  ```

### Verifying that the setup works

You can verify your setup by crashing something on your managed host. We have a
set of utilities in the Fedora repository especially for this purpose:

```
~# yum -y install will-crash
~$ will_segfault
Will segfault.
Segmentation fault (core dumped)
```

After a couple of seconds, a new file should appear in
`/var/spool/foreman-proxy/abrt-send` on the smart-proxy host. The reports from
the smart-proxy are sent to the Foreman in batches every half an hour (by
default). This means that within half an hour you should be able to see the bug
report in the Foreman web interface.

## Usage

The list of received bug reports can be accessed by clicking on *Bug reports*
link in the *Monitor* menu. To see detailed information for a report, click on
its reported date.

List of bug reports coming from a particular host is also displayed on the page
with the details about the host in the *Bug reports* tab on the left.

### Forwarding the report to the ABRT server

On the bug report details page you can forward the bug report to an actual
ABRT server by clicking the *Forward report* button. The ABRT server may
respond with some information it knows about the bug, such as the list of URLs
related to the bug (e.g. Bugzilla link) and list of possible solutions to the
problem that caused the bug to occur.

The forwarding functionality may have to be configured in *Abrt* tab of the
configuration screen (*Administer*->*Settings*).

## TODO

- Graph with number of reports vs. time on the dashboard.
- Figure out how to import the Puppet CA cert on managed hosts to the system
  certificates so that the reporter-ureport doesn't have to skip server
  certificate validation.
- Forwarding reports on the proxy - drop it altogether, or forward the server
  response to the client?
- Use puppet to configure managed hosts to send ureports to Foreman.

## Copyright

Copyright (c) 2014 Red Hat

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

