# cpe_environment
Manage specific aspects of shell and zsh environments, including PATH and
environment variables


Also, a great resource to reference for macOS on this topic: https://scriptingosx.com/2019/06/moving-to-zsh-part-2-configuration-files/

## Examples

```
  node.default['cpe_environment']['manage'] = true
  node.default['cpe_environment']['config']['paths'] << '/my/path/bin'
  node.default['cpe_environment']['config']['vars']['MYVAR'] = 'something'
```

