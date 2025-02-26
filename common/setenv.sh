#!/bin/bash

# Make sure we can open sufficiently many files / allocate enough memory
ulimit -n 4096 && ulimit -m unlimited && ulimit -v unlimited && [ -z "$GPUTYPE" ] || [ "$GPUTYPE" == "CPU" ] || ulimit -l unlimited
if [ $? != 0 ]; then
  echo Error setting ulimits
  exit 1
fi

LIST_OF_DETECTORS="ITS,MFT,TPC,TOF,FT0,MID,EMC,PHS,CPV,ZDC,FDD,HMP,FV0,TRD,MCH,CTP"
# Detectors used in the workflow / enabled parameters
if [ -z "${WORKFLOW_DETECTORS+x}" ] || [ "0$WORKFLOW_DETECTORS" == "0ALL" ]; then export WORKFLOW_DETECTORS=$LIST_OF_DETECTORS; fi
if [ -z "${WORKFLOW_DETECTORS_QC+x}" ] || [ "0$WORKFLOW_DETECTORS_QC" == "0ALL" ]; then export WORKFLOW_DETECTORS_QC=$WORKFLOW_DETECTORS; fi
if [ -z "${WORKFLOW_DETECTORS_CALIB+x}" ] || [ "0$WORKFLOW_DETECTORS_CALIB" == "0ALL" ]; then export WORKFLOW_DETECTORS_CALIB=$WORKFLOW_DETECTORS; fi
if [ -z "${WORKFLOW_DETECTORS_RECO+x}" ] || [ "0$WORKFLOW_DETECTORS_RECO" == "0ALL" ]; then export WORKFLOW_DETECTORS_RECO=$WORKFLOW_DETECTORS; fi
if [ -z "${WORKFLOW_DETECTORS_CTF+x}" ] || [ "0$WORKFLOW_DETECTORS_CTF" == "0ALL" ]; then export WORKFLOW_DETECTORS_CTF=$WORKFLOW_DETECTORS; fi
if [ "0$WORKFLOW_DETECTORS_FLP_PROCESSING" == "0ALL" ]; then export WORKFLOW_DETECTORS_FLP_PROCESSING=$WORKFLOW_DETECTORS; fi
if [ -z "$WORKFLOW_PARAMETERS" ]; then export WORKFLOW_PARAMETERS=; fi

if [ -z "$NTIMEFRAMES" ];   then export NTIMEFRAMES=1; fi              # Number of time frames to process
if [ -z "$TFDELAY" ];       then export TFDELAY=100; fi                # Delay in seconds between publishing time frames
if [ -z "$GPUTYPE" ];       then export GPUTYPE=CPU; fi                # GPU Tracking backend to use, can be CPU / CUDA / HIP / OCL / OCL2
if [ -z "$DDSHMSIZE" ];     then export DDSHMSIZE=$(( 8 << 10 )); fi   # Size of shared memory for DD Input
if [ -z "$GPUMEMSIZE" ];    then export GPUMEMSIZE=$(( 24 << 30 )); fi # Size of allocated GPU memory (if GPUTYPE != CPU)
if [ -z "$HOSTMEMSIZE" ];   then export HOSTMEMSIZE=0; fi              # Size of allocated host memory for GPU reconstruction (0 = default)
if [ -z "$CREATECTFDICT" ]; then export CREATECTFDICT=0; fi            # Create CTF dictionary
if [ -z "$SAVECTF" ];       then export SAVECTF=0; fi                  # Save the CTF to a ROOT file
if [ -z "$SYNCMODE" ];      then export SYNCMODE=0; fi                 # Run only reconstruction steps of the synchronous reconstruction
if [ -z "$NUMAID" ];        then export NUMAID=0; fi                   # SHM segment id to use for shipping data as well as set of GPUs to use (use 0 / 1 for 2 NUMA domains)
if [ -z "$NUMAGPUIDS" ];    then export NUMAGPUIDS=0; fi               # NUMAID-aware GPU id selection
if [ -z "$CTFINPUT" ];      then export CTFINPUT=0; fi                 # Read input from CTF (incompatible to EXTINPUT=1)
if [ -z "$NHBPERTF" ];      then export NHBPERTF=128; fi               # Time frame length (in HBF)
if [ -z "$GLOBALDPLOPT" ];  then export GLOBALDPLOPT=; fi              # Global DPL workflow options appended at the end
if [ -z "$SEVERITY" ];      then export SEVERITY="info"; fi            # Log verbosity
if [ -z "$NORATELOG" ];     then export NORATELOG=1; fi                # Disable FairMQ Rate Logging
if [ -z "$INRAWCHANNAME" ]; then export INRAWCHANNAME=stfb-to-dpl; fi  # Raw channel name used to communicate with DataDistribution
if [ -z "$WORKFLOWMODE" ];  then export WORKFLOWMODE=run; fi           # Workflow mode, must be run, print, od dds
if [ -z "$FILEWORKDIR" ];   then export FILEWORKDIR=`pwd`; fi          # Override folder where to find grp, etc.
if [ -z "$EPNMODE" ];       then export EPNMODE=0; fi                  # Is this workflow supposed to run on EPN? Will enable InfoLogger / metrics / ...
if [ -z "$BEAMTYPE" ];      then export BEAMTYPE=PbPb; fi              # Beam type, must be PbPb, pp, pPb, cosmic, technical
if [ -z "$EDJSONS_DIR" ];   then export EDJSONS_DIR="jsons"; fi        # output directory for ED json files
if [ $EPNMODE == 0 ]; then
  if [ -z "$SHMSIZE" ];       then export SHMSIZE=$(( 8 << 30 )); fi   # Size of shared memory for messages
  if [ -z "$NGPUS" ];         then export NGPUS=1; fi                  # Number of GPUs to use, data distributed round-robin
  if [ -z "$EXTINPUT" ];      then export EXTINPUT=0; fi               # Receive input from raw FMQ channel instead of running o2-raw-file-reader
  if [ -z "$EPNPIPELINES" ];  then export EPNPIPELINES=0; fi           # Set default EPN pipeline multiplicities
  if [ -z "$SHMTHROW" ];      then export SHMTHROW=1; fi               # Throw exception when running out of SHM
  if [ -z "${WORKFLOW_DETECTORS_FLP_PROCESSING+x}" ]; then export WORKFLOW_DETECTORS_FLP_PROCESSING=""; fi # No FLP processing by default when we do not run the sync EPN workflow, e.g. full system test will also run full FLP processing
else # Defaults when running on the EPN
  if [ -z "$SHMSIZE" ];       then export SHMSIZE=$(( 256 << 30 )); fi
  if [ -z "$NGPUS" ];         then export NGPUS=4; fi
  if [ -z "$EXTINPUT" ];      then export EXTINPUT=1; fi
  if [ -z "$EPNPIPELINES" ];  then export EPNPIPELINES=1; fi
  if [ -z "$SHMTHROW" ];      then export SHMTHROW=1; fi               # NOTE: SHMTHROW SHOULD BE 0 FOR EPN, BUT IS =1 FOR TESTS DURING COMMISSIONING WHILE WE HAVE NO MEMORY MONITORING
  if [ -z "${WORKFLOW_DETECTORS_FLP_PROCESSING+x}" ]; then export WORKFLOW_DETECTORS_FLP_PROCESSING="TOF"; fi # Current default in sync processing is that FLP processing is only enabled for TOF
fi
# Some more options for running on the EPN
if [ -z "$INFOLOGGER_SEVERITY" ]; then export INFOLOGGER_SEVERITY="warning"; fi
if [ -z "$MULTIPLICITY_FACTOR_RAWDECODERS" ]; then export MULTIPLICITY_FACTOR_RAWDECODERS=1; fi
if [ -z "$MULTIPLICITY_FACTOR_CTFENCODERS" ]; then export MULTIPLICITY_FACTOR_CTFENCODERS=1; fi
if [ -z "$MULTIPLICITY_FACTOR_REST" ]; then export MULTIPLICITY_FACTOR_REST=1; fi

[ -z "${SEVERITY_TPC+x}" ] && SEVERITY_TPC="info" # overrides severity for the tpc workflow
[ -z "${DISABLE_MC+x}" ] && DISABLE_MC="--disable-mc"
[ -z "${DISABLE_ROOT_OUTPUT+x}" ] && DISABLE_ROOT_OUTPUT="--disable-root-output"

if [ $EXTINPUT == 1 ] && [ $CTFINPUT == 1 ]; then
  echo EXTINPUT and CTFINPUT are incompatible
  exit 1
fi
if [ $SAVECTF == 1 ] && [ $CTFINPUT == 1 ]; then
  echo SAVECTF and CTFINPUT are incompatible
  exit 1
fi
if [ $SYNCMODE == 1 ] && [ $CTFINPUT == 1 ]; then
  echo SYNCMODE and CTFINPUT are incompatible
  exit 1
fi
if [ $WORKFLOWMODE != "run" ] && [ $WORKFLOWMODE != "print" ] && [ $WORKFLOWMODE != "dds" ]; then
  echo Invalid workflow mode
  exit 1
fi

has_detector()
{
  [[ $WORKFLOW_DETECTORS =~ (^|,)"$1"(,|$) ]]
}

has_detector_qc()
{
  has_detector $1 && [[ $WORKFLOW_DETECTORS_QC =~ (^|,)"$1"(,|$) ]]
}

has_detector_calib()
{
  has_detector $1 && [[ $WORKFLOW_DETECTORS_CALIB =~ (^|,)"$1"(,|$) ]]
}

has_detector_reco()
{
  has_detector $1 && [[ $WORKFLOW_DETECTORS_RECO =~ (^|,)"$1"(,|$) ]]
}

has_detector_ctf()
{
  has_detector $1 && [[ $WORKFLOW_DETECTORS_CTF =~ (^|,)"$1"(,|$) ]]
}

has_detector_flp_processing()
{
  has_detector $1 && [[ $WORKFLOW_DETECTORS_FLP_PROCESSING =~ (^|,)"$1"(,|$) ]]
}

has_detector_matching()
{
  [[ $WORKFLOW_DETECTORS_MATCHING =~ (^|,)"ALL"(,|$) ]] || [[ $WORKFLOW_DETECTORS_MATCHING =~ (^|,)"$1"(,|$) ]]
}

workflow_has_parameter()
{
  [[ $WORKFLOW_PARAMETERS =~ (^|,)"$1"(,|$) ]]
}

_check_multiple()
{
  CHECKER=$1
  shift
  while true; do
    if [[ "0$1" == "0" ]]; then return 0; fi
    if ! $CHECKER $1; then return 1; fi
    shift
  done
}

has_detectors()
{
  _check_multiple has_detector $@
}

has_detectors_qc()
{
  _check_multiple has_detector_qc $@
}

has_detectors_calib()
{
  _check_multiple has_detector_calib $@
}

has_detectors_reco()
{
  _check_multiple has_detector_reco $@
}

has_detectors_ctf()
{
  _check_multiple has_detector_ctf $@
}

has_detectors_flp_processing()
{
  _check_multiple has_detector_flp_processing $@
}

workflow_has_parameters()
{
  _check_multiple workflow_has_parameter $@
}

add_comma_separated()
{
  if (( $# < 2 )); then
    echo "$# parameters received"
    echo "Function name: ${FUNCNAME} expects at least 2 parameters:"
    echo "it concatenates the string in 1st parameter by the following"
    echo "ones, forming comma-separated string. $# parameters received"
    exit 1
  fi

  for ((i = 2; i <= $#; i++ )); do
    if [[ -z ${!1} ]]; then
      eval $1+="${!i}"
    else
      eval $1+=",${!i}"
    fi
  done
}
