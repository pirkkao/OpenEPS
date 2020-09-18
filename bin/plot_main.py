#
#
#

import plot_modules as mo

import cartopy.crs as ccrs
import sys

date="2016120100"

# Overwrite if command line arguments given
if len(sys.argv)>1:
    date=str(sys.argv[1])

filepath="data/"+date+"/"

filename1=filepath+"PP_ctrl.nc"
filename2=filepath+"PP_ensmean.nc"
filename3=filepath+"PP_ensstd.nc"

fig_name="quick_look_"+date

# Variables to be plotted
plot_vars=[]
plot_vars.append({
    'vars':['T'],
    'levs':True,
    'nlevs':[1], # 2nd level in nc-file
})
plot_vars.append({
    'vars':['T2M'],
    'levs':False,
})
plot_vars.append({
    'vars':['Z'],
    'levs':True,
    'nlevs':[0],
    })
plot_vars.append({
    'vars':['MSL'],
    'levs':False,
    })

# Setup plotting options
plot_dict={
    'fcsteps':[0,1,2,3],
    'fig_c_col' :'blue',
    'fig_c_levs':16,
    'fig_cf_levs':16,
    'fig_ens_cols':5,
    'fig_ens_scaling':5., # this number * stddev
    'fig_ncol':2,
    'fig_nrow':4,
    'fig_size':(26,24), # 8 plots
    'fig_proj':ccrs.PlateCarree()
}
# Some other predefined configurations
if len(plot_vars)==1:
    plot_dict.update({'fig_size':(16,14),\
                      'fig_ncol':1,\
                      'fig_nrow':2}
    )
    
elif len(plot_vars)==2:
    plot_dict.update({'fig_size':(26,12),\
                      'fig_ncol':2,\
                      'fig_nrow':2}
    )

# Get all data
data=[]
for plot_var in plot_vars:
    data.append(mo.get_data(filename1,plot_var))
    data.append(mo.get_data(filename2,plot_var))
    data.append(mo.get_data(filename3,plot_var))

# Call plotting
mo.plot_master(data,fig_name,plot_vars,plot_dict)
