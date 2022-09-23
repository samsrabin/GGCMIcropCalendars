#!/bin/bash
set -e

# Bash script for calculating crop calendars for GGCMI phase3 (ISIMIP3b climate)

#############################################################################################
# Function-parsing code based on https://gist.github.com/neatshell/5283811
script="01_calc_crop_calendars.sh"

# Default values
wd="$PWD"
gcms_in="GFDL-ESM4 IPSL-CM6A-LR MPI-ESM1-2-HR MRI-ESM2-0 UKESM1-0-LL"
scens_in="ssp585 ssp370 ssp126 historical picontrol"
crops_in="Maize Rice Sorghum Soybean Spring_Wheat Winter_Wheat"

function usage {
echo -e "usage: $script [-w /home/minoli/crop_calendars_gitlab/r_package/cropCalendars/utils/ggcmi_ph3 -w PATH/TO/DIR/WITH/SCRIPT -g "GCM1 GCM2 ..." -s "SCEN1 SCEN2 ..." -c "CROP1 CROP2 ..."]\n"
}

function help {
usage
echo -e "OPTIONAL:"
echo -e "  -c/--crops: List of crops to include. Default: \"${crops_in}\""
echo -e "  -g/--gcms: List of gcms to include. Default: \"${gcms_in}\""
echo -e "  -s/--scens: List of scenarios to include. Default: \"${scens_in}\""
echo -e "  -w/--work-dir: Path to directory containing ${script}. Default is \$PWD."
}

# Args while-loop
while [ "$1" != "" ];
do
    case $1 in
        -c  | --crops)  shift
            crops_in="$1"
            ;;
        -g  | --gcms)  shift
            gcms_in="$1"
            ;;
        -s  | --scens)  shift
            scens_in="$1"
            ;;
        -w  | --work-dir )  shift
            wd="$1"
            ;;
        -h   | --help )        help
            exit
            ;;
        *)
            echo "$script: illegal option $1"
            help
            exit 1 # error
            ;;
    esac
    shift
done

#############################################################################################

# Convert input string lists to arrays
gcms=()
for g in ${gcms_in}; do
    gcms+=($g)
done
scens=()
for s in ${scens_in}; do
    scens+=($s)
done
crops=()
for c in ${crops_in}; do
    crops+=($c)
done

# sbatch settings
nnodes=1
ntasks=16

# MAIN
for gc in "${!gcms[@]}";do
  for sc in "${!scens[@]}";do
    for cr in "${!crops[@]}";do

      # Select years for each scenario
      if [ ${scens[sc]} = 'picontrol' ]
      then
        years=($(seq 1601 10 2091))
      elif [ ${scens[sc]} = 'historical' ]
      then
        years=($(seq 1851 10 2021))
      elif [[ ${scens[sc]} == 'ssp'* ]]
      then
        years=($(seq 2011 10 2091))
      else
        echo "Scenario ${scens[sc]} not recognized"
        exit 1
      fi

      for yy in "${!years[@]}";do

echo "GCM: ${gcms[gc]} --- SCENARIO: ${scens[sc]} --- CROP: ${crops[cr]} YEARS: ${years[yy]}"

# Submit job to SLURM - for arguments, see https://slurm.schedmd.com/sbatch.html
sbatch --nodes=${nnodes} --ntasks-per-node=${ntasks} --exclusive \
-t 01:00:00 -J crop_cal -A macmit --workdir="${wd}" \
R -f 01_calc_crop_calendars.R \
--args "${gcms[gc]}" "${scens[sc]}" "${crops[cr]}" "${years[yy]}" \
"${nnodes}" "${ntasks}"

      done # yy

# To avoid overloading the squeue
# sleep 1h

    done # cr
  done # sc
done # gc
