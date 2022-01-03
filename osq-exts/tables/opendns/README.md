# OpenDNS OSQuery Extension

This table reads information from debug.opendns.com for diagnostic information.

macOS, Windows, and Linux are supported.

```
osquery> select * from opendns;
+--------------+-------------------------------------------------------+
| key          | value                                                 |
+--------------+-------------------------------------------------------+
| server       | m1234.abcd                                            |
| device       | 1234567890123456                                      |
| organization | id 123456                                             |
| alt          | uid 123412341234123412341234123412341                 |
| remoteip     | 192.168.0.1                                           |
| flags        | 00000000 0 00 000000000000000000000000000000000000000 |
| originid     | 123456789                                             |
| orgid        | 123456                                                |
| orgflags     | 12345678                                              |
| actype       | X                                                     |
| bundle       | 1234567                                               |
| source       | 1.2.3.4:51280                                         |
| dnscrypt     | enabled (0000000000000000)                            |
+--------------+-------------------------------------------------------+
osquery> select * from opendns where key='server';
+--------+---------+
| key    | value   |
+--------+---------+
| server | m12.345 |
+--------+---------+
osquery>
```
