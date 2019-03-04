cpe_ssh Cookbook
========================
Manages configs and known_hosts for ssh.


Attributes
----------
* node['cpe_ssh']
* node['cpe_ssh']['manage']
* node['cpe_ssh']['config']
* node['cpe_ssh']['known_hosts']


Usage
-----
By default, this cookbook will not manage ssh, its config or any known hosts. You may enable management of these things using by setting `manage` to `true`


An example config would be:

    node.default['cpe_ssh']['manage'] = true
    node.default['cpe_ssh']['config']['myhost'] = {
      'ForwardAgent' => 'yes',
      'HostName' => 'myhost.company.com'
    }
    node.default['cpe_ssh']['config']['github'] = {
      'User' => 'git',
      'HostName' => 'github.com',
      'IdentityFile' => '/path/to/id_rsa',
    }
    node.default['cpe_ssh']['known_hosts']['AAAA1289a98y891e89asdighuq8sdiu238934789yayubiasd789has2912d89yaskjhias=='] = {
      'hosts' => ['github.com', '192.168.1.194'],
      'type' => 'ssh-rsa',
      'comment' => 'Added 02/29/2019'
    }
    node.default['cpe_ssh']['known_hosts']['AAAA1289a98y891e89asdighuq8sdiu238934789yayubiasd789asdadasdasdadasdasddas=='] = {
      'hosts' => ['gitlab.com', '192.168.1.191'],
      'type' => 'ssh-rsa',
      'cert_authority' => true,
    }
    node.default['cpe_ssh']['known_hosts']['AAAA1289a98y891e89asdighuq8sdiu238934789yayubiasd789asdadasdasdadasdasddas=='] = {
      'hosts' => ['somemalicioussite.com', '192.168.1.132'],
      'type' => 'ssh-rsa',
      'revoked' => true,
    }

Note that it is possible to add either the @revoked or @cert-authority markers, key type, multiple hosts per key and a comment if desired.
