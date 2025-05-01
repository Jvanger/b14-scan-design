# Synthesis script for Partial Scan Design of b14
# For ECE 553 Project

# Set up search paths and libraries
set search_path [list . /cae/apps/data/saed32_edk-2023/lib/stdcell_lvt/db_nldm]
set target_library "saed32lvt_tt1p05v25c.db"
set link_library "* $target_library"
set symbol_library "saed32lvt.sdb"

# Create reports directory if it doesn't exist
file mkdir reports

# Read the design
analyze -format vhdl b14.vhd
elaborate b14

# Set constraints
create_clock -name "clock" -period 10 [get_ports clock]
set_clock_transition 0.1 [get_clocks clock]
set_input_delay 0.5 -clock clock [remove_from_collection [all_inputs] [get_ports clock]]
set_output_delay 0.5 -clock clock [all_outputs]
set_driving_cell -lib_cell INVX1 [remove_from_collection [all_inputs] [get_ports clock]]
set_load 0.1 [all_outputs]

# Initial compile to check design
compile

# DFT Configuration - Using the correct signal names and polarities
set_scan_configuration -style multiplexed_flip_flop
set test_default_period 100
set_dft_signal -view existing_dft -type ScanClock -timing {45 55} -port clock
set_dft_signal -view existing_dft -type Reset -active_state 1 -port reset

# Create scan ports
create_port -direction in SERIAL_IN1
create_port -direction in SERIAL_IN2
create_port -direction in SCAN_EN
create_port -direction out SERIAL_OUT1
create_port -direction out SERIAL_OUT2

# Configure scan signals
set_dft_signal -view spec -type ScanDataIn -port SERIAL_IN1
set_dft_signal -view spec -type ScanDataIn -port SERIAL_IN2
set_dft_signal -view spec -type ScanDataOut -port SERIAL_OUT1
set_dft_signal -view spec -type ScanDataOut -port SERIAL_OUT2
set_dft_signal -view spec -type ScanEnable -port SCAN_EN -active_state 1

create_test_protocol

# Run compile with test for DFT rule checking but don't insert scan yet
compile -scan

# Preview and check DFT rules
preview_dft
dft_drc

# Get a list of all flip-flops in the design
set all_ff [all_registers -edge_triggered]
if {[sizeof_collection $all_ff] == 0} {
    puts "Warning: No scan cells found using all_registers -edge_triggered"
    set all_ff [get_cells -hierarchical -filter "is_sequential==true"]
}
set num_flops [sizeof_collection $all_ff]
puts "Total number of flip-flops: $num_flops"

# Set K value for partial scan (try 65% of flip-flops)
set K [expr int($num_flops * 0.4)]
puts "Using K = $K flip-flops for scan insertion"

# Get a list of all flip-flops
set all_ff_list {}
foreach_in_collection ff $all_ff {
    lappend all_ff_list [get_object_name $ff]
}

# Use a simpler approach - select first K flip-flops
set scan_ff [lrange $all_ff_list 0 [expr $K - 1]]
set exclude_ff [lrange $all_ff_list $K end]

# Only exclude if we have cells to exclude
if {[llength $exclude_ff] > 0} {
    puts "Excluding [llength $exclude_ff] flip-flops from scan"
    set_scan_configuration -exclude [get_cells $exclude_ff]
}

# Set up 2 scan chains
set_scan_configuration -chain_count 2
set_scan_configuration -clock_mixing no_mix

# Define the scan chains
set_scan_path chain1 -scan_data_in SERIAL_IN1 -scan_data_out SERIAL_OUT1
set_scan_path chain2 -scan_data_in SERIAL_IN2 -scan_data_out SERIAL_OUT2

# Insert scan
insert_dft
set_scan_state scan_existing

# Generate reports
report_area > reports/pscan_area.rpt
report_timing > reports/pscan_timing.rpt
report_power > reports/pscan_power.rpt
report_scan_path -view existing_dft -chain all > reports/pscan_chain.rep
report_scan_path -view existing_dft -cell all > reports/pscan_cell.rep

# Write out design files for ATPG
change_names -hierarchy -rule verilog
write -format verilog -hierarchy -out b14_pscan.vg
write -format ddc -hierarchy -output b14_pscan.ddc
write_scan_def -output b14_pscan.def
set test_stil_netlist_format verilog
write_test_protocol -output b14_pscan.stil

