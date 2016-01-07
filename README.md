# dummy-ocf-ra
Dummy Pacemaker OCF RA

## how-to
Copy the OCF RA
```
# mkdir -p /usr/lib/ocf/resource.d/dummy
# wget https://raw.githubusercontent.com/bogdando/dummy-ocf-ra/master/dummy \
-O /usr/lib/ocf/resource.d/dummy/dummy
# chmod +x /usr/lib/ocf/resource.d/dummy/dummy
```

Create the dummy pacemaker resource (use either ``crm`` or ``pcs`` tool)
```
# pcs resource create --force --master p_dummy ocf:dummy:dummy \
  op monitor trace_ra=1 interval=30 timeout=60 \
  op monitor trace_ra=1 interval=27 role=Master timeout=60 \
  op monitor trace_ra=1 interval=103 role=Slave timeout=60 OCF_CHECK_LEVEL=30 \
  op start interval=0 timeout=360 \
  op stop interval=0 timeout=120 \
  op promote interval=0 timeout=120 \
  op demote interval=0 timeout=120 \
  op notify interval=0 timeout=180 \
  meta notify=true ordered=false interleave=false master-max=1 master-node-max=1

# crm configure primitive p_dummy ocf:dummy:dummy \
        op monitor trace_ra=1 interval=30 timeout=60 \
        op monitor trace_ra=1 interval=27 role=Master timeout=60 \
        op monitor trace_ra=1 interval=103 role=Slave timeout=60 OCF_CHECK_LEVEL=30 \
        op start interval=0 timeout=360 \
        op stop interval=0 timeout=120 \
        op promote interval=0 timeout=120 \
        op demote interval=0 timeout=120 \
        op notify interval=0 timeout=180 \
        meta migration-threshold=10 failure-timeout=30s resource-stickiness=100

# crm configure ms p_dummy-master p_dummy \
        meta notify=true ordered=false interleave=false master-max=1 master-node-max=1
```

Note, for asymmetrical "Opt-In" clusters also enable the resource for each node, like
```
# pcs constraint location p_dummy prefers `crm_node -n`=100
# crm configure location loc-`crm_node -n` p_dummy 100: `crm_node -n`
```

Check results
```
# pcs resource show p_dummy-master
 Master: p_dummy-master
  Meta Attrs: notify=true ordered=false interleave=false master-max=1 master-node-max=1
  Resource: p_dummy (class=ocf provider=dummy type=dummy)
   Meta Attrs: migration-threshold=10 failure-timeout=30s resource-stickiness=100
   Operations: monitor trace_ra=1 interval=30 timeout=60 (p_dummy-monitor-interval-30)
               monitor trace_ra=1 interval=27 role=Master timeout=60 (p_dummy-monitor-interval-27)
               monitor trace_ra=1 interval=103 role=Slave timeout=60 OCF_CHECK_LEVEL=30 (p_dummy-monitor-interval-103)
               start interval=0 timeout=360 (p_dummy-start-interval-0)
               stop interval=0 timeout=120 (p_dummy-stop-interval-0)
               promote interval=0 timeout=120 (p_dummy-promote-interval-0)
               demote interval=0 timeout=120 (p_dummy-demote-interval-0)
               notify interval=0 timeout=180 (p_dummy-notify-interval-0)

# crm configure show p_dummy
primitive p_dummy ocf:dummy:dummy \
        op trace_ra=1 monitor interval=30 timeout=60 \
        op trace_ra=1 monitor interval=27 role=Master timeout=60 \
        op trace_ra=1 monitor interval=103 role=Slave timeout=60 OCF_CHECK_LEVEL=30 \
        op start interval=0 timeout=360 \
        op stop interval=0 timeout=120 \
        op promote interval=0 timeout=120 \
        op demote interval=0 timeout=120 \
        op notify interval=0 timeout=180 \
        meta migration-threshold=10 failure-timeout=30s resource-stickiness=100
# crm configure show p_dummy-master
ms p_dummy-master p_dummy \
        meta notify=true ordered=false interleave=false master-max=1 master-node-max=1
```

Note that the ``resource-agents>=3.9.5`` package is required in order to use the
``trace_ra=1`` setting. Traces will be stored at the
``/var/lib/heartbeat/trace_ra/dummy`` dir.

Also note, a shell fork bomb is a known issue for the resource-agents<=3.9.5,
see https://github.com/ClusterLabs/resource-agents/issues/734.

## dummy plays
By default, for each action or notify the dummy RA will return the
``OCF_SUCCESS`` or the 3rd parameter given for the ``dummy_pop()`` call
(see the dummy OCF script inline).

You can controll that it shall return though. To do that, create a file like
``/tmp/dummy_plays_monitor`` or ``/tmp/dummy_plays_post_promote`` containing a
scripted sequence (placed in reverse order) of return codes for the action
specified in the file name, for example:
```
$ cat /tmp/dummy_plays_monitor
NOT_RUNNING
NOT_RUNNING
ERROR
$ cat /tmp/dummy_plays_post_promote
RUNNING_MASTER
```
This will force the dummy RA to play dead and return ``OCF_GENERIC_ERROR``
then ``OCF_NOT_RUNNING`` twice for the next monitor actions (each return
code will be popped from the file from down to top). While the nearest post
promote notification will return ``OCF_RUNNING_MASTER`` once as well.
Note that actions to play are not serialized and will run independently
for each action or notification.

Supported actions to play are:
``ERROR, FAILED_MASTER, RUNNING_MASTER, SUCCESS, NOT_RUNNING``

## dummy master wannabe
If you wish some instance of the dummy to became a master, create
the ``/tmp/dummy_master_wannabe`` file.
