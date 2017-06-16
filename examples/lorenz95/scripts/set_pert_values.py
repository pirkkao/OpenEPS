import numpy as np
import sys
from random import normalvariate as rndm

# read in ctrl data,(size: NSTATES x 1),add noise to get pertrurbed values
# inputs: path to ctrl data, 
# output: s0file.dat = control data (ctrl_file) + random noise, N(0, sigma_pert^2) (in the same folder as script is executed)

# inputs:
ctrl_file = sys.argv[1] # file that contains true data
sigma_pert = sys.argv[2] # sigma of perturbation noise

# convert to float
sigma_pert = float(sigma_pert)

# load true data
ctrl_data = np.loadtxt(ctrl_file)

# define K = no. of states
K = np.size(ctrl_data)

# define an_data vector Kx1 
pert_data = np.zeros(K)

# pert_data = ctrl_data + noise (random number)
for i in range(K):
    pert_data[i] = ctrl_data[i] + rndm(0,sigma_pert)
    
# save output to file
np.savetxt('s0file.dat', pert_data, fmt='%.10f')

# END OF FILE
