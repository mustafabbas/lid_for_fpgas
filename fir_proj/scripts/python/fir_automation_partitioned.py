#!/usr/bin/env python3

import sys
import subprocess
import time
import os
import fileinput
from array import *
from multiprocessing import Process

# constants
NUM_VARIABLES       = 12 
NUM_SEEDS           = 5 
ns_TO_MHz           = 1000
TIMMING_CONSTRAINT  = 1 #ns
NUM_RUN_IN_PARALLEL = 1

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
        if (i % NUM_RUN_IN_PARALLEL) == 0:
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
        if (i % NUM_RUN_IN_PARALLEL) == 0:
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
    num_pipeline = 0

    projects_list = os.listdir(projects_directory)
    for project in projects_list:
        
        project_path = projects_directory + '/' + project + '/' + module_top_path

        text_to_search = 'parameter N_FIRs = 1'
        text_to_replace = 'parameter N_FIRs = 2' 
        modify_src_parameter(project_path, text_to_search, text_to_replace)
        
        text_to_search  = 'parameter N_OUTPUT_REG=0'
        text_to_replace = 'parameter N_OUTPUT_REG=' + str(num_pipeline)
        modify_src_parameter(project_path, text_to_search, text_to_replace)

        text_to_search  = 'parameter N_STAGES = 0'
        text_to_replace = 'parameter N_STAGES = ' + str(num_pipeline)
        modify_src_parameter(project_path, text_to_search, text_to_replace)

        text_to_search  = 'parameter N_RELAY_STATIONS=0'
        text_to_replace = 'parameter N_RELAY_STATIONS=' + str(num_pipeline)
        modify_src_parameter(project_path, text_to_search, text_to_replace)

        num_pipeline += 1

def modify_src_parameter(project_path, text_to_search, text_to_replace):
    """
    """
    for line in fileinput.input(project_path, inplace=True):
        print(line.replace(text_to_search, text_to_replace), end='')
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
                    if 'parameter N_OUTPUT_REG=' in line:
                        num_fir = int(line.split()[2].split(',')[0])
                    elif 'parameter N_STAGES =' in line:
                        num_fir = int(line.split()[3].split(',')[0])
                    elif 'parameter N_RELAY_STATIONS=' in line:
                        num_fir = int(line.split()[2].split(',')[0])

                index = int(num_fir)
                print(project, ' ', num_fir)
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
        num_pipelines = i 

        print(num_pipelines, end = '\t')

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
    if len(frequencies_array) <= 1 :
        return
    
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

def run_design(directory, wrapper_type):
    """
    """
    create_project_directories(NUM_VARIABLES, current_project, directory)
    modify_num_fir_cascades(directory)

    text_to_search  = 'parameter WRAPPER_TYPE = ""'
    text_to_replace = 'parameter WRAPPER_TYPE = "' + wrapper_type + '"'
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
    module_top_path = 'hdl/top/fir_cascade.sv'
    CREATE_PROJ_TCL = 'scripts/tcl/create_proj_stratix10_par.tcl'
    current_project = 'fir_all_wrappers_src'
    sdc_file_name   = 'fir_cascade.sdc'

# Project Definitions


    # Credit based designs
    stratix_credit_par_dir   = 'LI_CREDIT_PAR_STRATIX'
    stratix_credit_par_args  = [stratix_credit_par_dir, "credit"]

    # Ready-valid based designs
    stratix_qsys_par_dir     = 'LI_QSYS_PAR_STRATIX'
    stratix_qsys_par_args    = [stratix_qsys_par_dir, "qsys"]

    # Non-latency insensitive based designs
    stratix_non_li_par_dir   = 'NON_LI_PAR_STRATIX'
    stratix_non_li_par_args  = [stratix_non_li_par_dir, "non-li"]
    
    # Carloni based designs
    stratix_carloni_par_dir  = 'CARLONI_PAR_STRATIX'
    stratix_carloni_par_args = [stratix_carloni_par_dir, "carloni"]


#    # Credit based designs
#    stratix_credit_par_dir     = 'LI_CREDIT_PAR_STRATIX'
##
#    # Ready-valid based designs
#    stratix_qsys_dir       = 'LI_QSYS_PAR_STRATIX'
##
##    # Non-latency insensitive based designs
##    non_li_dir        = 'pipeline_efficiency/NON_LI_PAR'
##    
#    # Carloni based designs
#    stratix_carloni = 'NON_LI_PAR_STRATIX' 


# Run Projects

#    # Non-Li
#    run_design(stratix_non_li_par_dir, "non-li")
#
#    # Carloni
#    run_design(stratix_carloni_par_dir, "carloni")
#
#    # Credit
#    run_design(stratix_credit_par_dir, "credit")
#
#    # Qsys 
#    run_design(stratix_qsys_par_dir, "qsys")
#
#    run_in_parallel((run_design, stratix_non_li_par_args),
#                    (run_design, stratix_carloni_par_args),
#                    (run_design, stratix_credit_par_args),
#                    (run_design, stratix_qsys_par_args))

#    # Ready-valid
#    module_top_path = 'fir_cascade.sv'
#    run_multi_seed(li_qsys_dir, module_top_name)
#
#    # Non-LI
#    module_top_path = 'hdl/fir_cascade.sv'
#    run_multi_seed(non_li_dir, module_top_name)
#    


#    # Carloni
#    module_top_path = 'hdl/fir_cascade.sv'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_proj_carloni_stratix_par.tcl'
#    current_project = 'fir_stratix_par_src'
#    run_design(stratix_carloni, False)

#    # Credit
#    module_top_path = 'fir_cascade.sv'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_proj_credit_stratix_par.tcl'
#    current_project = 'fir_stratix_credit_par_src'
#    run_design(stratix_credit_par_dir, False)

#    # Qsys 
#    module_top_path = 'hdl/top/fir_cascade.sv'
#    CREATE_PROJ_TCL = 'scripts/tcl/create_proj_stratix10_par.tcl'
#    current_project = 'fir_all_wrappers_src'
#    run_design(stratix_qsys_dir, False)


# Parse Frequency

#    # Credit
#    module_top_path = 'fir_cascade.sv'
#    li_credit_frequencies = parse_frequencies(li_credit_dir, NUM_VARIABLES, NUM_SEEDS)
#    print_frequencies(li_credit_dir, li_credit_frequencies)
#
#    # Ready-valid
#    module_top_path = 'fir_cascade.sv'
#    li_qsys_frequencies = parse_frequencies(li_qsys_dir, NUM_VARIABLES, NUM_SEEDS)
#    print_frequencies(li_qsys_dir, li_qsys_frequencies)
#
#    # Non-LI 
#    module_top_path = 'hdl/fir_cascade.sv'
#    non_li_frequencies = parse_frequencies(non_li_dir, NUM_VARIABLES, NUM_SEEDS)
#    print_frequencies(non_li_dir, non_li_frequencies)
#
#    # Carloni
#    module_top_path = 'hdl/fir_cascade.sv'
#    li_carloni_frequencies = parse_frequencies(stratix_carloni, NUM_VARIABLES, NUM_SEEDS)
#    print_frequencies(stratix_carloni, li_carloni_frequencies)

#    # Credit
#    module_top_path = 'fir_cascade.sv'
#    li_credit_frequencies = parse_frequencies(stratix_credit_par_dir, NUM_VARIABLES, NUM_SEEDS)
#    print_frequencies(stratix_credit_par_dir, li_credit_frequencies)
#    # Qsys 
#    module_top_path = 'hdl/top/fir_cascade.sv'
#    li_qsys_frequencies = parse_frequencies(stratix_qsys_dir, NUM_VARIABLES, NUM_SEEDS)
#    print_frequencies(stratix_qsys_dir, li_qsys_frequencies)

    # Non-Li
    non_li_frequencies = parse_frequencies(stratix_non_li_par_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(stratix_non_li_par_dir, non_li_frequencies)

    # Carloni
    li_carloni_frequencies = parse_frequencies(stratix_carloni_par_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(stratix_carloni_par_dir, li_carloni_frequencies)

    # Credit
    li_credit_frequencies = parse_frequencies(stratix_credit_par_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(stratix_credit_par_dir, li_credit_frequencies)

    # Qsys 
    li_qsys_frequencies = parse_frequencies(stratix_qsys_par_dir, NUM_VARIABLES, NUM_SEEDS)
    print_frequencies(stratix_qsys_par_dir, li_qsys_frequencies)

## output avg, max, and min Fmax results to matlab file
#    matlab_filename = 'fir_scaling_dat.m'
#    matlab_file = open(matlab_filename, 'w')
#
#    make_matlab_vectors(matlab_file, li_carloni_dir.split('/')[-1], li_carloni_frequencies)
#    make_matlab_vectors(matlab_file, li_credit_dir.split('/')[-1], li_credit_frequencies)
#    make_matlab_vectors(matlab_file, li_qsys_dir.split('/')[-1], li_qsys_frequencies)
#    make_matlab_vectors(matlab_file, non_li_dir.split('/')[-1], non_li_frequencies)
#
#    matlab_file.close()

# use: import module_name; module_name.main() to execute main func in another script
if __name__ == "__main__":
    main(sys.argv)
