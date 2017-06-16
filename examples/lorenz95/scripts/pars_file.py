import numpy as np
import sys

# split one parameter file (NENS x NPARS) to a NENSx1 file

# Input: file that contains all parameters .dat file (NENSxNPARS), row number (=ensemble member number)
# Output: gupars.dat, contains only one row of parameters, output in the same folder as script is executed
# run file: python pars_file.py file.dat 1

# read in variables
var_file = sys.argv[1] # original file
var_row = sys.argv[2] # row number
file_orig = np.loadtxt(var_file)

# convert variable var_row to integer and substract 1 (python indexing starts from 0)
var_row = int(var_row) - 1 

# put value from file_orig on line var_row into new gupars.dat file:
np.savetxt('gupars.dat', file_orig[var_row,:], fmt='%.10f')

# END OF FILE
