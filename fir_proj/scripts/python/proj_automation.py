#!/usr/bin/env python3

import sys
import math
import subprocess
import time
import os
import fileinput
from array import *
from multiprocessing import Process

# constants
START_WIDTH         = 17#32
NUM_WIDTHS          = 1#6

NUM_PIPELINES       = 3#15#11
NUM_MODULES         = 5#7
MOD_JUMP_AMT        = 40#20
PIPE_JUMP_AMT       = 1#10

START_PIP           = 0 

NUM_SEEDS           = 5 

ns_TO_MHz           = 1000
TIMMING_CONSTRAINT  = 1 #ns

NUM_RUN_IN_PARALLEL = 1

# tcl script locations
CREATE_PROJ_TCL = ''
RUN_PROJ_TCL = ''
MULTI_SEED_TCL  = '../../scripts/tcl/multi_seed1.tcl'

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
        project_num_prefix = '_'
        if (i < 10):
            project_num_prefix = '_0'
        subprocess.call(['cp', '-r', current_project, new_project_directory + '/'
                        + current_project + project_num_prefix + str(i)])

def build_projects(projects_directory, module_top_name):
    """
    Takes in tcl_script to generate Quartus projects from the projects_directory and
    run through the CAD flow.
    """
    projects_list = os.listdir(projects_directory)
    projects_list.sort()
    i = 1 
    for project in projects_list:
        if(os.path.isfile(projects_directory + '/' + project + '/'
           + module_top_name + '.qsf')):
            continue
        p = subprocess.Popen(['quartus_sh', '-t', CREATE_PROJ_TCL, projects_directory + '/'
                             + project + '/' + module_top_name, module_top_name])
        if (i % NUM_RUN_IN_PARALLEL) == 0:
            p.wait()
        i += 1
    p.wait()
    
    add_partitions_to_projects(projects_directory, projects_list, module_top_name)
    synthesize_projects(projects_directory, projects_list, module_top_name)    


def synthesize_projects(projects_directory, projects_list, module_top_name):
    """
    """
    i = 1
    for project in projects_list:
        p = subprocess.Popen(['quartus_syn' , projects_directory + '/'
                             + project + '/' + module_top_name])
        if (i % NUM_RUN_IN_PARALLEL) == 0:
            p.wait()
        i += 1
    p.wait()

def partiton_merge_projects(projects_directory, projects_list, module_top_name):
    """
    """
    for project in projects_list:
        p = subprocess.Popen(['quartus_cdb', '--merge', projects_directory + '/'
                             + project + '/' + module_top_name])
        if (i % NUM_RUN_IN_PARALLEL) == 0:
            p.wait()
        i += 1
    p.wait()

def add_partitions_to_projects(projects_directory, projects_list, module_top_name):
    """
    """
    for project in projects_list:
        num_partitions = int(project.split('_')[-1])*MOD_JUMP_AMT
        qsf_file = projects_directory + '/' + project + '/' + module_top_name + '.qsf'
        add_partitions_to_qsf(num_partitions, qsf_file)

def add_partitions_to_qsf(num_partitions, qsf_file):
    """
    """
    myfile = open(qsf_file, 'a')
    
    initial_text_to_add = "set_instance_assignment -name PARTITION wrapper_gen" \
                          " -to FIRs[0].FIRST.wrapper_inst -entity fir_cascade"
    myfile.write('\n' + initial_text_to_add)

    for i in range(1,num_partitions):
        num = str(i)
        text_to_add = "set_instance_assignment -name PARTITION wrapper_gen_" \
                      + num \
                      + " -to FIRs[" \
                      + num \
                      +"].INTERMEDIATE_LAST.wrapper_inst -entity fir_cascade" 
        myfile.write('\n' + text_to_add)

    myfile.close()

def run_multi_seed(projects_directory, module_top_name):
    """
    Runs the command to start Quartus with a tcl script file that runs the design
    through multiple seeds.
    """
    projects_list = os.listdir(projects_directory)
    projects_list.sort()
    i = 1
    for project in projects_list:
#        if (i % 2) == 0:
#            i += 1
#            continue
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


def modify_data_width(project_path, data_width):
    """
    """
    text_to_search  = 'parameter DATA_WIDTH = 17'
    text_to_replace = 'parameter DATA_WIDTH = ' + str(data_width)
    modify_src_parameter(project_path, text_to_search, text_to_replace)

def modify_num_pipeline(project_path, num_pipeline):
    """
    """
    text_to_search  = 'parameter N_STAGES = 0'
    text_to_replace = 'parameter N_STAGES = ' + str(num_pipeline)
    modify_src_parameter(project_path, text_to_search, text_to_replace)

def sweep_data_width(projects_directory, num_pipeline_stages):
    """
    """
    curr_width = START_WIDTH

    projects_list = os.listdir(projects_directory)
    projects_list.sort()
    for project in projects_list:
        
        project_path = projects_directory + '/' + project + '/' + module_top_path

        text_to_search = 'parameter N_FIRs = 1'
        text_to_replace = 'parameter N_FIRs = 2' 
        modify_src_parameter(project_path, text_to_search, text_to_replace)
        
        text_to_search  = 'parameter N_STAGES = 0'
        text_to_replace = 'parameter N_STAGES = ' + str(num_pipeline_stages)
        modify_src_parameter(project_path, text_to_search, text_to_replace)

        text_to_search  = 'parameter DATA_WIDTH = 17'
        text_to_replace = 'parameter DATA_WIDTH = ' + str(2**curr_width)
        modify_src_parameter(project_path, text_to_search, text_to_replace)
        
        curr_width += 1

def sweep_num_pipelines(projects_directory):
    """
    """
    num_pipeline = 0 

    projects_list = os.listdir(projects_directory)
    projects_list.sort()
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

        num_pipeline += 10


def modify_src_parameters(projects_directory, text_to_search, text_to_replace):
    """
    """
    projects_list = os.listdir(projects_directory)
    for project in projects_list:
        for line in fileinput.input(projects_directory + '/' + project + '/' + module_top_path,
                                    inplace=True):
            print(line.replace(text_to_search, text_to_replace), end='')
        fileinput.close()

def parse_data_width_frequencies(projects_directory, num_variables, num_seeds):
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
                    if 'parameter DATA_WIDTH =' in line:
                        num_fir = int(line.split()[3].split(',')[0])

                index = int(math.log(int(num_fir), 2) )- 4
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
                        if 'Slow 900mV 100C Model Fmax Summary' in line and ';' in line:
                            line = next(timing_file_itter)
                            line = next(timing_file_itter)
                            line = next(timing_file_itter)
                            line = next(timing_file_itter)

                            frequency = float(line.split()[1]) #4 for unrestricted
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

    for i in range(NUM_MODULES):#range(NUM_PIPELINES):
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

    for i in range(NUM_PIPELINES):
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

    for i in range(len(frequencies_array)):#NUM_PIPELINES):
        average = 0
        maxx = 0
        total = 0
        for j in range(NUM_SEEDS):
            if frequencies_array[i][j] == 0:
                continue
            if frequencies_array[i][j] > maxx:
                maxx = frequencies_array[i][j]
            average += frequencies_array[i][j]
            total += 1
        if(total == 0):
            total = 1
        average = average / total
        if (i == len(frequencies_array) - 1):#NUM_PIPELINES - 1):
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

    for i in range(NUM_PIPELINES):
        maxx = 0
        for j in range(NUM_SEEDS):
            if frequencies_array[i][j] > maxx:
                maxx = frequencies_array[i][j]
        if (i == NUM_PIPELINES - 1):
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

    for i in range(NUM_PIPELINES):
        minn = 6000
        for j in range(NUM_SEEDS):
            if frequencies_array[i][j] == 0:
                continue
            if frequencies_array[i][j] < minn:
                minn = frequencies_array[i][j]
        if (i == NUM_PIPELINES - 1):
            matlab_file.write(str('{0:.2f}'.format(minn)) + '];')
        else:
            matlab_file.write(str('{0:.2f}'.format(minn)) + ', ')

    matlab_file.write('\n')

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

def sweep_width_and_pipelines(designs, current_project, num_widths, num_pipelines):
    """
    """
    if (True):#not os.path.isdir(designs[0])): # build projects only if they do not exist
        make_design_dirs(designs)
        create_width_and_pipeline_dirs(designs, num_widths, START_WIDTH, num_pipelines, current_project)
        modify_widths_and_pipelines(designs)
        curr_width = START_WIDTH
        for i in range(0, num_widths):
            proc = []
            for j in range(0, len (designs)):
                project_path = designs[j] + '/width_' + str(curr_width)
                p = Process(target=build_projects, args=(project_path, module_top_name))
                p.start()
                proc.append(p)
            for p in proc:
                p.join()
            curr_width = curr_width*2


    curr_width = START_WIDTH
    for i in range(0, num_widths):
        proc = []
        for j in range(0, len (designs)):
            project_path = designs[j] + '/width_' + str(curr_width)
            p = Process(target=run_multi_seed, args=(project_path, module_top_name))
            p.start()
            proc.append(p)
        for p in proc:
            p.join()
        curr_width = curr_width*2


def sweep_pipeline_and_num_module(designs, current_project, num_pipelines, num_modules):
    """
    """
    if (True):#not os.path.isdir(designs[0])): # build projects only if they do not exist
        make_design_dirs(designs)
        create_pipeline_and_num_modules_dirs(designs, num_pipelines, num_modules, current_project)
        modify_pipelines_and_modules(designs)
        curr_pipeline = START_PIP
        for i in range(START_PIP, num_pipelines):
            proc = []
            for j in range(0, len (designs)):
                project_path = designs[j] + '/pipeline_' + str(curr_pipeline)
                p = Process(target=build_projects, args=(project_path, module_top_name))
                p.start()
                proc.append(p)
            for p in proc:
                p.join()
            curr_pipeline = curr_pipeline + 1


    curr_pipeline = START_PIP
    for i in range(START_PIP, num_pipelines):
        proc = []
        for j in range(0, len (designs)):
            project_path = designs[j] + '/pipeline_' + str(curr_pipeline)
            p = Process(target=run_multi_seed, args=(project_path, module_top_name))
            p.start()
            proc.append(p)
        for p in proc:
            p.join()
        curr_pipeline = curr_pipeline + 1

def make_design_dirs(design_dirs):
    """
    """
    for i in range(0, len(design_dirs)):
        if(os.path.isdir(design_dirs[i])):
            continue
        subprocess.call(['mkdir', design_dirs[i]])

def create_pipeline_and_num_modules_dirs(design_dirs,
                                         num_pipelines,
                                         num_modules,
                                         current_project):
    """
    """
    curr_pipeline = 0
    for i in range(0, len(design_dirs)):
        for j in range(0, num_pipelines):
            
            curr_pipeline_dir = design_dirs[i] + '/pipeline_' + str(curr_pipeline)
            print(curr_pipeline_dir)
            curr_pipeline = curr_pipeline + 1
            if(os.path.isdir(curr_pipeline_dir)):
                continue
            subprocess.call(['mkdir', curr_pipeline_dir])
            create_proj_dirs(curr_pipeline_dir, num_modules, current_project)
            
        curr_pipeline = 0

def create_width_and_pipeline_dirs(design_dirs,
                                   num_widths,
                                   start_width,
                                   num_pipelines,
                                   current_project):
    """
    """
    curr_width = START_WIDTH
    for i in range(0, len(design_dirs)):
        for j in range(0, num_widths):
            
            curr_width_dir = design_dirs[i] + '/width_' + str(curr_width)
            print(curr_width_dir)
            curr_width = curr_width*2
            if(os.path.isdir(curr_width_dir)):
                continue
            subprocess.call(['mkdir', curr_width_dir])
            create_proj_dirs(curr_width_dir, num_pipelines, current_project)
            
        curr_width = START_WIDTH

def create_proj_dirs(design_dir, num_projects, current_project):
    """
    """
    for i in range(0, num_projects):
        project_num_prefix = '_'
        if (i < 10):
            project_num_prefix = '_0'
        subprocess.call(['cp', '-r', current_project, design_dir + '/'
                        + current_project + project_num_prefix + str(i)])

def modify_pipelines_and_modules(design_dirs):
    """
    """
    for i in range(0, len(design_dirs)):
        curr_design = design_dirs[i]
        print(curr_design)
        pipeline_list = sorted(os.listdir(curr_design))
        for pipeline in pipeline_list:
            curr_pipeline = int(pipeline.split('_')[-1])
            num_module_list = sorted(os.listdir(curr_design + '/' + pipeline))
            for num_module in num_module_list:
               curr_module = int(num_module.split('_')[-1])*MOD_JUMP_AMT
               if (curr_module == 0):
                   curr_module = 1
               project_path = curr_design + '/' + pipeline + '/' + num_module + '/' + module_top_path

               text_to_search  = 'parameter WRAPPER_TYPE = ""'
               text_to_replace = 'parameter WRAPPER_TYPE = "' + curr_design + '"'
               modify_src_parameter(project_path, text_to_search, text_to_replace)

               text_to_search  = 'parameter N_STAGES = 0'
               text_to_replace = 'parameter N_STAGES = ' + str(curr_pipeline)
               modify_src_parameter(project_path, text_to_search, text_to_replace)
               
               text_to_search = 'parameter N_FIRs = 1,'
               text_to_replace = 'parameter N_FIRs = ' + str(curr_module) + ','
               modify_src_parameter(project_path, text_to_search, text_to_replace)
            
def modify_widths_and_pipelines(design_dirs):
    """
    """
    for i in range(0, len(design_dirs)):
        curr_design = design_dirs[i]
        print(curr_design)
        width_list = sorted(os.listdir(curr_design))
        for width in width_list:
            curr_width = int(width.split('_')[-1])
            pipeline_list = sorted(os.listdir(curr_design + '/' + width))
            for pipeline in pipeline_list:
               curr_pipeline = int(pipeline.split('_')[-1])*PIPE_JUMP_AMT
               if (curr_pipeline == 0):
                   curr_pipeline = 1
               project_path = curr_design + '/' + width + '/' + pipeline + '/' + module_top_path

               text_to_search  = 'parameter WRAPPER_TYPE = ""'
               text_to_replace = 'parameter WRAPPER_TYPE = "' + curr_design + '"'
               modify_src_parameter(project_path, text_to_search, text_to_replace)

               text_to_search  = 'parameter N_STAGES = 0'
               text_to_replace = 'parameter N_STAGES = ' + str(curr_pipeline)
               modify_src_parameter(project_path, text_to_search, text_to_replace)
            
               text_to_search  = 'parameter DATA_WIDTH = 17'
               text_to_replace = 'parameter DATA_WIDTH = ' + str(curr_width)
               modify_src_parameter(project_path, text_to_search, text_to_replace)

def modify_src_parameter(project_path, text_to_search, text_to_replace):
    """
    """
    for line in fileinput.input(project_path, inplace=True):
        print(line.replace(text_to_search, text_to_replace), end='')
    fileinput.close()

def parse_pipeline_and_module_num_frequencies(designs, num_pipelines, num_modules):
    """
    """
    matlab_filename = 'matlab_dat.m'
    matlab_file = open(matlab_filename, 'w')
    curr_pipeline = 0
    for i in range(0, num_pipelines):
        proc = []
        for j in range(0, len (designs)):
            project_path = designs[j] + '/pipeline_' + str(curr_pipeline)
            frequencies = parse_frequencies_from_module_num(project_path, num_modules, NUM_SEEDS)
#            alms_needed, labs_logic, labs_mem, aluts_logic, aluts_route, total_regs, hyper_regs, m20k_block, mlab_mem_bits, block_mem_bits, block_mem_implentation_bits, dsp_blocks = parse_area(project_path, num_pipelines, NUM_SEEDS)

            print_frequencies(project_path, frequencies)
#            print_int_array('ALMs Needed', alms_needed)
#            print_int_array('Logic LABs', labs_logic)
#            print_int_array('Memory LABs', labs_mem)
#            print_int_array('Combinational ALUT usage for logic', aluts_logic)
#            print_int_array('Combinational ALUT usage for route-throughs', aluts_route)
#            print_int_array('Dedicated logic registers', total_regs)
#            print_int_array('Hyper-Registers', hyper_regs)
#            print_int_array('M20K blocks', m20k_block)
#            print_int_array('MLAB memory bits', mlab_mem_bits)
#            print_int_array('Block memory bits', block_mem_bits)
#            print_int_array('Block memory implentation bits', block_mem_implentation_bits)
#            print_int_array('DSP Blocks', dsp_blocks)
            if (not os.path.isdir(project_path)):
                continue
            make_matlab_vectors_avg(matlab_file,
                                    (project_path.replace('/pipeline_', '_')).replace('-','') ,
                                    frequencies)
#            make_matlab_vectors_avg(matlab_file,
#                                    (project_path.replace('/width_', '_')).replace('-','') +
#                                    "_total_regs",
#                                    total_regs)
#            make_matlab_vectors_avg(matlab_file,
#                                    (project_path.replace('/width_', '_')).replace('-','') +
#                                    "_hyper_regs",
#                                    hyper_regs)
        curr_pipeline = curr_pipeline + 1

    matlab_file.close()
def parse_width_and_pipeline_frequencies(designs, num_widths, num_pipelines):
    """
    """
    matlab_filename = 'width_pipeline.m'
    matlab_file = open(matlab_filename, 'w')
    curr_width = START_WIDTH
    for i in range(0, num_widths):
        proc = []
        for j in range(0, len (designs)):
            project_path = designs[j] + '/width_' + str(curr_width)
            frequencies = parse_frequencies(project_path, num_modules, NUM_SEEDS)
            alms_needed, labs_logic, labs_mem, aluts_logic, aluts_route, total_regs, hyper_regs, m20k_block, mlab_mem_bits, block_mem_bits, block_mem_implentation_bits, dsp_blocks = parse_area(project_path, num_pipelines, NUM_SEEDS)

            print_frequencies(project_path, frequencies)
#            print_int_array('ALMs Needed', alms_needed)
#            print_int_array('Logic LABs', labs_logic)
#            print_int_array('Memory LABs', labs_mem)
#            print_int_array('Combinational ALUT usage for logic', aluts_logic)
#            print_int_array('Combinational ALUT usage for route-throughs', aluts_route)
#            print_int_array('Dedicated logic registers', total_regs)
#            print_int_array('Hyper-Registers', hyper_regs)
#            print_int_array('M20K blocks', m20k_block)
#            print_int_array('MLAB memory bits', mlab_mem_bits)
#            print_int_array('Block memory bits', block_mem_bits)
#            print_int_array('Block memory implentation bits', block_mem_implentation_bits)
#            print_int_array('DSP Blocks', dsp_blocks)
            if (not os.path.isdir(project_path)):
                continue
            make_matlab_vectors_avg(matlab_file,
                                    (project_path.replace('/width_', '_')).replace('-','') ,
                                    frequencies)
#            make_matlab_vectors_avg(matlab_file,
#                                    (project_path.replace('/width_', '_')).replace('-','') +
#                                    "_total_regs",
#                                    total_regs)
#            make_matlab_vectors_avg(matlab_file,
#                                    (project_path.replace('/width_', '_')).replace('-','') +
#                                    "_hyper_regs",
#                                    hyper_regs)
        curr_width = curr_width*2

    matlab_file.close()
    
def parse_frequencies_from_module_num(projects_directory, num_variables, num_seeds):
    """
    """
    frequencies = [[0 for x in range(num_seeds)] for y in range(num_variables)]
    try:
        projects_list = os.listdir(projects_directory)
        for project in projects_list:
            try:
                src_file = open(projects_directory + '/' + project + '/' + module_top_path)
                num_pipe = 0
                for line in src_file:
                    if 'parameter N_FIRs = ' in line:
                        num_pipe = int(line.split()[3].split(',')[0])

                if (num_pipe == 1):
                    index = 0
                else:
                    index = int(num_pipe/MOD_JUMP_AMT)
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
                        if 'Model Fmax Summary' in line and ';' in line and '100C' in line and 'vid' not in line:
                            line = next(timing_file_itter)
                            line = next(timing_file_itter)
                            line = next(timing_file_itter)
                            line = next(timing_file_itter)

                            frequency = float(line.split()[4]) # 1 for unrestricted
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

def parse_frequencies(projects_directory, num_variables, num_seeds):
    """
    """
    frequencies = [[0 for x in range(num_seeds)] for y in range(num_variables)]
    try:
        projects_list = os.listdir(projects_directory)
        for project in projects_list:
            try:
                src_file = open(projects_directory + '/' + project + '/' + module_top_path)
                num_pipe = 0
                for line in src_file:
                    if 'parameter N_OUTPUT_REG=' in line:
                        num_pipe = int(line.split()[2].split(',')[0])
                    elif 'parameter N_STAGES =' in line:
                        num_pipe = int(line.split()[3].split(',')[0])
                    elif 'parameter N_RELAY_STATIONS=' in line:
                        num_pipe = int(line.split()[2].split(',')[0])

                index = int(num_pipe/PIPE_JUMP_AMT)
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
                        if 'Model Fmax Summary' in line and ';' in line and '100C' in line and 'vid' not in line:
                            line = next(timing_file_itter)
                            line = next(timing_file_itter)
                            line = next(timing_file_itter)
                            line = next(timing_file_itter)

                            frequency = float(line.split()[4]) # 1 for unrestricted
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

def parse_area(projects_directory, num_variables, num_seeds):
    """
    """
    # arrays to be used for parsed resutls
    alms_needed   = [[0 for x in range(num_seeds)] for y in range(num_variables)]
    labs_logic    = [[0 for x in range(num_seeds)] for y in range(num_variables)] 
    labs_mem      = [[0 for x in range(num_seeds)] for y in range(num_variables)] 
    aluts_logic   = [[0 for x in range(num_seeds)] for y in range(num_variables)] 
    aluts_route   = [[0 for x in range(num_seeds)] for y in range(num_variables)] 
    total_regs    = [[0 for x in range(num_seeds)] for y in range(num_variables)] 
    hyper_regs    = [[0 for x in range(num_seeds)] for y in range(num_variables)]
    m20k_block    = [[0 for x in range(num_seeds)] for y in range(num_variables)]
    mlab_mem_bits = [[0 for x in range(num_seeds)] for y in range(num_variables)]
    block_mem_bits= [[0 for x in range(num_seeds)] for y in range(num_variables)]
    block_mem_implentation_bits = [[0 for x in range(num_seeds)] for y in range(num_variables)]
    dsp_blocks    = [[0 for x in range(num_seeds)] for y in range(num_variables)]

    projects_list = os.listdir(projects_directory)
    for project in projects_list:
        try:
            src_file = open(projects_directory + '/' + project + '/' + module_top_path)
            num_fir = 0
            for line in src_file:
                if 'parameter N_STAGES =' in line:
                    num_pipe = int(line.split()[3].split(',')[0])

            index = int(num_pipe/PIPE_JUMP_AMT)
            src_file.close()

            seed_num = 0
            seed_rpt_list = os.listdir(projects_directory + '/' + project + '/seed_rpt')
            for fitter_rpt in seed_rpt_list:
                if '.fit.rpt' not in fitter_rpt:
                    continue # not a fitter file
                fitter_file = open(projects_directory + '/' + project + '/seed_rpt/' + fitter_rpt,
                              encoding = 'ISO-8859-1')
                fitter_file_itter = iter(fitter_file)
                is_fitter_report = False
                for line in fitter_file_itter:
                    if '; Fitter Resource Usage Summary' in line:
                        is_fitter_report = True
                    if 'ALMs needed [=A-B+C]' in line and is_fitter_report:
                        num_alms = int(float(line.split()[5].replace(',', '')))
                        alms_needed[index][seed_num] = num_alms
                    if 'Logic LABs' in line and is_fitter_report:
                        num_logic_labs = int(line.split()[5].replace(',', ''))
                        labs_logic[index][seed_num] = num_logic_labs
                    if 'Memory LABs' in line and is_fitter_report:
                        num_mem_labs = int(line.split()[11].replace(',', ''))
                        labs_mem[index][seed_num] = num_mem_labs
                    if 'Combinational ALUT usage for logic' in line:
                        num_aluts_for_logic = int(line.split()[7].replace(',', ''))
                        aluts_logic[index][seed_num] = num_aluts_for_logic
                    if 'Combinational ALUT usage for route-throughs' in line:
                        num_aluts_for_route = int(line.split()[7].replace(',',''))
                        aluts_route[index][seed_num] = num_aluts_for_route
                    if 'Dedicated logic registers' in line:
                        num_logic_registers = int(line.split()[5].replace(',', ''))
                        total_regs[index][seed_num] = num_logic_registers
                    if '-- Hyper-Registers:' in line:
                        num_hyper_regs = int(line.split()[4].replace(',',''))
                        hyper_regs[index][seed_num] = num_hyper_regs
                    if 'M20K block' in line and is_fitter_report:
                        num_m20k = int(line.split()[4].replace(',', ''))
                        m20k_block[index][seed_num] = num_m20k
                    if 'Total MLAB memory bits' in line:
                        num_mlab_mem_bits = int(line.split()[6].replace(',',''))
                        mlab_mem_bits[index][seed_num] = num_mlab_mem_bits
                    if 'Total block memory bits' in line: 
                        num_block_mem_bits = int(line.split()[6].replace(',',''))
                        block_mem_bits[index][seed_num] = num_block_mem_bits
                    if 'Total block memory implentation bits' in line:
                        num_block_mem_implentation_bits = int(line.split()[6].replace(',',''))
                        block_mem_implentation_bits[index][seed_num] = num_block_mem_implentation_bits
                    if 'Total DSP Blocks' in line and is_fitter_report:
                        num_dsp = int(line.split()[5].replace(',', ''))
                        dsp_blocks[index][seed_num] = num_dsp
                        break #always the last line needed to be parsed in the file

                seed_num += 1
                fitter_file.close()

        except FileNotFoundError:
            pass #Dismiss the non-created varibles inorder to view the generated ones

    return alms_needed, labs_logic, labs_mem, aluts_logic, aluts_route, total_regs, hyper_regs, m20k_block, mlab_mem_bits, block_mem_bits, block_mem_implentation_bits, dsp_blocks

def print_frequencies(array_name, frequencies_array):
    """
    """
    if len(frequencies_array) <= 1 :
        return

    print(array_name)
    print()

    for i in range(NUM_MODULES):#range(NUM_PIPELINES):
        average = 0
        num_to_average = 0
        num_pipelines = i * MOD_JUMP_AMT#PIPE_JUMP_AMT

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

    for i in range(NUM_PIPELINES):
        average = 0
        num_to_average = 0

        num_firs = i

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


def main(argv):

    global current_project
    global module_top_name
    global module_top_path
    global sdc_file_name
    global CREATE_PROJ_TCL

    module_top_name = 'fir_cascade'
    module_top_path = 'hdl/top/fir_cascade.sv'
#    CREATE_PROJ_TCL = '../../scripts/tcl/create_proj_stratix10_par.tcl'
    CREATE_PROJ_TCL = '../../scripts/tcl/create_proj_stratix10.tcl'
#    current_project = 'fir_all_wrappers_no_reset_src'
    
# arria 10 tcl file
#    CREATE_PROJ_TCL = '../../scripts/tcl/create_proj_arria10_par.tcl'
#    CREATE_PROJ_TCL = '../../scripts/tcl/create_proj_arria10.tcl'
#    current_project = 'fir_all_wrappers'

    current_project = 'fir_all_wrappers_qsys'
#    current_project = 'fir_all_wrappers_credit'
#    designs = ['qsys']
#    designs = ['carloni', 'non-li', 'credit']
#    designs = ['credit']
    designs = ['credit', 'carloni', 'non-li', 'qsys']
#    sweep_width_and_pipelines(designs, current_project, NUM_WIDTHS, NUM_PIPELINES)
#    parse_width_and_pipeline_frequencies(designs, NUM_WIDTHS, NUM_PIPELINES)

#    sweep_pipeline_and_num_module(designs, current_project, NUM_PIPELINES, NUM_MODULES)
    parse_pipeline_and_module_num_frequencies(designs, NUM_PIPELINES, NUM_MODULES)

# use: import module_name; module_name.main() to execute main func in another script
if __name__ == "__main__":
    main(sys.argv)
