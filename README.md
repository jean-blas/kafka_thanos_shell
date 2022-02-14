# kafka_thanos_shell

This simple collection of bash scripts run queries against our thanos
to retrive some kafka topics and display them.


usage : SHELL COMMAND PARAMS
    where:
      SHELL   = $0
      COMMAND = urp, do, ums, bs, olp, all, show
         all  : run all commands (e.g. SHELL all bkp15)
         show : display brokers and clusters only (e.g. SHELL show erding)
      PARAMS  = the command parameters, usually the cluster name or:
       erding : to check all erding clusters (e.g. SHELL urp erding)
        cloud : to check all PaaS clusters (e.g. SHELL urp cloud)
