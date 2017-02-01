PROGRAM calculate_cost_function
!************************************************************************
! A program for calculating the cost function from ECHAM grib-file
! output.
!
! - read in paths from "infile1.txt"
! - read the data using WGRIB
! - calculate cost function
! - write cost function to "obj.dat"
! - write some more information to "objX.dat" and "globavg_1.dat"
!************************************************************************
! Based on script by Dr. Petri Räisänen
!
!************************************************************************
! Author: Pirkka Ollinaho
!
!************************************************************************
!
! Modified for calculating cost function in nwp case.
!
!                                                  (PO 17 May 2011)
!
!************************************************************************

!!  USE matutils
!! NOTE !! EPPES fortran lib routine

  IMPLICIT NONE

  INTEGER, PARAMETER ::lon=320      ! T106 resolution
  INTEGER, PARAMETER ::lat=160      ! T106 resolution
  INTEGER, PARAMETER ::levmax=31    ! L31
  INTEGER, PARAMETER ::ntime=40, &  ! size of ECHAM output (10d with 6h intervals)
                       ntime2=20,&  ! an data (10d with 12h intervals)
                       ntime_cl=8   ! length of climatology file

  INTEGER, PARAMETER :: nvar=8 ! Number of variables 


  REAL, PARAMETER :: rpi = 3.1415926535, &
                      g  = 9.80665, &
                      cp = 1004, & ! JK**-1kg**-1
                      Tr = 300,  & ! K, reference temperature
                      Rd = 287,  & ! JK**-1kg**-1
                      pr = 1000, & ! hPa, reference pressure
                      ne = 2.718282, &
                      RE = 6371000 ! Mean radius of Earth

! Ordinary 2D quantities
  
  TYPE grid_field
     CHARACTER (LEN=10) :: vname     ! Variable name
     INTEGER            :: indfile   ! Which input file?
     INTEGER            :: icode     ! GrIB code number
     INTEGER            :: levels    ! Number of levels
     CHARACTER (LEN=80) :: description
  END TYPE grid_field

  TYPE (grid_field),  DIMENSION(nvar)          :: f  

  REAL, DIMENSION(:,:,:,:), ALLOCATABLE        :: ff
  REAL, DIMENSION(:,:,:,:), ALLOCATABLE        :: fff

  REAL, DIMENSION(:,:,:), ALLOCATABLE          :: lsp, psurf
  REAL, DIMENSION(:,:,:), ALLOCATABLE          :: lsp_an
  REAL, DIMENSION(:,:,:,:), ALLOCATABLE        :: t_an, u_an, v_an
  REAL, DIMENSION(:,:,:,:), ALLOCATABLE        :: t,u,v

  REAL, DIMENSION(lat)                    :: latitude, zonfrac_area
  REAL, DIMENSION(32)                     :: latitude21  ! T21 latitudes
  REAL, DIMENSION(64)                     :: latitude42  ! T42 latitudes
  REAL, DIMENSION(96)                     :: latitude63  ! T63 latitudes
  REAL, DIMENSION(160)                    :: latitude106 ! T106 latitudes
  REAL, DIMENSION(lon+1)                  :: longitude
  REAL, DIMENSION(lon,lat)                :: frac_area
  REAL                                    :: ww,rlat1,rlat2, globavg, sum_frac_area
  REAL, DIMENSION(ntime)                  :: z_globavg

  REAL, DIMENSION(ntime2)   :: cost_function, kinetic_e, potential_e, &
                                 cost_function_w, surfpres_e, surfpres_e2

  REAL, DIMENSION(levmax+1)   :: a_h, b_h
  REAL, DIMENSION(20)         :: ah19,bh19 ! L19 levels
  REAL, DIMENSION(32)         :: ah31,bh31 ! L31 levels
  REAL, DIMENSION(levmax)     :: a_f, b_f

  INTEGER, DIMENSION(12) :: idays_month

  CHARACTER (LEN=160) :: command
  CHARACTER (LEN=150) :: gribfile, wgribfile, &
                         gribfile1,gribfile2,gribfile3,gribfile4,gribfile5
  CHARACTER (LEN=150) :: path_in,wgribdir
  CHARACTER (LEN=10)  :: vname
  CHARACTER (LEN=4)   :: ayear, runnum
  CHARACTER (LEN=2)   :: amonth
  CHARACTER (LEN=20)  :: expname, date
  CHARACTER (LEN=150) :: ec_an_file, &
                         ec_an_file1,ec_an_file2,ec_an_file3,ec_an_file4,ec_an_file5

  INTEGER :: ilat,ilon,ilev,itime,ivar,iunit_wgrib,lev,imonth,iostat,ind, &
             timestep, timestep_cl, dummytime, dummyclim, clim_month, handlesame, &
             runnumber, iocode 

!! NOTE !! The below was designed to go through a set of outputs
!! It might be better to do a single calculation for each nid process.
!! You should consider doing simple OMP/MPI on some of the loops, this was
!! not very needed on T42 resolution, but with T255 and above it probably pays
!! off...
!! 
!! Commenting...
!! Read in run number and modify the control file to go to next run number
!
!!  CALL OPEN_WITH_LOCK(file="control.txt",unit=11,status='old',timeout=250.,uselock=.true.)
!! NOTE !! EPPES fortran lib routine
!  READ(11,*,IOSTAT=iocode) runnumber
!  IF (iocode > 0) THEN
!    WRITE(*,'("Problem with reading control.txt")')
!    STOP
!  END IF  
!  CLOSE(11)
!
!  CALL DELETE_FILE(file="control.txt")
!! NOTE !! EPPES fortran lib routine
!
!  OPEN (unit=11,file="control.txt",status='new')
!  WRITE(11,*) runnumber+1
!  CALL CLOSE_WITH_LOCK(unit=11,file="control.txt",uselock=.true.) 
!! NOTE !! EPPES fortran lib routine
!
!  IF (runnumber.LT.10) THEN
!    WRITE(runnum,'(I1)') runnumber
!
!  ELSEIF (runnumber.LT.100) THEN
!    WRITE(runnum,'(I2)') runnumber
!
!  ELSE
!    WRITE(runnum,'(I3)') runnumber
!  END IF
!! ...end commenting!

!******************************************************************************
! Number of days per month (no leap year) (PROBABLY NOT NEEDED?)

  idays_month = (/31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31/)

!*****************************************************************************
! Definition of hybrid levels coefficients (19-level model)

     ah19 = (/0., 2000., 4000., 6046.110595, 8267.927560, 10609.513232, &
          12851.100169, 14698.498086, 15861.125180, 16116.236610, 15356.924115, &
          13621.460403, 11101.561987, 8127.144155, 5125.141747, 2549.969411, & 
          783.195032, 0., 0., 0./)

     bh19 = (/0., 0., 0., 0.0003389933, 0.0033571866, 0.0130700434, 0.0340771467, &
          0.0706498323, 0.1259166826, 0.2011954093, 0.2955196487, 0.4054091989, &
          0.5249322235, 0.6461079479, 0.7596983769, 0.8564375573, 0.9287469142, &
          0.9729851852, 0.9922814815, 1./)!

! Definition of hybrid level coefficients (31-level model) -PO 4.5.2010

     ah31 = (/0.00000000,  2000.00000000,  4000.00000000,  6000.00000000,  &
          8000.00000000,  9976.13671875,  11820.53906250, 13431.39453125, &
          14736.35546875, 15689.20703125, 16266.60937500, 16465.00390625, &
          16297.62109375, 15791.59765625, 14985.26953125, 13925.51953125, &
          12665.29296875, 11261.23046875, 9771.40625000,  8253.21093750,  &
          6761.33984375,  5345.91406250,  4050.71777344,  2911.56933594,  &
          1954.80517578,  1195.88989258,  638.14892578,   271.62646484,   &
          72.06358337,    0.00000000,     0.00000000,     0.00000000/)


     bh31 = (/0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00039086, & 
          0.00291970, 0.00919413, 0.02031916, 0.03697486, 0.05948764, 0.08789498, & 
          0.12200361, 0.16144150, 0.20570326, 0.25418860, 0.30623537, 0.36114502, & 
          0.41820228, 0.47668815, 0.53588659, 0.59508425, 0.65356457, 0.71059442, &
          0.76540524, 0.81716698, 0.86495584, 0.90771586, 0.94421321, 0.97298521, &
          0.99228150, 1.00000000/)

! Choose the correct level presentation
!! NOTE
!! get the vcta and vctb for 91-level model above
!! Commenting...
!     a_h = ah31
!     b_h = bh31
!
!  DO ilev=1,levmax
!     a_f(ilev) = 0.5*(a_h(ilev)+a_h(ilev+1))  
!     b_f(ilev) = 0.5*(b_h(ilev)+b_h(ilev+1))
!  ENDDO
!! ...end comments!


!*******************************************************************************
! Definition of latitudes and longitudes

! Define latitudes).
! Note that in the GRIB files, latitudes go from 85.761 to -85.761 ??)

! T21
  latitude21 = (/-85.761, -80.269, -74.745, -69.213, -63.679, -58.143, &
               -52.607, -47.070, -41.532, -35.995, -30.458, -24.920, &
               -19.382, -13.844,  -8.307,  -2.769,   2.769,   8.307, &
                13.844,  19.382,  24.920,  30.458,  35.995,  41.532, &
                47.070,  52.607,  58.143,  63.679,  69.213,  74.745, &
                80.269,  85.761/)

! T42
  latitude42 = (/-87.8637988, -85.0965270, -82.3129129, -79.5256066, -76.7368997, &
               -73.9475152, -71.1577520, -68.3677561, -65.5776070, -62.7873518, &
               -59.9970201, -57.2066315, -54.4161995, -51.6257337, -48.8352410, &
               -46.0447266, -43.2541947, -40.4636482, -37.6730896, -34.8825210, &
               -32.0919439, -29.3013596, -26.5107693, -23.7201739, -20.9295743, &
               -18.1389710, -15.3483648, -12.5577561, -9.76714556, -6.97653355, &
               -4.18592053, -1.39530691,  1.39530691,  4.18592053,  6.97653355, &
                9.76714556,  12.5577561,  15.3483648,  18.1389710,  20.9295743, &
                23.7201739,  26.5107693,  29.3013596,  32.0919439,  34.8825210, &
                37.6730896,  40.4636482,  43.2541947,  46.0447266,  48.8352410, &
                51.6257337,  54.4161995,  57.2066315,  59.9970201,  62.7873518, &
                65.5776070,  68.3677561,  71.1577520,  73.9475152,  76.7368997, &
                79.5256066,  82.3129129,  85.0965270,  87.8637988/) 

! T63
  latitude63 = (/-88.5721685, -86.7225310, -84.8619703, -82.9989416, -81.1349768, &
               -79.2705590, -77.4058881, -75.5410615, -73.6761323, -71.8111321, &
               -69.9460806, -68.0809910, -66.2158721, -64.3507304, -62.4855705, &
               -60.6203959, -58.7552093, -56.8900126, -55.0248075, -53.1595954, &
               -51.2943771, -49.4291537, -47.5639257, -45.6986939, -43.8334586, &
               -41.9682203, -40.1029793, -38.2377360, -36.3724906, -34.5072433, &
               -32.6419944, -30.7767441, -28.9114924, -27.0462395, -25.1809856, &
               -23.3157307, -21.4504750, -19.5852186, -17.7199615, -15.8547039, &
               -13.9894457, -12.1241871, -10.2589282, -8.39366891,  -6.5284094, &
               -4.66314971, -2.79788988, -0.932629968, 0.932629968,  2.79788988,&
                4.66314971,   6.5284094,  8.39366891,  10.2589282,  12.1241871, &
                13.9894457,  15.8547039,  17.7199615,  19.5852186,  21.4504750, & 
                23.3157307,  25.1809856,  27.0462395,  28.9114924,  30.7767441, &
                32.6419944,  34.5072433,  36.3724906,  38.2377360,  40.1029793, &
                41.9682203,  43.8334586,  45.6986939,  47.5639257,  49.4291537, &
                51.2943771,  53.1595954,  55.0248075,  56.8900126,  58.7552093, &
                60.6203959,  62.4855705,  64.3507304,  66.2158721,  68.0809910, &
                69.9460806,  71.8111321,  73.6761323,  75.5410615,  77.4058881, &
                79.2705590,  81.1349768,  82.9989416,  84.8619703,  86.7225310, &
                88.5721685/) 

! T106
  latitude106 = (/-89.1415194, -88.0294289, -86.9107708, -85.7906289, -84.6699241, &
               -83.5489469, -82.4278175, -81.3065945, -80.1853099, -79.0639825, &
               -77.9426242, -76.8212430, -75.6998442, -74.5784317, -73.4570081, &
               -72.3355758, -71.2141361, -70.0926904, -68.9712395, -67.8497844, &
               -66.7283256, -65.6068636, -64.4853989, -63.3639317, -62.2424624, &
               -61.1209913, -59.9995185, -58.8780442, -57.7565686, -56.6350918, &
               -55.5136140, -54.3921352, -53.2706555, -52.1491750, -51.0276937, & 
               -49.9062118, -48.7847293, -47.6632463, -46.5417627, -45.4202786, &
               -44.2987941, -43.1773092, -42.0558240, -40.9343383, -39.8128524, &
               -38.6913661, -37.5698796, -36.4483928, -35.3269058, -34.2054185, &
               -33.0839310, -31.9624434, -30.8409555, -29.7194675, -28.5979793, &
               -27.4764909, -26.3550025, -25.2335138, -24.1120251, -22.9905362, &
               -21.8690473, -20.7475582, -19.6260691, -18.5045798, -17.3830905, &
               -16.2616011, -15.1401117, -14.0186222, -12.8971326, -11.7756430, & 
               -10.6541533, -9.53266359, -8.41117384, -7.28968406, -6.16819425, &
               -5.04670442, -3.92521457, -2.80372470, -1.68223483, -0.560744943, &
               0.560744943,  1.68223483,  2.80372470,  3.92521457,  5.04670442, &
                6.16819425,  7.28968406,  8.41117384,  9.53266359,  10.6541533, &
                 11.775643,  12.8971326,  14.0186222,  15.1401117,  16.2616011, &
                17.3830905,  18.5045798,  19.6260691,  20.7475582,  21.8690473, & 
                22.9905362,  24.1120251,  25.2335138,  26.3550025,  27.4764909, &
                28.5979793,  29.7194675,  30.8409555,  31.9624434,  33.0839310, &
                34.2054185,  35.3269058,  36.4483928,  37.5698796,  38.6913661, &
                39.8128524,  40.9343383,  42.0558240,  43.1773092,  44.2987941, &
                45.4202786,  46.5417627,  47.6632463,  48.7847293,  49.9062118, &
                51.0276937,  52.1491750,  53.2706555,  54.3921352,  55.5136140, &
                56.6350918,  57.7565686,  58.8780442,  59.9995185,  61.1209913, &
                62.2424624,  63.3639317,  64.4853989,  65.6068636,  66.7283256, &
                67.8497844,  68.9712395,  70.0926904,  71.2141361,  72.3355758, &
                73.4570081,  74.5784317,  75.6998442,  76.8212430,  77.9426242, &
                79.0639825,  80.1853099,  81.3065945,  82.4278175,  83.5489469, &
                84.6699241,  85.7906289,  86.9107708,  88.0294289,  89.1415194/)

! Choose the correct latitude presentation
!! NOTE
!! Get the correcat presentation for T255 above
!! Commenting...
!  latitude = latitude106
!
!
!! Area fraction of latitude zones (used as weight in the computations)
!
!  DO ilat=1,lat
!    IF (ilat == 1) THEN
!       rlat1 = -90.
!     ELSE
!       rlat1 = 0.5*(latitude(ilat-1)+latitude(ilat))
!     END IF
!     IF (ilat == lat) THEN
!       rlat2 = 90.
!     ELSE
!       rlat2 = 0.5*(latitude(ilat)+latitude(ilat+1))
!     END IF
!     frac_area(1:lon,ilat) = 1./REAL(lon)                 &
!          * 0.5*(SIN(rpi/180.*rlat2)-SIN(rpi/180.*rlat1))
!  ENDDO
!
!  sum_frac_area = SUM(frac_area(:,:))
!
!  frac_area(:,:) = frac_area(:,:) / sum_frac_area
! 
!  DO ilat=1,lat
!    zonfrac_area(ilat) = SUM(frac_area(1:lon,ilat))
!  ENDDO 
!
!! Define longitudes
!
!  DO ilon=1,lon
!    longitude(ilon) = (ilon-1.)/REAL(lon) * 360.
!  ENDDO
!  longitude(lon+1)=360.
!! ...end comments!
   frac_area(:,:)=1.0

!*******************************************************************
! Define file paths for reading
!*******************************************************************

! Read paths in

   OPEN(UNIT=11,FILE="infile.txt",STATUS='OLD')
   READ(11,'(A)') expname
   READ(11,'(A)') path_in
   READ(11,'(A)') wgribdir
   READ(11,'(A)') ec_an_file
   READ(11,'(A)') date
   CLOSE(11)

!! NOTE
!! The stuff below works if an-file is a single file containing all 
!! verification dates
!! Commenting...
!! Read in timestep
!
!   OPEN(UNIT=11,FILE="timestep.txt",STATUS='OLD')
!   READ(11,*) dummytime
!   CLOSE(11)
!
!! Convert the "hours-from-2011010100" to timestep corresponding to the
!! an-file (i.e. define which element of an-file to read)
!
!   timestep = dummytime/12 + 1
!
!! ...end comments!

! Define the path name for input files!
!! NOTE !! I haven't tested but would guess i/o is faster with the fields in
!! separate files.
   !path_in = TRIM(path_in)//"/" //TRIM(date) // "/" //TRIM(expname)//"/pp/"
   path_in = TRIM(path_in)//"/pp/"
   gribfile1 = TRIM(path_in)//"temp_var152.grb"
   gribfile2 = TRIM(path_in)//"temp_var130.grb"
   gribfile3 = TRIM(path_in)//"temp_var131.grb" 
   gribfile4 = TRIM(path_in)//"temp_var132.grb"
!   gribfile5 = TRIM(path_in)//"temp_var133.grb" 

!! NOTE !! Since there ain't a single an file (for now), define the paths for an 
!! files here
   ec_an_file1 = TRIM(path_in)//"temp_an_var152.grb"
   ec_an_file2 = TRIM(path_in)//"temp_an_var130.grb"
   ec_an_file3 = TRIM(path_in)//"temp_an_var131.grb" 
   ec_an_file4 = TRIM(path_in)//"temp_an_var132.grb"
!   ec_an_file5 = TRIM(path_in)//"temp_an_var132.grb"

   !wgribdir = TRIM(wgribdir)//"/" //TRIM(date) // "/" //TRIM(expname)//"/wgrib1/"
   wgribdir = TRIM(wgribdir)//"/wgrib1/"

!****************************************************************
! Define variables to be considered
!****************************************************************
 
  f(1:nvar)%vname   = "          " 
  f(1:nvar)%indfile = 0
  f(1:nvar)%icode   = 0
  f(1:nvar)%levels  = 0
  f(1:nvar)%description = "                                        "//&
                          "                                        " 

  f(1)=grid_field("lnsp",    1, 152,   1, "logarithm of surface pressure")

! Vertical distrubution of temperature and winds
  f(2)=grid_field("t",       2,130, levmax, "temperature at model levels (K)")
  f(3)=grid_field("u",       3,131, levmax, "u component of wind at model levels (ms**-1)")
  f(4)=grid_field("v",       4,132, levmax, "v component of wind at model levels (ms**-1)")

! Analysis fields
  f(5)=grid_field("lnsp",    5, 152,   1, "logarithm of surface pressure")

  f(6)=grid_field("t",       6,130, levmax, "temperature at model levels (K)")
  f(7)=grid_field("u",       7,131, levmax, "u component of wind at model levels (ms**-1)")
  f(8)=grid_field("v",       8,132, levmax, "v component of wind at model levels (ms**-1)")

  DO ivar=1,nvar
    write(33,'(A,I4," 99  ",A)') f(ivar)%vname, f(ivar)%levels, f(ivar)%description
  ENDDO

!******************************************************************
! Read variables one by one, and write them all to a direct access
! binary output file
!*****************************************************************

  iunit_wgrib=1000
  DO ivar=1,nvar

    IF (f(ivar)%indfile == 1) gribfile = gribfile1
    IF (f(ivar)%indfile == 2) gribfile = gribfile2
    IF (f(ivar)%indfile == 3) gribfile = gribfile3
    IF (f(ivar)%indfile == 4) gribfile = gribfile4
!    IF (f(ivar)%indfile == 1) gribfile = gribfile
    IF (f(ivar)%indfile == 5) gribfile = ec_an_file1
    IF (f(ivar)%indfile == 6) gribfile = ec_an_file2
    IF (f(ivar)%indfile == 7) gribfile = ec_an_file3
    IF (f(ivar)%indfile == 8) gribfile = ec_an_file4
!    IF (f(ivar)%indfile == ) gribfile = ec_an_file5

    lev = f(ivar)%levels
    vname = TRIM(f(ivar)%vname)

    CALL extract_wgrib(f(ivar)%icode,gribfile,wgribdir,iunit_wgrib,wgribfile, &
                       iostat)

    IF (iostat /= 0) GOTO 999

    IF (f(ivar)%indfile == 1) THEN
       ALLOCATE(ff(lon,lat,lev,ntime))
       CALL read_wgribfile(lon,lat,lev,ntime,iunit_wgrib, ff(:,:,1,:), &
                           iostat)
       handlesame=0
    ELSEIF (f(ivar)%indfile==2.OR.f(ivar)%indfile==3.OR.f(ivar)%indfile==4) THEN
       ALLOCATE(ff(lon,lat,lev,ntime))
       CALL read_wgribfile(lon,lat,lev,ntime,iunit_wgrib, ff(:,:,:,:), &
                           iostat)
       handlesame=0
    ELSEIF (f(ivar)%indfile == 5) THEN
       ALLOCATE(fff(lon,lat,lev,ntime2))
       CALL read_wgribfile(lon,lat,lev,ntime2,iunit_wgrib, fff(:,:,1,:), &
                           iostat)
       handlesame=1
    ELSE
       ALLOCATE(fff(lon,lat,lev,ntime2))
       CALL read_wgribfile(lon,lat,lev,ntime2,iunit_wgrib, fff(:,:,:,:), &
                           iostat)
       handlesame=1
    END IF

    CALL clean_up (iunit_wgrib,wgribfile)

! Compute global averages (for testing)

 !   DO itime=1,ntime2
 !     DO ilev=1,f(ivar)%levels
 !       IF (handlesame.EQ.0) globavg = SUM(frac_area(:,:)*ff(:,:,ilev,itime*2))
 !       IF (handlesame.EQ.1) globavg = SUM(frac_area(:,:)*fff(:,:,ilev,itime))
 !       WRITE(22,*) itime,vname,ilev,globavg
 !
 !     ENDDO
 !   ENDDO 

! Store some variables for further use
    IF (vname=="lnsp".AND. handlesame.EQ.0) THEN

       ALLOCATE(lsp(lon,lat,ntime))
       lsp(:,:,:) = ff(:,:,1,:)
       DEALLOCATE(ff)

    ELSE IF (vname=="t".AND.handlesame.EQ.0) THEN

       ALLOCATE(t(lon,lat,lev,ntime))
       t(:,:,:,:) = ff(:,:,:,:)
       DEALLOCATE(ff)

    ELSE IF (vname=="u"  .AND. handlesame.EQ.0) THEN

       ALLOCATE(u(lon,lat,lev,ntime))
       u(:,:,:,1:ntime) = ff(:,:,:,1:ntime)
       DEALLOCATE(ff)

    ELSE IF (vname=="v"  .AND. handlesame.EQ.0) THEN

       ALLOCATE(v(lon,lat,lev,ntime))
       v(:,:,:,1:ntime) = ff(:,:,:,1:ntime)
       DEALLOCATE(ff)

    ELSE IF (vname=="lnsp".AND. handlesame.EQ.1) THEN

       ALLOCATE(lsp_an(lon,lat,ntime2))
       lsp_an(:,:,:) =  fff(:,:,1,:)
       DEALLOCATE(fff)

    ELSE IF (vname=="t"  .AND. handlesame.EQ.1) THEN

       ALLOCATE(t_an(lon,lat,lev,ntime2))
       t_an(:,:,:,1:ntime2) = fff(:,:,:,1:ntime2)
       DEALLOCATE(fff)

   ELSE IF (vname=="u"  .AND. handlesame.EQ.1) THEN

       ALLOCATE(u_an(lon,lat,lev,ntime2))
       u_an(:,:,:,1:ntime2) = fff(:,:,:,1:ntime2)
       DEALLOCATE(fff)

    ELSE IF (vname=="v"  .AND. handlesame.EQ.1) THEN

       ALLOCATE(v_an(lon,lat,lev,ntime2))
       v_an(:,:,:,1:ntime2) = fff(:,:,:,1:ntime2)
       DEALLOCATE(fff)

    END IF

    IF (TRIM(vname)=="phalf") THEN
      DO ilev=1,f(ivar)%levels
        ff(:,:,ilev,1:ntime) = a_h(ilev) + b_h(ilev)*psurf(:,:,1:ntime) 
      ENDDO
    END IF 

    IF (TRIM(vname)=="pfull") THEN
      DO ilev=1,f(ivar)%levels
        ff(:,:,ilev,1:ntime) = a_f(ilev) + b_f(ilev)*psurf(:,:,1:ntime) 
      ENDDO
    END IF  
        
  ENDDO ! Loop over variables

! Take zonal average

  DO itime=1,ntime
     z_globavg(itime) = SUM(frac_area(:,:)*lsp(:,:,itime))
!     z_shavg(itime) = SUM(frac_area(:,1:lat/2)*z(:,1:lat/2,itime))
!     z_nhavg(itime) = SUM(frac_area(:,lat/2:lat)*z(:,lat/2:lat,itime))
  ENDDO


!*************************************************************************
! Compute the cost function.
!************************************************************************
 99 CONTINUE

  cost_function = 0.

! Old formatting
!    CALL read_2d(1,lat,iunit_era, 6,imonth,nvar_era, zonstdnet_era(:))
 

  kinetic_e=0.
  potential_e=0.
  surfpres_e=0.
  surfpres_e2=0.

  DO itime = 1,ntime2
!    kinetic_e(itime) = 0.5 *SUM((frac_area(u_an(:,:,:,itime+1)-u(:,:,:,itime*2))**2 + &
!                                (v_an(:,:,:,itime+1)-v(:,:,:,itime*2))**2)
!    potential_e(itime) = cp/Tr* SUM((t_an(:,:,:,itime+1)-t(:,:,:,itime*2))**2)
!    surfpres_e(itime)  = 0.5 * Rd*Tr*pr*SUM((lsp_an(:,:,itime+1)-lsp(:,:,itime*2))**2)
!    surfpres_e2(itime) = 0.5 * Rd*Tr/pr**2 * SUM((ne**(lsp(:,:,itime)))**2)
!    cost_function(itime) = kinetic_e(itime) + potential_e(itime) + surfpres_e(itime)

write(*,*) "hep"
write(*,*) (t_an(1,1,1,1)-t(1,1,1,1))**2
!do ilon=1,lon
! do ilat=1,lat
!  potential_e(itime)=potential_e(itime)+cp/Tr*((t_an(ilon,ilat,1,itime)-t(ilon,ilat,1,itime))**2)
! end do
!end do

  !  DO ilev = 1,levmax
  !     kinetic_e(itime) = kinetic_e(itime) + &
  !                        0.5 *SUM(frac_area(:,:)*(u_an(:,:,ilev,itime)-u(:,:,ilev,itime))**2 &
  !                      + frac_area(:,:)*(v_an(:,:,ilev,itime)-v(:,:,ilev,itime))**2)
  !     potential_e(itime) = potential_e(itime) + &
  !                          cp/Tr* &
  !                          SUM(frac_area(:,:)*(t_an(:,:,ilev,itime)-t(:,:,ilev,itime))**2)
  !  END DO

  !  surfpres_e(itime)  = 0.5*Rd*Tr*pr*SUM(frac_area(:,:)*(lsp_an(:,:,itime)-lsp(:,:,itime))**2)

    cost_function(itime) = kinetic_e(itime) + potential_e(itime) + surfpres_e(itime)

write(*,*) "hep"

! Disrecard the following, using the PR fractional areas is faster and accurate enough.
! 
!    DO ilat=1,lat
!      IF (ilat == 1) THEN
!         rlat1 = -90.
!       ELSE
!         rlat1 = 0.5*(latitude(ilat-1)+latitude(ilat))
!       END IF
!       IF (ilat == lat) THEN
!         rlat2 = 90.
!       ELSE
!         rlat2 = 0.5*(latitude(ilat)+latitude(ilat+1))
!       END IF
!
!       DO ilon=1,lon
!         surfpres_e2(itime) = surfpres_e2(itime) + 0.5 * Rd*Tr*pr* &
!                             (RE**2*(ABS(COS(rlat2/360.*2*rpi-rpi/2.)-COS(rlat1/360.*2*rpi-rpi/2.)))* &
!                             ABS(longitude(ilon)/360.*2.*rpi -longitude(ilon+1)/360.*2.*rpi))/(4.*rpi*RE**2)* &
!                             (lsp_an(ilon,ilat,itime)-lsp(ilon,ilat,itime*2))**2
!       END DO
!    ENDDO

  END DO

 999 CONTINUE
! Special treatment of cost function and global-mean radiative fluxes
! in the case that something went wrong (iostat /=0). This has been added
! in order to define the cost function also when runs crashed.
! If this is not done, MCMC will use the "obj.dat" (from the previous
! run that was finished succesfully), and may errorneously accept the
! tuning parameters use in this (crashed) run.            (PR 24 Nov 2009)

  IF (iostat /=0) THEN

! Write the cost function to "obj.dat"

!!    CALL DELETE_FILE(file="tmp/obj_en.dat"//TRIM(runnum))
!! NOTE !! DELETE_FILE is in EPPES fortran lib, either add here or link in comp
!    OPEN(UNIT=12,FILE="tmp/obj_en.dat"//TRIM(runnum))
!    WRITE(12,*) 0
!    CLOSE(12)

! Write out some other stuff also

!!    CALL DELETE_FILE(file="tmp/obj2_en.dat"//TRIM(runnum))  
!! NOTE !! DELETE_FILE is in EPPES fortran lib, either add here or link in comp
!    OPEN(UNIT=12,FILE="tmp/obj2_en.dat"//TRIM(runnum))
!    DO itime=1,ntime2
!       WRITE(12,*) 0
!    END DO
!    CLOSE(12)

    WRITE(*,*) "Damn..."
  ELSE

! Write the cost function to "obj.dat"

!!    CALL DELETE_FILE(file="tmp/obj_en.dat"//TRIM(runnum))
!! NOTE !! DELETE_FILE is in EPPES fortran lib, either add here or link in comp
!    OPEN(UNIT=12,FILE="tmp/obj_en.dat"//TRIM(runnum))
!    WRITE(12,*) cost_function(ntime2)
!    CLOSE(12)

! Write out some other stuff also

!!    CALL DELETE_FILE(file="tmp/obj2_en.dat"//TRIM(runnum))  
!! NOTE !! DELETE_FILE is in EPPES fortran lib, either add here or link in comp
!    OPEN(UNIT=12,FILE="tmp/obj2_en.dat"//TRIM(runnum))
!    DO itime=1,ntime2
!       WRITE(12,*) cost_function(itime), kinetic_e(itime), potential_e(itime), surfpres_e(itime)
!    END DO
!    CLOSE(12)

    WRITE(*,*) cost_function
  END IF

! Write some information to "globavg_1.dat"

!  CALL SYSTEM("rm -f globavg_1.dat")
!  OPEN(UNIT=12,FILE="globavg_1.dat")
!  DO itime=1,ntime2-1
!     WRITE(12,'(6F12.5)') z_globavg(2*itime), z_an_globavg(itime)/g, z_nhavg(2*itime), &
!                 z_an_nhavg(itime)/g, z_shavg(2*itime), z_an_shavg(itime)/g
!  END DO
!  CLOSE(12)


!******************************************
CONTAINS
!******************************************

!***********************************************************************
  SUBROUTINE extract_wgrib(icode, gribfile, wgribdir, iunit_wgrib, wgribfile, &
                           iostat)
!
! Extracts with 'wgrib' the field with the number "icode" from "gribfile".   
! The field is written in binary format to a file in the directory "wgribdir".
! The file name is returned in "wgribfile".
!                                                     (PR 20060505)
!
! Information about possible problems in opening the "wgribfile" is added
! to output arguments (iostat).
!                                                     (PR 20091124)

    INTEGER, INTENT(in)  :: icode, iunit_wgrib 
    INTEGER, INTENT(out) :: iostat
    CHARACTER (len=*), INTENT(in)  :: gribfile, wgribdir 
    CHARACTER (len=*), INTENT(out) :: wgribfile
   
    CHARACTER (len=350) :: command 
    CHARACTER (len=3) :: apu

! Define file names

    iostat = 0

    apu = "   "
 
    IF (icode < 10) THEN
      write(apu,'(I1)') icode
    ELSE IF (icode < 100) THEN
      write(apu,'(I2)') icode
    ELSE
      write(apu,'(I3)') icode
    ENDIF

    wgribfile = TRIM(wgribdir)//TRIM(apu)//".bin"

    OPEN(UNIT=11,FILE=wgribfile,FORM='unformatted',STATUS='new',IOSTAT=iostat)

    IF (iostat /= 0) GOTO 999

! Extract the field using WGRIB
!

    COMMAND = "wgrib "//TRIM(gribfile)//" | grep "&
              //"'kpds5="//TRIM(apu)//":' | wgrib "&
              //TRIM(gribfile)//" -i -bin -o "//wgribfile

!    write(*,*) command
    CALL SYSTEM(command) 

    CLOSE(11)

! Open the file for reading!

    OPEN(UNIT=iunit_wgrib,FILE=wgribfile, FORM = 'unformatted', STATUS = 'old',&
         IOSTAT = iostat)

 999 CONTINUE
 
    RETURN
  END SUBROUTINE extract_wgrib
!**************************************************************************

  SUBROUTINE read_wgribfile(lon,lat,lev,ntime,iunit_wgrib, ff, iostat)

    INTEGER, INTENT(in) :: lon,lat,lev,ntime,iunit_wgrib
    INTEGER, INTENT(out) :: iostat
    INTEGER :: itime,ilev
    REAL, DIMENSION(lon,lat,lev,ntime),INTENT(out) :: ff
   
    DO itime=1,ntime
      DO ilev=1,lev
!       READ(iunit_wgrib) ff(:,:,ilev,itime)
        READ(iunit_wgrib,IOSTAT=iostat) ff(:,lat:1:-1,ilev,itime)
        IF (iostat /=0) GOTO 999
      ENDDO 
    ENDDO
 999 CONTINUE     

    RETURN
  END SUBROUTINE read_wgribfile

!************************************************************************************

  SUBROUTINE write_field(lon,lat,lev,ntime,ff,iunit_out,ifirst,nrec_per_step)

! Add the field "ff" to the direct access binary output file (iunit_out).
! The variables "ifirst" and "nrec_per_step" are used for calculating record numbers 


    INTEGER :: lon, lat, lev, ntime, iunit_out, ifirst, nrec_per_step, &
               ilev, itime,irec

    REAL :: ff(lon,lat,lev,ntime)

    DO itime=1,ntime
      DO ilev=1,lev
        irec = (itime-1)*nrec_per_step + ifirst + ilev-1
        WRITE(iunit_out,REC=irec) ff(:,:,ilev,itime)
!       CALL ulos(ff(:,:,ilev,itime),irec,lon,lat,iunit_out)
      ENDDO 
    ENDDO
     

  END SUBROUTINE write_field

!****************************************************************************
  SUBROUTINE clean_up (iunit,wgribfile)
! Closes files iadd+1 ... iadd+nruns and removes
! the [same] files wgribfile(1) ... wgribfile (nruns)

    INTEGER, INTENT(in) :: iunit
    CHARACTER (len=*), INTENT(in) :: wgribfile   
    
    CLOSE(iunit)
!    CALL DELETE_FILE(file=wgribfile)
     CALL SYSTEM("rm -f "//TRIM(wgribfile))
! Remove also the temporary files (if they exist)
!    CALL DELETE_FILE(file=TRIM(wgribfile)//"1")
!    CALL DELETE_FILE(file=TRIM(wgribfile)//"2")

    RETURN
 END SUBROUTINE clean_up
!****************************************************


END PROGRAM calculate_cost_function
