README (08.03.2021)
------
Author: Sara Minoli
Affiliation: Potsdam Institute for Climate Impact Research, Germany
Contact: sara.minoli@pik-potsdam.de

This folder includes R-coded scripts for computing sowing and harvest dates following the approaches from Waha et al. (2012) and Minoli et al. (2019).

Running the code:

1) Create a configuration file: `./compute_sdate_hdate/configuration/configuration_myproject.R`
- Define I/O paths (make sure automatically created directories are correct)
- Define crops to simulate
- Grid coordinates (by default LPJmL grid.bin is used, which is converted into a dataframe)

2) Prepare monthly climate files: `./preprocessing/prepare_montly_climate.R` and `./preprocessing/prepare_montly_climate.sh`
- Compute long-term monthly average of temperature (degC), precipitation (mm), potential evapotranspiration (mm), P/PET ratio (frac), stored in a datatable with header: lon, lat, month, tas, pr, pet, ppet
- pass arguments and submit job via bash script

3) Set up main script: `./compute_sdate_hdate/main_myproject.R`
- Choose if On Cluster TRUE/FALSE
- Define Working directory

4) `./compute_sdate_hdate/main_myproject.sh`
- Define loops for running scenarios and crops in batch
- To run it type: `bash main_myproject.sh` (note: module purge might be needed beforehand, if need to open old Rdata files)

Postprocessing:
- Winter-wheat suitable area can be derived by removing pixels with sowing_month==0 which indicates that the deafault sowing month was chosen
- A script for merging spring and winter wheat is provided: ./postprocessing/merge_winter_spring_wheat.R

Parameters:
- Adjust crop parameters in crop_parameters.txt (default are taken from Waha 2012 & Minoli 2019)

Debugging:
- ./compute_sdate_hdate/src/debugging.R can help troubleshooting
