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
timesteps_per_day=1

function usage {
echo -e "usage: $script [-w /home/minoli/crop_calendars_gitlab/r_package/cropCalendars/utils/ggcmi_ph3 -w PATH/TO/DIR/WITH/SCRIPT -g "GCM1 GCM2 ..." -s "SCEN1 SCEN2 ..." -c "CROP1 CROP2 ..." -y "1850 1860 ..."]\n"
}

function help {
usage
echo -e "OPTIONAL:"
echo -e "  -c/--crops: List of crops to include. Default: \"${crops_in}\""
echo -e "  -g/--gcms: List of gcms to include. Default: \"${gcms_in}\""
echo -e "  -s/--scens: List of scenarios to include. Default: \"${scens_in}\""
echo -e "  --timesteps-per-day: Number of timesteps per day. Default: ${timesteps_per_day}."
echo -e "  -w/--work-dir: Path to directory containing ${script}. Default is \$PWD."
echo -e "  -y/--years: List of years (year after end of 30-year averaging period) to process. If specified, will skip if provided year is not in scenario's period. Default is every 10 years in each scenario's period."
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
        --timesteps-per-day)  shift
            timesteps_per_day="$1"
            ;;
        -w  | --work-dir )  shift
            wd="$1"
            ;;
        -y  | --years)  shift
            years_in="$1"
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
if [[ "${years_in}" != "" ]]; then
  years=()
  for y in ${years_in}; do
      years+=($y)
  done
fi

# sbatch settings
nnodes=1
ntasks=16

# MAIN
for gc in "${!gcms[@]}";do
  for sc in "${!scens[@]}";do

    # Select years for each scenario
    if [ ${scens[sc]} = 'picontrol' ]; then
      scen_y1=1601
      scen_yN=2091
    elif [ ${scens[sc]} = 'historical' ]; then
      scen_y1=1851
      scen_yN=2091
    elif [[ ${scens[sc]} == 'ssp'* ]]; then
      scen_y1=2011
      scen_yN=2091
    else
      echo "Scenario ${scens[sc]} not recognized"
      exit 1
    fi

    # If -y/--years not specified, generate year list here.
    if [[ "${years}" == "" ]]; then
      years=($(seq ${scen_y1} 10 ${scen_yN}))
    fi

    for yy in "${!years[@]}";do

      # Skip any years not in this scenario.
      if [[ ${years[yy]} -lt ${scen_y1} || ${years[yy]} -gt ${scen_yN} ]]; then
        continue
      fi

      for cr in "${!crops[@]}";do

echo "GCM: ${gcms[gc]} --- SCENARIO: ${scens[sc]} --- YEAR: ${years[yy]} CROP: ${crops[cr]}"

# Submit job to SLURM - for arguments, see https://slurm.schedmd.com/sbatch.html
sbatch --nodes=${nnodes} --ntasks-per-node=${ntasks} --exclusive \
-t 01:00:00 -J crop_cal -A macmit --workdir="${wd}" \
R -f 01_calc_crop_calendars.R \
--args "${gcms[gc]}" "${scens[sc]}" "${crops[cr]}" "${years[yy]}" \
"${nnodes}" "${ntasks}" $PWD $PWD $HOME $HOME ${timesteps_per_day}

      done # cr

# To avoid overloading the squeue
# sleep 1h

    done # yy
  done # sc
done # gc
