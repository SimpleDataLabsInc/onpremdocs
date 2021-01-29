## Standalone Testing for livy connectivity

Sample command:

```bash
java -Dsun.security.krb5.debug=true -jar target/scala-2.12/livy-kerberos-standalone-assembly-0.1.jar -l http://livy -p prophecy_principal -k /path/to/keytab 
```
(the jar file is present in this repo)

Available Arguments:

```bash
❯ java -Dsun.security.krb5.debug=true -jar target/scala-2.12/livy-kerberos-standalone-assembly-0.1.jar
Error: Missing option --principal
Error: Missing option --keytab
Error: Missing option --livy
scopt 4.x
Usage: kerberos-test [options]

  -p, --principal <value>  principal of the prophecy user
  -k, --keytab <file>      keytab file
  -l, --livy <value>       livy url
  -x, --proxy-user <value>
                           proxy-user to pass to livy
  --driver-cores <value>   Driver Cores
  --driver-memory <value>  Driver Memory
  --executor-cores <value>
                           Executor Cores
  --executor-memory <value>
                           Executor Memory
  -n, --num-executors <value>
                           Number of Executors
  -q, --queue <value>      Yarn Queue for livy
  -w, --wait-time <value>  Wait time for statement finish
~/Documents/GitHub/livy-kerberos-standalone main* ❯
```

The sample command provided above tries to connect to livy as prophecy user. If there are issues with yarn-queues, or executor sizes etc you can provide these values and try.

Once this starts working, the next thing to try would be impersonation. For that, you should supply the `-x` argument like `-x <proxy-user>`. 
The format of proxy-user needs to be confirmed with Jagadeesh. It should be the user id with which you would login to livy. In my experience, it's generally `a` for a user with email id `a@company.com`; but good to confirm first. 


