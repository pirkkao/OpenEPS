import numpy as np
import sys

# calculate scores as root mean squared error (RMSE)
# based on this https://en.wikipedia.org/wiki/Root-mean-square_deviation
# output in scores_pert.dat (format?)

# Input: x_truth_file, x_model_file, t_truth_file, t_model_value (time multiplied by 100)
# Output: scores_pert.dat (output in the same folder as executed)


#command line arguments:
x_truth_file = sys.argv[1] # should be given as a string, ex. 'l95truth.dat', path to true data file
x_model_file = sys.argv[2] # same format as above, path to file containg model data
t_truth_file = sys.argv[3] # path to file containg true data time vector
t_model_value = sys.argv[4] # time value of model, i.e. time corresponding to last output "day", note it is multiplied by 100

# read in truth to matrix
x_truth = np.loadtxt(x_truth_file)
# read in modelled data to matrix
x_model = np.loadtxt(x_model_file)
# read in true time vector
t_truth = np.loadtxt(t_truth_file)
# convert t_model to float, divide by 100
t_model = float(t_model_value)/100


K = np.shape(x_model[0,:])

# find index in t_truth vector, that corresponds to t_model time, np.argwhere returns a vector of indices corr. to that value, 0 grabs the first index.
t_truth_index = np.argwhere(t_truth == t_model)[0]

# model index = index corresponding to last time step, i.e. last row 
t_model_index = -1 

# RMSE calculation at model's last output time, compared to true data corresponding to the same "day" 
rmse = np.sqrt((np.sum(np.square(x_truth[t_truth_index, :] - x_model[t_model_index, :])))/K)

# save rmse value to file 
np.savetxt('scores_pert.dat', rmse, fmt='%.10f')    

# END OF FILE
