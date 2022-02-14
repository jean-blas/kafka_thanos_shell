# kafka_thanos_shell

This simple collection of bash scripts run queries against our thanos
to retrive some kafka topics and display them.


### usage : <i>SHELL COMMAND PARAMS</i>

where:

* SHELL   = $0
* COMMAND = urp, do, ums, bs, olp, all, show

    * <tt>urp</tt> : under replication partitions
    * <tt>do</tt> : disk occupancy
    * <tt>olp</tt> : offline partitions
    * <tt>ums</tt> : under min in sync replicas partitions
    * <tt>bs </tt> : broker state
    * <tt>all</tt> : run all commands (e.g. <i>SHELL all bkp15</i>)
    * <tt>show</tt> : display brokers and clusters only (e.g. <i>SHELL show erding</i>)
<p>

* PARAMS  = the command parameters, usually the cluster name or:

    * <tt>erding</tt> : to check all erding clusters (e.g. <i>SHELL urp erding</i>)
    * <tt>cloud</tt> : to check all PaaS clusters (e.g. <i>SHELL urp cloud</i>)
