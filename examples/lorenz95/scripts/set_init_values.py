import numpy as np
import sys
from random import normalvariate as rndm

# read in true data at time index t_index, add noise to get initial value for model
# inputs: path to true data, time index, sigma_an
# output: s0file.dat = "analysed data" = truth + noise, noise ~ N(0,sigma_an^2) (output in the same folder as script is executed)

# inputs:
truth_file = sys.argv[1] # file that contains true data
t_index = sys.argv[2] # index for time t
sigma_an = sys.argv[3] # sigma for analysis

# convert t_index to integer
t_index = int(t_index)
# convert sigma_an to float
sigma_an = float(sigma_an)

# load true data
truth_data = np.loadtxt(truth_file)
# define K = no. of states
K = np.size(truth_data[t_index, :])

# define an_data vector 
an_data = np.zeros(K)

# an_data = truth_data[t_index, :] + noise (random number)
for i in range(K):
    an_data[i] = truth_data[t_index, i] + rndm(0,sigma_an)

# save output to file
np.savetxt('s0file.dat', an_data, fmt='%.10f')

# END OF FILE
