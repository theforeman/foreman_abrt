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
install the plugin itself, install ABRT plugin for your smart proxies and
configure your hosts to send the bug reports to their smart proxy.

Both plugins are available as RPMs in [Foremay YUM repositories](http://yum.theforeman.org/).

### Prerequisites

The plugins require both Foreman and smart-proxy to be version 1.6 or later.

The plugins have been tested on Fedora 19, RHEL 6 and RHEL 7. Due to old
version of `rubygem-ffi` the smart-proxy plugin does not work on RHEL 6 unless
you set the option `aggregate_reports` to `false` in
`/etc/foreman-proxy/settings.d/abrt.yml`.

To have hosts automatically send ureports to Foreman, you need to have ABRT
2.1.11 or higher installed on them. RHEL 7 and Fedora 19 and higher satisfy
this. ABRT in RHEL6 does not have ureport support, however you can use an
[unofficial build](https://copr.fedoraproject.org/coprs/jfilak/abrt/) if you
wish to test this feature.

### Installing the Foreman plugin

To install the Foreman plugin, follow the [plugin installation
instructions](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Plugin).

### Setting up smart proxies

Follow the [smart-proxy plugin installation
instructions](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Smart-Proxy_Plugin).
The plugin needs some configuration in order to work correctly.

- Edit `/etc/foreman-proxy/settings.yml` to configure the main Foreman host,
  which is normally not needed. Assuming Foreman runs on `f19-foreman.tld` the
  file should contain following:

  ```
  # URL of your foreman instance
  :foreman_url: https://f19-foreman.tld
  ```
  Please note that the `:foreman_url:` setting may be entirely missing in the
  file. In that case just add the line to the end of
  `/etc/foreman-proxy/settings.yml`.

- Ensure that `/etc/foreman-proxy/settings.d/abrt.yml` contains the following line:
  ```
  :enabled: true
  ```

- Cron is used to transfer the captured bug reports to Foreman in batches.
  Ensure that the `smart-proxy-abrt-send` command is run periodically. The
  provided RPM package contains a cron snippet that runs the command every 30
  minutes.

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
  # Verify the server certificate.
  SSLVerify = yes
  # This asks puppet config for the path to the ceritificates. you can
  # explicitly provide path by using /path/to/cert:/path/to/key on the
  # right hand side.
  SSLClientAuth = puppet
  ```

- Add the Puppet CA to the list of trusted certificate authorities. This is
  needed for verifying the validity of smart-proxy's certificate:

  ```
  ~# cp /var/lib/puppet/ssl/certs/ca.pem /etc/pki/ca-trust/source/anchors/
  ~# update-ca-trust
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
`/var/spool/foreman-proxy-abrt` on the smart-proxy host. The reports from
the smart-proxy are sent to the Foreman in batches every half an hour (by
default). This means that within half an hour you should be able to see the bug
report in the Foreman web interface. You can send the reports to Foreman
manually by running the `smart-proxy-abrt-send` command.

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

