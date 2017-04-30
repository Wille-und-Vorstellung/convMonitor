'''
Mk05_RogueOne
DESC:
    After the excution of Mk05_pyBoost, procedes to extract rogue particles 
through given criteria and interval
Input:
    1. statisticMk05.dat( input )
    2. interval (of oscilation)
    3. maximum oscilation( used to filter out rogue ones )
Output:
    1. RoguePartiles_MkXX.star
    2. XXX_RogueOne_Mk0X.log
MISC:

'''
__author__ = 'Ruogu Gao'


import os
import sys
import math
import logging
import time
from functools import reduce
import numpy as np
import matplotlib.pyplot as plt
#import ConvMonitor_Relion_Mk05_pyBoost  as pyBoost
#Macros
THIS_PROGRAM = 'RogueOne'
VERSION = 'Mk06'
LOG_NAME = VERSION + '_' +THIS_PROGRAM + '.log'
logging.basicConfig(filename=LOG_NAME, level=logging.DEBUG)

def _RogueOne(  ):
    print('/> Let\'s get down to business.')
    trend = _loadData()

    flag = input( 'skip load-n-plot(*/n)?:' )
    if( flag == 'n' or flag == 'N' ):
        trend = _loadData()
        _shiftPlot( trend )
    
    flag = 'n'
    flag = input('Extract(y/n)?:')
    if ( flag == 'y' or flag == 'Y' ):
        print('/> Proceed to rogue extraction.')
        print('/> //please make sure input sample file be correct, doing otherwise at your own peril.')
    else:
        print('/> Terminating...')
        return 0
    
    sample_file = input('.star file: ')
    thres = input( 'threshold: ' )
    pivot = input( 'pivot: ' )
    tc = input( 'Target column of class N(mis-input at you peril~):' )
    #print( tc )
    black_list = _oscillationCount( int(pivot), trend )
    #print( 'black_list: '+str( black_list ) )
    rogues, head_l, unstable_C = _rogueExtract( int(thres), black_list, sample_file, int(tc) )
    _prudentExtract( rogues, sample_file, head_l )

    #print unstable classes
    print('Unstable classes:')
    print( str(unstable_C) )

    return 117


def _shiftPlot( dat_matrix ):
    #count and plot class-shift occured in every other iteration
    shift_list = [0 for i in range( len(dat_matrix) -1 )]
    
    for i in range( 1, len(dat_matrix) ):
        for j in range( len(dat_matrix[0]) ):
            if ( dat_matrix[i][j] != dat_matrix[i-1][j] ):
                shift_list[i-1] += 1
    
    logging.info(shift_list)

    #plot with matplotlib
    plt.xlabel('Iterations')
    plt.ylabel('class shift')
    plt.title('Paritcle Oscillation')
    plt.bar( np.arange(len(shift_list)), shift_list, width=1 )
    plt.plot( np.arange(len(shift_list)), shift_list, 'g--' )
    plt.draw()
    plt.show()

    return 0

def _loadData():
    ##read input and .dat files
    dat_f = input('.dat file: ')
    with open( dat_f, 'r' ) as dat_x:
        dat_lines = dat_x.readlines()
    
    row_n = len(dat_lines)
    col_n = len(dat_lines[0].split())
    #result: iter_N X particle_N 
    result = [ [ 0 for col in range(col_n) ] for row in range(row_n) ]

    for i in range( len( dat_lines ) ):
        temp_line = dat_lines[i].strip().split()
        result[i] = temp_line[0:]

    dat_x.close()
    return result

def _oscillationCount( pivot, dat_matrix ):
    #count the oscillation N of every partilce in given interval
    #marginal check
    if ( pivot >= len(dat_matrix) or pivot < 0 ):
        logging.info("_oscillationCount> input pivot out of range")
        return [1]
    result = [0 for i in range( len( dat_matrix[0] ) )]

    for i in range( pivot, len( dat_matrix ) ):
        for j in range(1, len(result) ):
            #NOTICE here, that the first slot of *.dat, thus dat_matrix[*][0], is the line nmber - 1, which is tailered for GNUPLOT scripts therefore should not be regarded as particle class numbers 
            if ( dat_matrix[i-1][j] != dat_matrix[i][j] ):
                    result[j] += 1

    return result

def  _rogueExtract( thres, black_list, sample, TARGET_COLUMN ):
    
    with open( sample, 'r' ) as sample_:
            sample_dat = sample_.readlines()

    rogue_particle = []
    for i in range( len(black_list) ):
        if ( black_list[i] > thres ):
            rogue_particle.append(i)

    head_l = 0
    for i in range(len(sample_dat)):
        temp = sample_dat[i].strip().split()
        if ( len(temp) > 2 ):
            head_l = i
            break
    '''
    print("tc = " + str( TARGET_COLUMN ) )
    print("h_l = " + str( head_l ) )
    print( rogue_particle )
    '''
    unstable_class = []
    temp_str = ''
    temp_row = 0
    o_file = open('RogueOnes_in_'+sample+'.star', 'w')
    for j in range( head_l + len(rogue_particle) ):
        
        if ( j < head_l ):
            o_file.write( sample_dat[j] )
        else:
            temp_row = int( rogue_particle[j-head_l] ) + head_l
            #NOTICE here, the rogue_particle only record the number of rogue particles, which is the row number of that particles in *_data.star files minus the head length( under such knowledge that the particle and it's line in star file is the same in all *_data.star files of the same process of Relion  )
            o_file.write( sample_dat[temp_row] )
            #print( '> ' + str(j)  +' - '+ str(temp_row) )
            #print( '$ ' + sample_dat[temp_row] )
            temp_str = sample_dat[temp_row].strip().split()[TARGET_COLUMN-1] #the array starts from 0, FYI 
            unstable_class.append( temp_str )

    o_file.close()
    sample_.close()

    uc = []
    for i in unstable_class:
        if ( not ( i in uc) ):
            uc.append(i)

    return rogue_particle, head_l, uc

def _prudentExtract( rogues, sample, head_l ):
    with open( sample, 'r' ) as sample_:
            sample_dat = sample_.readlines()

    o_file = open('Prudents_of_'+sample+'.star', 'w')
    for j in range( len(sample_dat) ):
        if ( j < head_l ):
            o_file.write( sample_dat[j] )
        elif (  not any( j - head_l == k for k in rogues)  ):
            o_file.write( sample_dat[j] )

    o_file.close()
    sample_.close()

    return 0


if __name__ == '__main__':
    _RogueOne()
    print(VERSION)
    exit(0)



