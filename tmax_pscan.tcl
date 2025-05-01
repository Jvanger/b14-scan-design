# TetraMAX ATPG script for b14 (Partial Scan)

# Read the netlist and standard cell library
read_netlist b14_pscan.vg
read_netlist /cae/apps/data/saed32_edk-2023/lib/stdcell_lvt/verilog/saed32nm_lvt.v

# Build the design model
run_build_model b14

# Run DRC check with STIL file
run_drc b14_pscan.stil

# Add all stuck-at faults
add_faults -all

# Configure ATPG for partial scan - increase effort for better coverage
set_atpg -abort_limit 300
set_atpg -merge high
set_atpg -full_seq_atpg
set_atpg -patterns 3000
set_atpg -fill adjacent

# Run ATPG with more effort to achieve higher test coverage
run_atpg -auto

# Delete existing pattern file if it exists
catch {file delete b14_pattern_pscan.v}

# Write patterns in binary format as required
write_patterns b14_pattern_pscan.v -format binary

# Generate the fault and pattern reports
report_faults -all > b14_pscan_fault_report.txt
report_patterns -all > b14_pscan_pattern_report.txt