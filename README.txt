ECE 553 Project - Partial Scan Design


Group Members
Jonathan Fang (Individually done) 

 Files Included
1. b14_pscan.vg - Generated netlist with partial scan (40% of flip-flops)
2. b14_pscan.stil - Generated STIL file for DRC
3. b14_pattern_pscan.v - Test vectors in binary format
4. synthesis_pscan.tcl - Script for partial scan synthesis with Design Vision
5. tmax_pscan.tcl - Script for running TetraMax
6. [fang].pdf - Project report with design exploration and analysis

 How to Run the Scripts

Directory Setup
All scripts should be run from a directory containing the original b14.vhd file.
You can copy this file using: cp ~adavoodi/setup/b14.vhd .

Running Synthesis Script

design_vision -no_gui -f synthesis_pscan.tcl
OR
/cae/apps/bin/design_vision


This will:
1. Analyze and elaborate the b14.vhd design
2. Create clock and timing constraints
3. Configure scan insertion for 40% of flip-flops (86 FFs)
4. Set up 2 balanced scan chains
5. Insert scan and generate reports
6. Write out b14_pscan.vg, b14_pscan.stil, and b14_pscan.def files

Running ATPG Script

tmax -no_gui -f tmax_pscan.tcl
OR
/cae/apps/bin/oldver/tmax

This will:
1. Read the netlist and scan information
2. Configure ATPG settings for optimal pattern generation
3. Generate test patterns with high compression
4. Write out test coverage report and b14_pattern_pscan.v


Process for Exploring Different K Values
To reproduce the design exploration with different K values:

Modify the percentage value in the synthesis_pscan.tcl script:
tcl Original line (for K=86, 40% of flip-flops)
set K [expr int($num_flops * 0.4)]

 Change to other percentages as needed:
 50% -> set K [expr int($num_flops * 0.5)]
 60% -> set K [expr int($num_flops * 0.6)]
 etc.

Run synthesis with the modified script:
design_vision -no_gui -f synthesis_pscan.tcl

Check the generated reports to extract key metrics:

Area (A): From reports/pscan_area.rpt
Chain Length (L): From reports/pscan_chain.rep


Run ATPG:
tmax -no_gui -f tmax_pscan.tcl
Note: For lower K values, ATPG may take a very long time. You can interrupt the process with SIGINT (Ctrl+C) once test coverage exceeds 40%.
Extract ATPG metrics:

Test Coverage (TC): From the ATPG report
Pattern Count (N): From the ATPG report


Calculate the M metric:
M = TC / (A/K1 × N/K2 × L/K3 × P/K4)
Where K1=14233, K2=480, K3=215, K4=3
Repeat for each K value to identify the optimal design point.

 Notes on Implementation
- The optimal implementation uses 40% of flip-flops (86 out of 215)
- Two balanced scan chains of 43 FFs each are used
- The M metric value is 699.58, which is a 416% improvement over full scan

If any issues are encountered, please check the reports directory for detailed logs.