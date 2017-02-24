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
import matplotlib as plt
import ConvMonitor_Relion_Mk05_pyBoost  as pyBoost
#Macros
THIS_PROGRAM = 'RogueOne'

logging.basicConfig(filename=pyBoost.VERSION + '_'+THIS_PROGRAM+'.log', \
level=logging.DEBUG)

def _RogueOne(  ):
    print('I ain\'t done nothing yet...')
    trend = _loadData()
    
    pass
    return 117


def _shiftPlot():
    #count and plot class-shift occured in every other iteration
     
    pass

def _loadData():
    ##read input and .dat files
    dat_f = input('.dat file: ')
    with open( 'dat_f', 'r' ) as dat_x:
        dat = dat_x.readlines()
    
    col_n = len(dat)
    row_n = len(dat[0].split()) - 1
    #result: particle_N X iter_N
    result = [ [ 0 for col in range(col_n) ] for row in range(row_n) ]

    
    return result

def _ocsilationCount():
    #count the ocsilation N of every partilce in given interval
    pass


def  _rogueExtract():

    pass
    
if __name__ == '__main__':
    _RogueOne()
    print(pyBoost.VERSION)
    exit(0)



