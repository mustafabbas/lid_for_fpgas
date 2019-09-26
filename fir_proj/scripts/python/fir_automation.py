#!/usr/bin/env python3

import sys
import subprocess
import time
import os
import fileinput
from array import *
from multiprocessing import Process

# constants
NUM_VARIABLES       = 13
NUM_SEEDS           = 5 
ns_TO_MHz           = 1000
TIMMING_CONSTRAINT  = 1 #ns
NUM_RUN_IN_PARALLEL = 4

# tcl script locations
CREATE_PROJ_TCL = ''
MULTI_SEED_TCL  = 'scripts/tcl/multi_seed.tcl'

current_project     = ''
module_top_name     = ''
module_top_path     = ''
sdc_file_name       = ''

def create_project_directories(num_projects, current_project, new_project_directory):
    """
    Takes as an input the current_project src code directory and the number of projects
    to replicate, then creates those projects in the new_project_directory specified.
    """
    subprocess.call(['mkdir', new_project_directory])
    for i in range(0, num_projects):
        subprocess.call(['cp', '-r', current_project, new_project_directory + '/'
                        + current_project + '_' + str(i)])

def build_projects(projects_directory, module_top_name):
    """
    Takes in tcl_script to generate Quartus projects from the projects_directory and
    run through the CAD flow.
    """
    projects_list = os.listdir(projects_directory)
    i = 0
    for project in projects_list:
        p = subprocess.Popen(['quartus_sh', '-t', CREATE_PROJ_TCL, projects_directory + '/'
                             + project + '/' + module_top_name, module_top_name])
        if (i % NUM_RUN_IN_PARALLEL) == 0 and i != 0:
            p.wait()
        i += 1
    p.wait()

def run_multi_seed(projects_directory, module_top_name):
    """
    Runs the command to start Quartus with a tcl script file that runs the design
    through multiple seeds.
    """
    projects_list = os.listdir(projects_directory)
    i = 0
    for project in projects_list:
        p = subprocess.Popen(['quartus_sta', '-t', MULTI_SEED_TCL, projects_directory + '/'
                             + project + '/' + module_top_name, module_top_name])
        if (i % NUM_RUN_IN_PARALLEL) == 0 and i != 0:
            p.wait()
        i += 1
    p.wait()

def backup_seeds(projects_directory):
    """
    """
    projects_list = os.listdir(projects_directory)
    for project in projects_list:
        p = subprocess.Popen(['mv', projects_directory + '/' + project + '/seed_rpt', 
                             projects_directory + '/' + project + '/seed_rpt_bac'])
    p.wait()

def modify_num_fir_cascades(projects_directory):
    """
    """
    projects_list = os.listdir(projects_directory)
    num_fir = 1
    for project in projects_list:
        text_to_search = 'parameter N_FIRs = 1'
        text_to_replace = 'parameter N_FIRs = ' + str(num_fir)
        for line in fileinput.input(projects_directory + '/' + project + '/' + module_top_path,
                                    inplace=True):
            print(line.replace(text_to_search, text_to_replace), end='')

        if num_fir == 1:
            num_fir = 10
        else:
            num_fir = num_fir + 10

        fileinput.close()

def modify_src_parameters(projects_directory, text_to_search, text_to_replace):
    """
    """
    projects_list = os.listdir(projects_directory)
    for project in projects_list:
        for line in fileinput.input(projects_directory + '/' + project + '/' + module_top_path,
                                    inplace=True):
            print(line.replace(text_to_search, text_to_replace), end='')
        fileinput.close()

def parse_area(projects_directory, num_variables, num_seeds):
    """
    """
    # arrays to be used for parsed resutls
    aluts       = [[0 for x in range(num_seeds)] for y in range(num_variables)]
    registers   = [[0 for x in range(num_seeds)] for y in range(num_variables)]
    labs        = [[0 for x in range(num_seeds)] for y in range(num_variables)]
    m20k_blocks = [[0 for x in range(num_seeds)] for y in range(num_variables)]
    dsp_blocks  = [[0 for x in range(num_seeds)] for y in range(num_variables)]
    
    projects_list = os.listdir(projects_directory)
    for project in projects_list:
        try:
            src_file = open(projects_directory + '/' + project + '/' + module_top_path)
            num_fir = 0
            for line in src_file:
                if 'parameter N_FIRs =' in line:
                    num_fir = int(line.split()[3].split(',')[0])
    
            index = int(num_fir / 10)
            src_file.close()

            seed_num = 0
            seed_rpt_list = os.listdir(projects_directory + '/' + project + '/seed_rpt')
            for fitter_rpt in seed_rpt_list:
                if '.fit.rpt' not in fitter_rpt:
                    continue # not a fitter file
                fitter_file = open(projects_directory + '/' + project + '/seed_rpt/' + fitter_rpt)
                fitter_file_itter = iter(fitter_file)
                final_frequency = 1000.0
                for line in fitter_file_itter:
                    if 'Combinational ALUT usage for logic' in line:
                        num_aluts = int(line.split()[7].replace(',', ''))
                        aluts[index][seed_num] = num_aluts
                    if 'Design implementation registers' in line:
                        num_registers = int(line.split()[6].replace(',', ''))
                        registers[index][seed_num] = num_registers
                    if 'Total LABs:  partially or completely used' in line:
                        num_labs = int(line.split()[8].replace(',', ''))
                        labs[index][seed_num] = num_labs
                    if 'M20K block' in line:
                        num_m20k = int(line.split()[4].replace(',', ''))
                        m20k_blocks[index][seed_num] = num_m20k
                    if 'MP DSP' in line:
                        num_dsp = int(line.split()[4].replace(',', ''))
                        dsp_blocks[index][seed_num] = num_dsp
                        break #always the last line needed to be parsed in the file

                seed_num += 1
                fitter_file.close()

        except FileNotFoundError:
            pass #Dismiss the non-created varibles inorder to view the generated ones

    return aluts, registers, labs, m20k_blocks, dsp_blocks 

def parse_frequencies(projects_directory, num_variables, num_seeds):
    """
    """
    frequencies = [[0 for x in range(num_seeds)] for y in range(num_variables)]
    try:
        projects_list = os.listdir(projects_directory)
        for project in projects_list:
            try:
                src_file = open(projects_directory + '/' + project + '/' + module_top_path)
                num_fir = 0
                for line in src_file:
                    if 'parameter N_FIRs =' in line:
                        num_fir = int(line.split()[3].split(',')[0])
                if (num_fir % 10 != 0 and num_fir != 1):
                    continue
                index = int(num_fir / 10)
                src_file.close()

                seed_num = 0
                seed_rpt_list = os.listdir(projects_directory + '/' + project + '/seed_rpt')
                for timing_rpt in seed_rpt_list:
                    if '.sta.rpt' not in timing_rpt:
                        continue # not a timing file
                    timing_file = open(projects_directory + '/' + project + '/seed_rpt/' + timing_rpt)
                    timing_file_itter = iter(timing_file)
                    final_frequency = 1000.0
                    for line in timing_file_itter:
                        if 'Model Fmax Summary' in line and ';' in line:
                            line = next(timing_file_itter)
                            line = next(timing_file_itter)
                            line = next(timing_file_itter)
                            line = next(timing_file_itter)

                            frequency = float(line.split()[4])
                            if frequency < final_frequency:
                                final_frequency = frequency

                    frequencies[index][seed_num] = final_frequency
                    seed_num += 1

                    timing_file.close()
            except FileNotFoundError:
                pass #Dismiss the non-created varibles inorder to view the generated ones
    except FileNotFoundError:
        return [[]] #Dismiss the non-created dir
    return frequencies

def parse_frequencies_using_slack(projects_directory, frequencies):
    """
    """
    projects_list = os.listdir(projects_directory)
    for project in projects_list:
        try:
            src_file = open(projects_directory + '/' + project + '/' + module_top_path)
            num_fir = 0
            for line in src_file:
                if 'parameter N_FIRs =' in line:
                    num_fir = int(line.split()[3].split(',')[0])

            index = int(num_fir / 5)

            src_file.close()

            seed_num = 0
            seed_rpt_list = os.listdir(projects_directory + '/' + project + '/seed_rpt')
            for timing_rpt in seed_rpt_list:
                if '.sta.rpt' not in timing_rpt:
                    continue # not a timing file
                timing_file = open(projects_directory + '/' + project + '/seed_rpt/' + timing_rpt)
                timing_file_itter = iter(timing_file)
                slack = 0 # in ns
                for line in timing_file_itter:
                    if ('Model Setup Summary' in line and ';' in line) or \
                       ('Model Minimum Pulse Width Summary' in line and ';' in line):
                        line = next(timing_file_itter)
                        line = next(timing_file_itter)
                        line = next(timing_file_itter)
                        line = next(timing_file_itter)

                        temp_slack = float(line.split()[3])
                        if temp_slack < slack:
                            slack = temp_slack
                frequency = 1 / (TIMMING_CONSTRAINT - slack) * ns_TO_MHz
                frequencies[index][seed_num] = frequency
                seed_num += 1

                timing_file.close()

        except FileNotFoundError:
            pass #Dismiss the non-created varibles inorder to view the generated ones

def print_frequencies(array_name, frequencies_array):
    """
    """
    if len(frequencies_array) <= 1 :
        return

    print(array_name)
    print()

    for i in range(NUM_VARIABLES):
        average = 0
        num_to_average = 0
        num_firs = 0

        if i == 0:
            num_firs = 1
        else:
            num_firs = i * 10

        print(num_firs, end = '\t')

        for j in range(NUM_SEEDS):
            print('{0:.2f}'.format(frequencies_array[i][j]), end = '\t')
            if (frequencies_array[i][j] != 0):
                average += frequencies_array[i][j]
                num_to_average += 1
        if num_to_average == 0:
            num_to_average = 1
        average = average / num_to_average
        print('{0:.2f}'.format(average))
    print()

def print_int_array(array_name, int_array):
    """
    """
    print(array_name)
    print()

    for i in range(NUM_VARIABLES):
        average = 0
        num_to_average = 0
        num_firs = 0

        if i == 0:
            num_firs = 1
        else:
            num_firs = i * 10

        print(num_firs, end = '\t')

        for j in range(NUM_SEEDS):
            print(int_array[i][j], end = '\t')
            if (int_array[i][j] != 0):
                average += int_array[i][j]
                num_to_average += 1
        if num_to_average == 0:
            num_to_average = 1
        average = average / num_to_average
        print('{0:.2f}'.format(average))
    print()

def make_matlab_vectors(matlab_file, vector_name, frequencies_array):
    """ 
    Writes the min, max, and avg value of each row in frequencies_array in the matlab_file specified.
    For each vector_name three vectors are created with the specified vector name as the prefix and
    min, max, or avg as the suffix.
    """
    make_matlab_vectors_avg(matlab_file, vector_name, frequencies_array);
    make_matlab_vectors_min(matlab_file, vector_name, frequencies_array);
    make_matlab_vectors_max(matlab_file, vector_name, frequencies_array);

def make_matlab_vectors_avg(matlab_file, vector_name, frequencies_array):
    """
    Writes the avg value of each row in frequencies_array as a matlab vector, with the name as
    "vector_name"_avg, in the specified matlab_file.
    """
    matlab_file.write(vector_name + ' = [')

    for i in range(NUM_VARIABLES):
        average = 0
        maxx = 0
        for j in range(NUM_SEEDS):
            if frequencies_array[i][j] == 0:
                continue
            if frequencies_array[i][j] > maxx:
                maxx = frequencies_array[i][j]
            average += frequencies_array[i][j]
        average = average / NUM_SEEDS
        if (i == NUM_VARIABLES - 1):
            matlab_file.write(str('{0:.2f}'.format(average)) + '];')
        else:
            matlab_file.write(str('{0:.2f}'.format(average)) + ', ')
    
    matlab_file.write('\n')


def make_matlab_vectors_max(matlab_file, vector_name, frequencies_array):
    """
    Writes the max value of each row in frequencies_array as a matlab vector, with the name as
    "vector_name"_max, in the specified matlab_file.
    """
    matlab_file.write(vector_name + '_max = [')

    for i in range(NUM_VARIABLES):
        maxx = 0
        for j in range(NUM_SEEDS):
            if frequencies_array[i][j] > maxx:
                maxx = frequencies_array[i][j]
        if (i == NUM_VARIABLES - 1):
            matlab_file.write(str('{0:.2f}'.format(maxx)) + '];')
        else:
            matlab_file.write(str('{0:.2f}'.format(maxx)) + ', ')
    
    matlab_file.write('\n')


def make_matlab_vectors_min(matlab_file, vector_name, frequencies_array):
    """
    Writes the min value of each row in frequencies_array as a matlab vector, with the name as
    "vector_name"_min, in the specified matlab_file.
    """
    matlab_file.write(vector_name + '_min = [')

    for i in range(NUM_VARIABLES):
        minn = 6000
        for j in range(NUM_SEEDS):
            if frequencies_array[i][j] == 0:
                continue
            if frequencies_array[i][j] < minn:
                minn = frequencies_array[i][j]
        if (i == NUM_VARIABLES - 1):
            matlab_file.write(str('{0:.2f}'.format(minn)) + '];')
        else:
            matlab_file.write(str('{0:.2f}'.format(minn)) + ', ')

    matlab_file.write('\n')

def run_design(directory, is_non_li, num_reg, num_relay_stations):
    """
    """
    create_project_directories(NUM_VARIABLES, current_project, directory)
    modify_num_fir_cascades(directory)

    if(is_non_li):
        text_to_search  = 'parameter LI=0'
        text_to_replace = 'parameter LI=1'
        modify_src_parameters(directory, text_to_search, text_to_replace)
        text_to_search  = 'parameter LI_OPT=0'
        text_to_replace = 'parameter LI_OPT=1'
        modify_src_parameters(directory, text_to_search, text_to_replace)
        text_to_search  = 'parameter LI_PIPELINE_WRAPPER=0'
        text_to_replace = 'parameter LI_PIPELINE_WRAPPER=1'
        modify_src_parameters(directory, text_to_search, text_to_replace)

    if(num_reg > 0):
        text_to_search  = 'parameter N_OUTPUT_REG=0'
        text_to_replace = 'parameter N_OUTPUT_REG=' + str(num_reg)
        modify_src_parameters(directory, text_to_search, text_to_replace)

        text_to_search  = 'parameter N_STAGES = 0'
        text_to_replace = 'parameter N_STAGES = ' + str(num_reg)
        modify_src_parameters(directory, text_to_search, text_to_replace)

    if(num_relay_stations > 0):
        text_to_search  = 'parameter N_RELAY_STATIONS=0'
        text_to_replace = 'parameter N_RELAY_STATIONS=' + str(num_relay_stations)
        modify_src_parameters(directory, text_to_search, text_to_replace)

    build_projects(directory, module_top_name)
    run_multi_seed(directory, module_top_name)

def run_in_parallel(*functions):
    """
    """
    proc = []
    for function in functions:
        p = Process(target=function[0], args=function[1])
        p.start()
        proc.append(p)
    for p in proc:
        p.join()

def main(argv):

    global current_project
    global module_top_name
    global module_top_path
    global sdc_file_name
    global CREATE_PROJ_TCL

    module_top_name = 'fir_cascade'
    sdc_file_name   = 'fir_cascade.sdc'

# Project Definitions

    # Credit based designs
    li_credit_0_dir     = 'LI_CREDIT_0'
    li_credit_1_dir     = 'LI_CREDIT_1'
    li_credit_2_dir     = 'LI_CREDIT_2'
    li_credit_3_dir     = 'LI_CREDIT_3'
    li_credit_6_dir     = 'LI_CREDIT_6'

    li_credit_0_args    = [li_credit_0_dir, False, 0, 0]
    li_credit_1_args    = [li_credit_1_dir, False, 1, 0]
    li_credit_2_args    = [li_credit_2_dir, False, 2, 0]
    li_credit_3_args    = [li_credit_3_dir, False, 3, 0]
    li_credit_6_args    = [li_credit_6_dir, False, 6, 0]

    # Ready-valid based designs
    li_qsys_0_dir       = 'LI_QSYS_0'
    li_qsys_1_dir       = 'LI_QSYS_1'
    li_qsys_2_dir       = 'LI_QSYS_2'
    li_qsys_3_dir       = 'LI_QSYS_3'
    li_qsys_6_dir       = 'LI_QSYS_6'

    li_qsys_0_args      = [li_qsys_0_dir, False, 0, 0]
    li_qsys_1_args      = [li_qsys_1_dir, False, 1, 0]
    li_qsys_2_args      = [li_qsys_3_dir, False, 2, 0]
    li_qsys_3_args      = [li_qsys_3_dir, False, 3, 0]
    li_qsys_6_args      = [li_qsys_6_dir, False, 6, 0]

    # Non-latency insensitive based designs
    non_li_0_dir        = 'NON_LI_0_REG'
    non_li_1_dir        = 'NON_LI_1_REG'
    non_li_2_dir        = 'NON_LI_2_REG'
    non_li_3_dir        = 'NON_LI_3_REG'
    non_li_6_dir        = 'NON_LI_6_REG'

    non_li_0_args       = [non_li_0_dir, False, 0, 0]
    non_li_1_args       = [non_li_1_dir, False, 1, 0]
    non_li_2_args       = [non_li_2_dir, False, 2, 0]
    non_li_3_args       = [non_li_3_dir, False, 3, 0]
    non_li_6_args       = [non_li_6_dir, False, 6, 0]
    
    # Carloni based designs
    li_carloni_0_dir    = 'LI_CARLONI_0'
    li_carloni_1_dir    = 'LI_CARLONI_1'
    li_carloni_2_dir    = 'LI_CARLONI_2'
    li_carloni_3_dir    = 'LI_CARLONI_3'
    li_carloni_6_dir    = 'LI_CARLONI_6'

    li_carloni_0_args   = [li_carloni_0_dir, True, 0, 0]
    li_carloni_1_args   = [li_carloni_1_dir, True, 0, 1]
    li_carloni_2_args   = [li_carloni_2_dir, True, 0, 2]
    li_carloni_3_args   = [li_carloni_3_dir, True, 0, 3]
    li_carloni_6_args   = [li_carloni_6_dir, True, 0, 6]

# Run projects

#    # Zero register designs
#    current_project = 'fir_arria_credit_src'
#    module_top_path = 'fir_cascade.sv'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_fir_proj_credit.tcl'
#    run_in_parallel((run_design, li_credit_0_args))
#    current_project = 'fir_arria_qsys_src'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_fir_proj_qsys.tcl'
#    run_in_parallel((run_design, li_qsys_0_args))
#    current_project = 'fir_cascade_aria_10_src'
#    module_top_path = 'hdl/fir_cascade.sv'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_fir_proj_carloni.tcl'
#    run_in_parallel((run_design, li_carloni_0_args))
#    run_in_parallel((run_design, non_li_0_args))
#
#    # One register designs
#    current_project = 'fir_arria_credit_src'
#    module_top_path = 'fir_cascade.sv'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_fir_proj_credit.tcl'
#    run_in_parallel((run_design, li_credit_1_args))
#    current_project = 'fir_arria_qsys_src'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_fir_proj_qsys.tcl'
#    run_in_parallel((run_design, li_qsys_1_args))
#    current_project = 'fir_cascade_aria_10_src'
#    module_top_path = 'hdl/fir_cascade.sv'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_fir_proj_carloni.tcl'
#    run_in_parallel((run_design, li_carloni_1_args))
#    run_in_parallel((run_design, non_li_1_args))
#
#    # Two register designs
#    current_project = 'fir_arria_credit_src'
#    module_top_path = 'fir_cascade.sv'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_fir_proj_credit.tcl'
#    run_in_parallel((run_design, li_credit_2_args))
#    current_project = 'fir_arria_qsys_src'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_fir_proj_qsys.tcl'
#    run_in_parallel((run_design, li_qsys_2_args))
#    current_project = 'fir_cascade_aria_10_src'
#    module_top_path = 'hdl/fir_cascade.sv'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_fir_proj_carloni.tcl'
#    run_in_parallel((run_design, li_carloni_2_args))
#    run_in_parallel((run_design, non_li_2_args))
#
#    # Three register designs
#    current_project = 'fir_arria_credit_src'
#    module_top_path = 'fir_cascade.sv'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_fir_proj_credit.tcl'
#    run_in_parallel((run_design, li_credit_3_args))
#    current_project = 'fir_arria_qsys_src'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_fir_proj_qsys.tcl'
#    run_in_parallel((run_design, li_qsys_3_args))
#    current_project = 'fir_cascade_aria_10_src'
#    module_top_path = 'hdl/fir_cascade.sv'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_fir_proj_carloni.tcl'
#    run_in_parallel((run_design, li_carloni_3_args))
#    run_in_parallel((run_design, non_li_3_args))
#
#    # Six register designs
#    current_project = 'fir_arria_credit_src'
#    module_top_path = 'fir_cascade.sv'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_fir_proj_credit.tcl'
#    run_in_parallel((run_design, li_credit_6_args))
#    current_project = 'fir_arria_qsys_src'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_fir_proj_qsys.tcl'
#    run_in_parallel((run_design, li_qsys_6_args))
#    current_project = 'fir_cascade_aria_10_src'
#    module_top_path = 'hdl/fir_cascade.sv'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_fir_proj_carloni.tcl'
#    run_in_parallel((run_design, li_carloni_6_args))
#    run_in_parallel((run_design, non_li_6_args))

# Parse Fmax results into arrays

    # Zero register designs
    module_top_path = 'fir_cascade.sv'
    li_credit_0_frequencies = parse_frequencies(li_credit_0_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(li_credit_0_dir, li_credit_0_frequencies)
    li_qsys_0_frequencies = parse_frequencies(li_qsys_0_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(li_qsys_0_dir, li_qsys_0_frequencies)
    module_top_path = 'hdl/fir_cascade.sv'
    li_carloni_0_frequencies = parse_frequencies(li_carloni_0_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(li_carloni_0_dir, li_carloni_0_frequencies)
    non_li_0_frequencies = parse_frequencies(non_li_0_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(non_li_0_dir, non_li_0_frequencies)

    # One register designs
    module_top_path = 'fir_cascade.sv'
    li_credit_1_frequencies = parse_frequencies(li_credit_1_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(li_credit_1_dir, li_credit_1_frequencies)
    li_qsys_1_frequencies = parse_frequencies(li_qsys_1_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(li_qsys_1_dir, li_qsys_1_frequencies)
    module_top_path = 'hdl/fir_cascade.sv'
    li_carloni_1_frequencies = parse_frequencies(li_carloni_1_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(li_carloni_1_dir, li_carloni_1_frequencies)
    non_li_1_frequencies = parse_frequencies(non_li_1_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(non_li_1_dir, non_li_1_frequencies)

    # Two register designs
    module_top_path = 'fir_cascade.sv'
    li_credit_2_frequencies = parse_frequencies(li_credit_2_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(li_credit_2_dir, li_credit_2_frequencies)
    li_qsys_2_frequencies = parse_frequencies(li_qsys_2_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(li_qsys_2_dir, li_qsys_2_frequencies)
    module_top_path = 'hdl/fir_cascade.sv'
    li_carloni_2_frequencies = parse_frequencies(li_carloni_2_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(li_carloni_2_dir, li_carloni_2_frequencies)
    non_li_2_frequencies = parse_frequencies(non_li_2_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(non_li_2_dir, non_li_2_frequencies)

    # Three register designs
    module_top_path = 'fir_cascade.sv'
    li_credit_3_frequencies = parse_frequencies(li_credit_3_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(li_credit_3_dir, li_credit_3_frequencies)
    li_qsys_3_frequencies = parse_frequencies(li_qsys_3_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(li_qsys_3_dir, li_qsys_3_frequencies)
    module_top_path = 'hdl/fir_cascade.sv'
    li_carloni_3_frequencies = parse_frequencies(li_carloni_3_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(li_carloni_3_dir, li_carloni_3_frequencies)
    non_li_3_frequencies = parse_frequencies(non_li_3_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(non_li_3_dir, non_li_3_frequencies)

    # Six register designs
    module_top_path = 'fir_cascade.sv'
    li_credit_6_frequencies = parse_frequencies(li_credit_6_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(li_credit_6_dir, li_credit_6_frequencies)
    li_qsys_6_frequencies = parse_frequencies(li_qsys_6_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(li_qsys_6_dir, li_qsys_6_frequencies)
    module_top_path = 'hdl/fir_cascade.sv'
    li_carloni_6_frequencies = parse_frequencies(li_carloni_6_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(li_carloni_6_dir, li_carloni_6_frequencies)
    non_li_6_frequencies = parse_frequencies(non_li_6_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(non_li_6_dir, non_li_6_frequencies)

# Parse area results into arrays

    # Zero register designs
    module_top_path = 'fir_cascade.sv'
    print(li_credit_0_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(li_credit_0_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)
    print(li_qsys_0_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(li_qsys_0_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)
    module_top_path = 'hdl/fir_cascade.sv'
    print(li_carloni_0_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(li_carloni_0_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)
    print(non_li_0_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(non_li_0_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)

    # One register designs
    module_top_path = 'fir_cascade.sv'
    print(li_credit_1_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(li_credit_1_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)
    print(li_qsys_1_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(li_qsys_1_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)
    module_top_path = 'hdl/fir_cascade.sv'
    print(li_carloni_1_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(li_carloni_1_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)
    print(non_li_1_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(non_li_1_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)

    # Two register designs
    module_top_path = 'fir_cascade.sv'
    print(li_credit_2_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(li_credit_2_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)
    print(li_qsys_2_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(li_qsys_2_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)
    module_top_path = 'hdl/fir_cascade.sv'
    print(li_carloni_2_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(li_carloni_2_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)
    print(non_li_2_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(non_li_2_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)

    # Three register designs
    module_top_path = 'fir_cascade.sv'
    print(li_credit_3_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(li_credit_3_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)
    print(li_qsys_3_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(li_qsys_3_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)
    module_top_path = 'hdl/fir_cascade.sv'
    print(li_carloni_3_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(li_carloni_3_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)
    print(non_li_3_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(non_li_3_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)

    # Six register designs
    module_top_path = 'fir_cascade.sv'
    print(li_credit_6_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(li_credit_6_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)
    print(li_qsys_6_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(li_qsys_6_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)
    module_top_path = 'hdl/fir_cascade.sv'
    print(li_carloni_6_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(li_carloni_6_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)
    print(non_li_6_dir)
    aluts, registers, labs, m20k_blocks, dsp_blocks \
        = parse_area(non_li_6_dir, NUM_VARIABLES, NUM_SEEDS)
    print_int_array('aluts', aluts)
    print_int_array('registers', registers)
    print_int_array('labs', labs)
    print_int_array('m20k_blocks', m20k_blocks)
    print_int_array('dsp_blocks', dsp_blocks)

# output avg, max, and min Fmax results to matlab file
    matlab_filename = 'fir_scaling_dat.m'
    matlab_file = open(matlab_filename, 'w')

    make_matlab_vectors(matlab_file, li_carloni_0_dir, li_carloni_0_frequencies)
    make_matlab_vectors(matlab_file, li_carloni_1_dir, li_carloni_1_frequencies)
    make_matlab_vectors(matlab_file, li_carloni_2_dir, li_carloni_2_frequencies)
    make_matlab_vectors(matlab_file, li_carloni_3_dir, li_carloni_3_frequencies)
    make_matlab_vectors(matlab_file, li_carloni_6_dir, li_carloni_6_frequencies)

    make_matlab_vectors(matlab_file, li_credit_0_dir, li_credit_0_frequencies)
    make_matlab_vectors(matlab_file, li_credit_1_dir, li_credit_1_frequencies)
    make_matlab_vectors(matlab_file, li_credit_2_dir, li_credit_2_frequencies)
    make_matlab_vectors(matlab_file, li_credit_3_dir, li_credit_3_frequencies)
    make_matlab_vectors(matlab_file, li_credit_6_dir, li_credit_6_frequencies)

    make_matlab_vectors(matlab_file, li_qsys_0_dir, li_qsys_0_frequencies)
    make_matlab_vectors(matlab_file, li_qsys_1_dir, li_qsys_1_frequencies)
    make_matlab_vectors(matlab_file, li_qsys_2_dir, li_qsys_2_frequencies)
    make_matlab_vectors(matlab_file, li_qsys_3_dir, li_qsys_3_frequencies)
    make_matlab_vectors(matlab_file, li_qsys_6_dir, li_qsys_6_frequencies)

    make_matlab_vectors(matlab_file, non_li_0_dir, non_li_0_frequencies)
    make_matlab_vectors(matlab_file, non_li_1_dir, non_li_1_frequencies)
    make_matlab_vectors(matlab_file, non_li_2_dir, non_li_2_frequencies)
    make_matlab_vectors(matlab_file, non_li_3_dir, non_li_3_frequencies)
    make_matlab_vectors(matlab_file, non_li_6_dir, non_li_6_frequencies)

    matlab_file.close()

# use: import module_name; module_name.main() to execute main func in another script
if __name__ == "__main__":
    main(sys.argv)
