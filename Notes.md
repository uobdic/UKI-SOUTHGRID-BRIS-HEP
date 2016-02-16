# General notes

## SELINUX interferes with hiera
Hiera seems to have access to node-level facts, however, if SELINUX is enabled custom facts will not be availabe: https://ask.puppetlabs.com/question/24091/hiera-dynamic-lookup-with-external-facts/

## Puppet custom mount points
Puppet custom mount points are defined in `/etc/puppetlabs/puppet/fileserver.conf`

```
[secrets]
    path /etc/puppetlabs/secrets/files
    allow *
```
Any change to this file will need a restart of the puppet service (`systemctl restart puppetserver.service`). **IMPORTANT**: Any files in the new mount point need to be readable by the `puppet` user.

Also, it is considered good practice to saveguard the files in ``/etc/puppetlabs/puppet/auth.conf`:
```
path ~ ^/puppet/v3/file_(metadata|content)/secrets/
auth yes
allow *.example.org, *.example2.org
```
where regex is allowed.
