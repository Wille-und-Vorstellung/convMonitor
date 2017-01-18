####################################################
#Mk05: 2D-classification + additonal analysis & plot + track
#Input parameter:                                   
#   1.the number of classes;                                                
#   2.number of particles to be monitored;              
#   3..all those star files;like "manual_it???_data.star"           
#Log files:                                     
#   1.MkXX.log                                  
#   //2.testLog.log                                   
#Output:                                        
#   1.statisticMk0X.dat                             
#   2.RogueParticles.star                               
#   3.PrudentParticles.star                             
#   4.AnalysisPlus.dat                              
####################################################
#Macros and conventions:                                
#   1.HEADERL                                   
#   2.TCOLUMN                                   
#   3.PARAMETERN                                
#   4.EXTRACTN                                  
#   5.VASTART                                   
#   6.VAEND                                 
#   7.INC, column number of  _rlnImageName                  
#   8.CXC, column number of  _rlnCoordinateX                     
#   9.CYC, column number of  _rlnCoordinateY                     
#   10.MNC, column number of  _rlnMicrographName                 
#   11.CNC, column number of  _rlnClassNumber                
#   12._NCC, ~ _rlnNormCorrection                
#   13.LLCC, ~ _rlnLogLikeliContribution        
#   14.MVPDC, ~ _rlnMaxValueProbDistribution    
#   15.NSSC, ~ _rlnNrOfSignificantSamples       
####################################################
__author__ = 'Ruogu Gao'
'''
GLOBAL_ACCESS_ALERT:
    1. all upper class Macros

'''
import sys
import os
import math
import logging
import time
import numpy as np
import matplotlib.pyplot as plt
from multiprocessing import Pool
from multiprocessing import Process
from multiprocessing import cpu_count
from functools import reduce
#MACROs
THIS_PROGRAM    = 'ConvMonitor'
VERSION         = 'MK05'
CONF_FILE       = THIS_PROGRAM + '_' + VERSION + '.conf'
STAT_FILE       = 'Migration' + '_' + VERSION + '.dat'

PROC_UPPER = 32
PROC_LOWER = 1
'''
EXTRACTN=100
HEADERL=28
TCOLUMN=20
INC=10      #_rlnImageName #10
CXC=11      #_rlnCoordinateX #11 
CYC=12      #_rlnCoordinateY #12 
MNC=13      #_rlnMicrographName #13 
CNC=20      #_rlnClassNumber #20  //hazard?(there was once 14)
NCC=21      #_rlnNormCorrection #21
LLCC=22     #_rlnLogLikeliContribution #22 
MVPDC=23    #_rlnMaxValueProbDistribution #23 
NSSC=24     #_rlnNrOfSignificantSamples #24 
TEST_FLAG=0
'''
logging.basicConfig( filename = VERSION + '.log', level = logging.DEBUG )

def _DataLoader():
    ##through a conf file to access those MACROS
    try:
        f = open( CONF_FILE, 'r' )
    except :
        return ( 'Invalid file path' )

    conf = f.readlines()
    global process_N, pool_size, EXTRACTN, HEADERL, CNC, NCC, LLCC, MVPDC, NSSC, TEST_FLAG

    process_N   = int(conf[1].strip().split(' ')[1] )
    pool_size   = int(conf[2].strip().split(' ')[1] )
    EXTRACTN    = int(conf[3].strip().split(' ')[1] ) #100
    HEADERL     = int(conf[4].strip().split(' ')[1] ) #28 
    CNC         = int(conf[5].strip().split(' ')[1] ) #20 #_rlnClassNumber #20  
    NCC         = int(conf[6].strip().split(' ')[1] ) #21 #_rlnNormCorrection #21
    LLCC        = int(conf[7].strip().split(' ')[1] ) #22 #_rlnLogLikeliContribution #22 
    MVPDC       = int(conf[8].strip().split(' ')[1] ) #23 #_rlnMaxValueProbDistribution #23 
    NSSC        = int(conf[9].strip().split(' ')[1] ) #24 #_rlnNrOfSignificantSamples #24 
    TEST_FLAG   = int(conf[10].strip().split(' ')[1] )

    logging.info( 'Waypoint/> ' + 'conf reading done, T_column ' + str( CNC ) )
    ##para-checker
    if ( process_N > PROC_UPPER or process_N < PROC_LOWER ):
        logging.info('Invalid process number.')
        exit(1)
    if ( process_N > cpu_count() or process_N < 0 ):
        logging.info('Invalid pool size.')
        exit(2)

    ##input files 
    #file_N = len(sys.argv)-1
    file_list = []
    for i in range( 1, len(sys.argv) ):
        file_list.append( str( sys.argv[i] ) )

    ##oganize output bundle
    result_bundle = ( file_list, process_N, pool_size, (HEADERL, CNC, NCC, LLCC, MVPDC, NSSC) )

    return result_bundle


def _TaskSplitter( file_list, piece_N, paraMs ):
    file_N = len(file_list)
    if ( len(file_list) < piece_N ):
        logging.info( 'Gentlemen, please make sure that the number of files are LARGER than the processes expected to ultilise, otherwise all those effort would be for nothing.' )
        exit(3)
    piece_length = file_N//piece_N

    re_list = []
    for index in range(piece_N-1):
        re_list.append( (index, [1,2], [], paraMs) )
        re_list[index][1][0] = index*piece_length
        re_list[index][1][1] = (index+1)*piece_length
        #re_list.append( ( index, index*piece_length, (index+1)*piece_length ) )
        for j in range( index*piece_length, (index+1)*piece_length ):
            re_list[index][2].append( file_list[j] )

    #re_list.append( ( (piece_N-1), (piece_N-1)*piece_length, file_N ) ) #the last entry
    re_list.append( (piece_N-1, [1,2], [], paraMs) )
    re_list[piece_N-1][1][0] = (piece_N-1)*piece_length
    re_list[piece_N-1][1][1] = file_N
    for j in range( (piece_N-1)*piece_length, file_N ):
        re_list[piece_N-1][2].append( file_list[j] )

    #returns a list consiting of tuples like( sequence_N, start_file, end_file ), indicating a interval closed at the left.
    return re_list


def _StandAloneModule( in_bundle ):
    #read seperate parts respectively
    sequence_N = in_bundle[0]
    files = in_bundle[2]
    interval = in_bundle[1]
    paraMs = in_bundle[3]
    logging.info("Waypoint/> process_{0} running...".format(os.getpid()))
    #HEADERL, CNC, NCC, LLCC, MVPDC, NSSC
    _HEADERL = paraMs[0]
    _NCC = paraMs[2]
    _CNC = paraMs[1]
    _NSSC = paraMs[5]
    _MVPDC = paraMs[4]
    _LLCC = paraMs[3]
    #TAKE NOTE:  [[0 for col in range(n)] for row in range(n)] to organise lists as matrix
    #and the following result is actually a tensor...
    file_buffer = open( files[0], 'r' )
    data_buffer = file_buffer.readlines()
    row_L = len(data_buffer) - _HEADERL
    col_L = len(files)
    logging.info("Waypoint/process_{0}/>file_list:{1}, row:{2}, col:{3}, header_length:{4}, CNC:{5}".format(os.getpid(), str(files), row_L, col_L, int(_HEADERL), int(_CNC)))

    result = (  [[0 for col in range(col_L)] for row in range(row_L)], \
                [[0 for col in range(col_L)] for row in range(row_L)], \
                [[0 for col in range(col_L)] for row in range(row_L)], \
                [[0 for col in range(col_L)] for row in range(row_L)], \
                [[0 for col in range(col_L)] for row in range(row_L)], \
             ) #class, NC, NSS, MVPD, LLC  //////////////////////// POTENTIAL-HAZARD
    for i in range( len(files) ):
        #open file
        file_buffer = open( files[i], 'r' )
        data_buffer = file_buffer.readlines()
        #extract target fields
        #logging.info( "Waypoint/process_{0}/>file:{1}, row:{2}, col:{3}, cnc:{4}".format(os.getpid(), str(files[i]), len(data_buffer) - _HEADERL, len(files), _CNC ))
        for j in range( _HEADERL ,len(data_buffer) ): #NOTE: here we assume that particle number differs not between files
            #logging.info('closing-in/{0}/>( {1}, {2}) while ( {3}, {4})'.format( os.getpid(), j-_HEADERL, i, row_L, col_L ))
            #logging.info( ' additional/{0}/>{1}-{2}--{3}, while-{4}'.format(os.getpid(), j-_HEADERL, i, _CNC-1, len( data_buffer[j].strip().split(' ') )))
            result[0][j-_HEADERL][i] = data_buffer[j].strip().split()[_CNC-1]
            logging.info('closing-in/{0}/>step_1, i = {1}, j = {2}, readin: {3}'.format(os.getpid(), i,j, result[0][j-_HEADERL][i] ))
            result[1][j-_HEADERL][i] = data_buffer[j].strip().split()[_NCC-1]
            #logging.info('closing-in/{0}/>step_2, i = {1}, j = {2}'.format(os.getpid(), i,j))
            result[2][j-_HEADERL][i] = data_buffer[j].strip().split()[_NSSC-1]
            #logging.info('closing-in/{0}/>step_3, i = {1}, j = {2}'.format(os.getpid(), i,j))
            result[3][j-_HEADERL][i] = data_buffer[j].strip().split()[_MVPDC-1]
            #logging.info('closing-in/{0}/>step_4, i = {1}, j = {2}'.format(os.getpid(), i,j))
            result[4][j-_HEADERL][i] = data_buffer[j].strip().split()[_LLCC-1]

        file_buffer.close()

    logging.info("Waypoint/> process_{0} finishing off...".format(os.getpid()))
    
    return result


def _Merge( raw_1, raw_2 ):
    #sequence_N = raw_1(so it seems that we dont need sequence ID to guide the merge process...)
    for n in range(5): #5 statistic attributes
        for i in range( len(raw_2[n]) ): #raw_1 and raw_2 are supposed to be the same
            for j in range( len(raw_2[n][0]) ):
                #raw_1[n][i][j+len(raw_1[n][0])] = raw_2[n][i][j]
                raw_1[n][i].append( raw_2[n][i][j] )

    return raw_1


def _PostProcess( to_write ):
    #
    logging.info('Waypoint/postprocess/> ' + str( to_write ))
    w_file = open( STAT_FILE, 'w')
    for i in range( len(to_write) ):
        temp=''
        for j in range( len(to_write[0]) ):
            temp += str( to_write[i][j] ) + ' '
        w_file.write( temp[:-1] + '\n' )

    w_file.close()
    return 0


def _AdditionalAnalysis( trend ):
    #
    tlength = len(trend)
    #ph: might need to convrt str->int manually
    plt.plot( range(tlength), trend )

    plt.savefig( VERSION + '_migration_trend' +'.png')
    return 0


def main():
    ####general read-in     
    ####@_DataLoader()
    start_t = time.time()
    f_input = _DataLoader()
    file_list = f_input[0]
    process_N = f_input[1]
    pool_size = f_input[2]
    macro_parameters = f_input[3]

    ####task split
    ####@_TaskSplitter
    task_bundle = _TaskSplitter( file_list, process_N, macro_parameters )

    ####Pool-party !!!
    logging.info( 'Waypoint/> _TaskSplitter done: ' + str(task_bundle) )

    work_pool = Pool(pool_size)
    tobe_merged = work_pool.map(_StandAloneModule, task_bundle )
    
    logging.info( "Waypoint/> " + 'joined' )

    ####merge manually(avoid using anything potemtially volitile shared memory)
    ####@_Merge()
    #merged_task = _Merge( tobe_merged ) #note here that the tobe_merged should be a list
    merged_task = reduce( _Merge, tobe_merged )

    ####finish off the business: write the merged into disk(those statistic files)
    ####@_PostProcess()
    _PostProcess( merged_task[0] )

    end_t = time.time()

    logging.info( "Waypoint/> " + 'file operation done, time consumption: ' + str( end_t - start_t )  )
    ####Additional analysis, including plotting with GNUPLOT and extract rogue/prudent particles(need additional input parameters)
    ####@_AdditionalAnalysis()
    _AdditionalAnalysis( merged_task[0] )

    ####Advanced: mining patterns from NC, NSS, MVPD, LLC etc.
    ####@another program

    return ('All clear', 117)

if __name__ == '__main__':
    flag = main()
    print("terminating: {0}/{1}".format(flag[0], flag[1]))
 