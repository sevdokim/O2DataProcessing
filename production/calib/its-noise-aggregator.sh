#!/bin/bash

source common/setenv.sh

# ---------------------------------------------------------------------------------------------------------------------
# Set general arguments
ARGS_ALL="--session default --severity $SEVERITY --shm-segment-size $SHMSIZE $ARGS_ALL_EXTRA"
ARGS_ALL+=" --infologger-severity $INFOLOGGER_SEVERITY"
ARGS_ALL+=" --monitoring-backend influxdb-unix:///tmp/telegraf.sock --resources-monitoring 60"
if [ $SHMTHROW == 0 ]; then
  ARGS_ALL+=" --shm-throw-bad-alloc 0"
fi
if [ $NORATELOG == 1 ]; then
  ARGS_ALL+=" --fairmq-rate-logging 0"
fi
ARGS_ALL_CONFIG="NameConf.mDirGRP=$FILEWORKDIR;NameConf.mDirGeom=$FILEWORKDIR;NameConf.mDirCollContext=$FILEWORKDIR;NameConf.mDirMatLUT=$FILEWORKDIR;keyval.input_dir=$FILEWORKDIR;keyval.output_dir=/dev/null;$ALL_EXTRA_CONFIG"

PROXY_INSPEC="A:ITS/COMPCLUSTERS/0;B:ITS/PATTERNS/0;C:ITS/CLUSTERSROF/0;eos:***/INFORMATION"

WORKFLOW="o2-dpl-raw-proxy $ARGS_ALL --proxy-name its-noise-input-proxy --dataspec \"$PROXY_INSPEC\" --network-interface ib0 --channel-config \"name=its-noise-calib,method=bind,type=pull,rateLogging=0,transport=zeromq\" | "
WORKFLOW+="o2-calibration-its-calib-workflow $ARGS_ALL --configKeyValues \"$ARGS_ALL_CONFIG\" --prob-threshold 1e-5 | "
WORKFLOW+="o2-calibration-ccdb-populator-workflow $ARGS_ALL --configKeyValues \"$ARGS_ALL_CONFIG\" --ccdb-path=\"http://ccdb-test.cern.ch:8080\" | "
WORKFLOW+="o2-dpl-run $ARGS_ALL $GLOBALDPLOPT"

if [ $WORKFLOWMODE == "print" ]; then
  echo Workflow command:
  echo $WORKFLOW | sed "s/| */|\n/g"
else
  # Execute the command we have assembled
  WORKFLOW+=" --$WORKFLOWMODE"
  eval $WORKFLOW
fi
