# This tcl is used to sweep seed by running fitter and STA.
# The timing report will be stored in seed_rpt directory.
#
# Author: Mustafa Abbas
# Modified from original source by Boon Seong at:
# https://almost-a-technocrat.blogspot.ca/2013/07/run-quartus-ii-fitter-and-timequest_3.html

# Check valid number of input arguments
if {$argc < 2} {
    puts "Missing input arguments"
    puts "usage quartus_sh -t <tcl_execuable> <project_dir/top_module_name> <top_module_name>"
    puts "                    <sdc_file>"
    qexit -error
}

# Load required packages
load_package flow
load_package report

# Specify project name and revision name
set project_name [lindex $argv 0]
set project_revision [lindex $argv 1]
#set sdc_file [lindex $argv 2]

# Set seeds
set seedList {1 2 3 4 5}
set timetrynum [llength $seedList]
puts "Total compiles: $timetrynum"
project_open -revision $project_revision $project_name

# Specify seed compile report directory
set rptdir seed_rpt
file mkdir $rptdir
set trynum 0
while { $timetrynum > $trynum } {

    set current_seed [lindex $seedList $trynum]
    set_global_assignment -name SEED $current_seed

#    # Skip run if file results already exist
#    if{[file exists $rptdir/seed$current_seed.sta.rpt]
#       && [file exists $rptdir/seed$current_seed.fit.rpt]} {
#        puts "Already ran current seed $current_seed, skipping..."
#        continue
#    }

    # Place & Route
    if {[catch {execute_module -tool fit} result]} {
        puts "\nResult: $result\n"
        puts "ERROR: Quartus II Fitter failed. See the report file.\n"
        qexit -error
    } else {
        puts "\nInfo: Quartus II Fitter was successful.\n"
    }

    # TimeQuest Timing Analyzer
    if {[catch {execute_module -tool sta} result]} {
        puts "\nResult: $result\n"
        puts "ERROR: TimeQuest Analyzer failed. See the report file.\n"
        qexit -error
    } else {
        puts "\nInfo: TimeQuest Analyzer was successful.\n"
    }

    # Critical Path Analysis
    create_timing_netlist
    read_sdc fir_cascade.sdc
    update_timing_netlist
    report_timing -from_clock { clock } -to_clock { clock } -setup -npaths 1000 -detail full_path -panel_name {Report Timing} -multi_corner -file critical_path.rpt
    delete_timing_netlist

    # Store compile results
    file copy -force ./output_files/$project_revision.fit.rpt $rptdir/seed$current_seed.fit.rpt
    file copy -force ./output_files/$project_revision.sta.rpt $rptdir/seed$current_seed.sta.rpt
    file copy -force critical_path.rpt $rptdir/seed$current_seed.cp.rpt
    load_report
    set panel {TimeQuest Timing Analyzer||Multicorner Timing Analysis Summary}
    set id [get_report_panel_id $panel]
    if {$id != -1} {
        write_report_panel -file $rptdir/Multicorner_sta_seed$current_seed.htm -html -id $id
    } else {
        puts "Error: report panel could not be found."
    }
    unload_report
    incr trynum
}

project_close

