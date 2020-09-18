
from __future__ import print_function
import numpy as np
import xarray as xr
import os
import copy

import matplotlib.pyplot as plt
#import xarray as xr
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import cartopy.io.shapereader as shapereader
import seaborn as sns
#import shapely.geometry as sgeom
#from shapely.geometry import Point
#from datetime import datetime,timedelta
#from matplotlib.colors import ListedColormap
#from matplotlib.lines import Line2D as Line
#from matplotlib import cm
from matplotlib.backends.backend_pdf import PdfPages
#from tkinter import *


def get_data(data_path,plot_vars):
    "Open NetCDF file containing data"

    with xr.open_dataset(data_path) as ds:

        # Get variable gribtable name
        item=plot_vars['vars'][0]

        if item=='Z'  : item2='var129'
        if item=='T'  : item2='var130'
        if item=='U'  : item2='var131'
        if item=='V'  : item2='var132'
        if item=='Q'  : item2='var133'
        if item=='VO' : item2='var138'
        if item=='D'  : item2='var155'
            
        if item=='10m gust (3h)'   : item2='var28'
        if item=='10m gust (inst)' : item2='var29'
        if item=='CAPES' : item2='var44'
        if item=='CAPE'  : item2='var59' 
        if item=='TCW'   : item2='var136'
        if item=='MSL'   : item2='var151'
        if item=='TCC'   : item2='var164'
        if item=='U10M'  : item2='var165'
        if item=='V10M'  : item2='var166'
        if item=='T2M'   : item2='var167'
        if item=='D2M'   : item2='var168'
        if item=='TP'    : item2='var228'
        if item=='TP3'   : item2='var228'
        if item=='TP6'   : item2='var228'
        if item=='TP12'  : item2='var228'
        if item=='W10M'  : item2='var255'
        if item=='SST'   : item2='var34'

        print("GETTING: "+item+" from "+data_path)

        # Pick wanted variable and level (if applicable) from the data
        data_reduced=ds[item2]

        if plot_vars['levs']:
            # Try whether z-axis is plev or lev
            try:
                data_reduced['plev']
            except KeyError:
                data_reduced=data_reduced.isel(lev=plot_vars['nlevs'][0])
            else:
                data_reduced=data_reduced.isel(plev=plot_vars['nlevs'][0])


        # Change variable name to ecmwf-gribtable one
        data_reduced.name=item

        # Change pressure into hPa
        #if item2=='var151' or item2=='Z':
        #    data_reduced=data_reduced/100.

        # Change total accumulated precip to accumated over 3h time window
        if item2=='var228':
            data_reduced=precip_converter(data_reduced,item)
    
        
        return data_reduced



def precip_converter(data,item):
    "Change total accumulated precip to accumated over chosen time window"
    
    #NOTE! The data must be in 3h time steps

    # Copy the field
    dtemp=data

    if item=="TP3":
        fcskip=1
    elif item=="TP6":
        fcskip=2
    elif item=="TP12":
        fcskip=4
    elif item=="TP":
        fcskip=10000

    dd_temp=[]

    first=True
    init=True
    skipper=1
    # Loop over forecast lengths
    for time in dtemp.coords['time'].values:

        # Start when enough hours have accumulated
        if init and skipper < fcskip:
            skipper+=1
            print("Skipping "+str(time))

            if first:
                first=False
                prev_time=time
                prev_time1=time
                prev_time2=time

            continue

        elif init:
            skipper=1
            if first:
                first=False
                prev_time=time
                prev_time1=time
                prev_time2=time

                dd_temp.append(dtemp.sel(time=time))

            init=False
            continue

        
        # Data substraction
        dd_temp.append(data.sel(time=time) - dtemp.sel(time=prev_time).values)

        # Keep book of what is previous step
        if skipper < fcskip:
            prev_time1=time
            prev_time=prev_time2

            skipper+=1

        elif fcskip==1:
            prev_time=time

        else:
            prev_time2=time
            prev_time=prev_time1

            skipper=1

    data=xr.concat([idat for idat in dd_temp],dim='time')

    return data




def plot_master(data_struct,fig_name,plot_vars,plot_dict):

    minmax=[]

    # Open a pdf to plot to
    with PdfPages(fig_name+'.pdf') as pdf:
        
        # Plot each forecast step into its own pdf page
        for fcstep in plot_dict['fcsteps']:

            # Create figure 
            fig,ax=create_figure(data_struct,plot_dict)
            
            # Call plotting
            index=0
            for plot_var in plot_vars:

                # Get same min and max for ctrl and ensmean
                minmax1=[min(data_struct[index*3].min().values,data_struct[index*3+1].min().values), \
                         max(data_struct[index*3].max().values,data_struct[index*3+1].max().values)]
                minmax2=[0, data_struct[index*3+2].mean().values+plot_dict['fig_ens_scaling']*data_struct[index*3+2].std().values]

                # Call plotting
                plot_mvar(fcstep,data_struct[index*3:(index+1)*3],plot_dict,plot_vars[index],index*2,fig,ax,minmax1,minmax2)

                index+=1

            # Save the plot to the pdf and open a new pdf page
            pdf.savefig()
            plt.close()



def plot_mvar(itime,data_struct,plot_dict,plot_vars,index,fig,ax,minmax1,minmax2):
    "Plot 2D projections"

    # Generate color maps for data
    cmaps=col_maps_data(data_struct,plot_dict,plot_vars)
    ccont1=[plot_dict['fig_c_col'],plot_dict['fig_c_levs']]
    ccont2=[cmaps[1]              ,plot_dict['fig_cf_levs']]
    ccont3=[cmaps[2]              ,plot_dict['fig_ens_cols']]


    # Enlarge fontsizes
    plt.rc('font', size=13)
    plt.rc('axes', labelsize=15)
    plt.rc('xtick',labelsize=15)
    plt.rc('ytick',labelsize=15)

    # Call plotting code layer
    # CTRL vs ENSMEAN
    call_plot(ax[index],data_struct[1],options=[itime],cmap=ccont1, minmax=minmax1,plottype='contour')
    call_plot(ax[index],data_struct[0],options=[itime],cmap=ccont2, minmax=minmax1)

    # ENSMEAN and ENSSTD
    call_plot(ax[index+1],data_struct[1],options=[itime],cmap=ccont1, minmax=minmax1,plottype='contour')
    call_plot(ax[index+1],data_struct[2],options=[itime],cmap=ccont3, minmax=minmax2)


    # MOD FOR WIND BARBS
    #call_plot(ax[0],data_struct[0],options=[itime],cmap=ccont3, minmax=[mim1,mam1])
    #call_plot(ax[0],data_struct[1],data2=data_struct[2],options=[itime],cmap=ccont2,minmax=[mim2,mam2],plottype='winds')

    # Coast line
    ax[index].coastlines('50m',edgecolor='gray',facecolor='gray')
    ax[index+1].coastlines('50m',edgecolor='gray',facecolor='gray')

    # Grid lines
    gl=ax[index].gridlines(draw_labels=True, color='gray', alpha=0.4, linestyle='--')
    gl.top_labels = False
    gl.left_labels = False
    gl=ax[index+1].gridlines(draw_labels=True, color='gray', alpha=0.4, linestyle='--')
    gl.top_labels = False
    gl.left_labels = False


    # Remove border whitespace
    fig.tight_layout()




def create_figure(data_struct,plot_dict):
    "Create figure and return figure and axis handles"

    # Single axis handle
    if (plot_dict['fig_ncol']==1 and plot_dict['fig_nrow']==1):

        # Create a figure
        fig,ax=plt.subplots(nrows=1,squeeze=0,figsize=plot_dict['fig_size'],\
                            subplot_kw={'projection': plot_dict['fig_proj']})


    # Multiple axis handles
    else:
        # Create a figure
        fig,ax=plt.subplots(nrows=plot_dict['fig_nrow'],ncols=plot_dict['fig_ncol'],\
                            figsize=plot_dict['fig_size'],\
                            subplot_kw={'projection': plot_dict['fig_proj']})


    # Fix the axis handle to be simply ax[0]
    ax=fix_ax(ax)

    return fig,ax




def fix_ax(ax):
    "Correct the axis handle when opening a single subplot"

    try:
        ax[0][1]
    except IndexError:
        pass
    except TypeError:
        pass
    else:
        ax_tmp=[]
        for irow in range(0,len(ax)):
            for icol in range(0,len(ax[0])):
                ax_tmp.append(ax[irow][icol])
        return ax_tmp

    try:
        ax[0][0]
    except TypeError:
        pass
    else:
        return ax[0]

    try:
        ax[0]
    except TypeError:
        ax_tmp=[]
        ax_tmp.append(ax)
        ax=ax_tmp
        return ax
    else:
        return ax



def call_plot(ax,data,\
              data2=xr.DataArray(data=None),\
              data3=xr.DataArray(data=None),\
              data4=xr.DataArray(data=None),\
              plottype='contourf',options=[],\
              cmap=[],minmax=[],contf=True):
    "Code layer for plotting"

    # Create an empty data structure
    # (multiple input data sources can be used to calculate
    # differences, RMSEs, etc. between the datasets)
    d=[xr.DataArray(data=None),xr.DataArray(data=None),\
       xr.DataArray(data=None),xr.DataArray(data=None)]

    # Choose a timeinstance and level setting from the data
    #if get_varname(data)=='TP':
        # Precipitation is cumulative, get the diff of the last fcsteps
    #    d[0]=data.isel(time=options[0])-data.isel(time=options[0]-1)

    #else:
    d[0]=data.isel(time=options[0])

    # Get data information
    #dtime=d[0]['time']

    # Select additional data according to first data set
    if data2.notnull().any(): d[1]=data2.isel(time=options[0])
    if data3.notnull(): d[2]=data3.sel(time=dtime)
    if data4.notnull(): d[3]=data4.sel(time=dtime)


    # Contourf.
    if plottype=="contourf":
        contourf_cartopy(ax,d[0],minmax[0],minmax[1],cmap=cmap)

    if plottype=="contour":
        contour_cartopy(ax, d[0],minmax[0],minmax[1],cmap=cmap)
  
    if plottype=="winds":
        barb_cartopy(ax,d[0],d[1],minmax[0],minmax[1],cmap=cmap)



def contourf_cartopy(ax,data,fmin,fmax,cmap):
    "Generate a 2D map with cartopy"

    # Cubehelix cmaps are missing len, set it manually
    try:
        len(cmap)
    except TypeError:
        ncolors=10
    else:
        ncolors=len(cmap)-1

        # mvar specific settings for ens spread
        if len(cmap)==2:
            ncolors=cmap[1]
            cmap=cmap[0]


    # Determine contour intervals
    if not fmin==[]:
        conts=np.arange(fmin,fmax,(fmax-fmin)/ncolors)
    else:
        fmin=data.min().values
        fmax=data.max().values
        conts=np.arange(fmin,fmax,(fmax-fmin)/ncolors)

    # Plot
    xr.plot.contourf(data, ax=ax, transform=ccrs.PlateCarree(), \
                     colors=cmap, levels=conts)
                     #colors=cmap, levels=conts, extend='min',cbar_kwargs=dict(label="MSLP"))
                     #colors=cmap, levels=conts, extend='max',cbar_kwargs=dict(label="SDEV(MSLP)"))



def contour_cartopy(ax,data,fmin,fmax,cmap):
    "Generate a 2D map with cartopy"

    ccol=cmap[0]
    clen=cmap[1]

    # Determine contour intervals
    if not fmin==[]:
        conts=np.arange(fmin,fmax,(fmax-fmin)/clen)
    else:
        fmin=data.min().values
        fmax=data.max().values
        conts=np.arange(fmin,fmax,(fmax-fmin)/clen)

    # Plot
    cs=xr.plot.contour(data, ax=ax, transform=ccrs.PlateCarree(), \
                       levels=conts,colors=ccol,alpha=0.35)

    ax.clabel(cs,fmt= '%1.0f',fontsize=14)



def col_maps_data(data_struct,plot_dict,plot_vars=[]):
    "Set colormaps for each variable [physical units, standard deviation]"

    cmaps=[]

    clevs=plot_dict['fig_cf_levs']

    idata=0
    for data in data_struct:
        icol=0
        #if plot_vars:
            #if plot_vars[idata]['ens']=='ensstd':
            #if plot_vars['ens']=='ensstd':
        if idata==2:
            icol=1

            # TEMP SOLUTION FOR SCORES
            #icol=1

        cmap=col_maps(get_varname(data),clevs)[icol]

        cmaps.append(cmap)

        idata+=1

    return cmaps



def col_maps(var,clevs):
    "Set colormaps for each variable [physical units, standard deviation]"

    if var=='MSL': 
        cmap=[sns.color_palette("BrBG_r",clevs),sns.cubehelix_palette(n_colors=clevs,start=2.7, light=1, as_cmap=True)]
    elif var=='Z': 
        cmap=[sns.color_palette("BrBG_r",clevs),sns.cubehelix_palette(start=2.7, light=1, as_cmap=True, n_colors=clevs)]
    elif var=='T':
        cmap=[sns.color_palette("RdBu_r",clevs),sns.cubehelix_palette(start=2.7, light=1, as_cmap=True, n_colors=clevs)]
    elif var=='Q':
        cmap=[sns.color_palette("PuBu",clevs),sns.cubehelix_palette(start=3.0, light=1, as_cmap=True, n_colors=clevs)]
    elif var=='U' or var=='V':
        cmap=[sns.color_palette("OrRd",clevs),sns.cubehelix_palette(start=2.7, light=1, as_cmap=True, n_colors=clevs)]
    elif var=='W10M':
        cmap=[sns.color_palette("cool",clevs),sns.cubehelix_palette(start=2.7, light=1, as_cmap=True, n_colors=clevs)]
    elif var=='TP':
        cmap=[sns.color_palette("viridis",clevs-10),sns.cubehelix_palette(start=2.7, light=1, as_cmap=True, n_colors=clevs)]
    elif var=='TESTI':
        cmap=[sns.color_palette("winter",clevs),sns.cubehelix_palette(start=2.7, light=1, as_cmap=True, n_colors=clevs)]
    elif var=='MYVARIABLE':
        cmap=[sns.color_palette("winter",clevs),sns.cubehelix_palette(start=2.7, light=1, as_cmap=True, n_colors=clevs)]
    else:
        cmap=[sns.color_palette("RdBu_r",clevs),sns.cubehelix_palette(start=2.7, light=1, as_cmap=True, n_colors=clevs)]

    return cmap




def get_varname(data):
    " Find which variable is requested from the data"

    vname=data.name

    return vname
