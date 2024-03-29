 
C     $Id$
c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1994  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     #################################################################
c     ##                                                             ##
c     ##  subroutine smooth  --  set potential smoothing parameters  ##
c     ##                                                             ##
c     #################################################################
c
c
c     "smooth" sets the type of smoothing method and the extent of
c     surface deformation for use with potential energy smoothing
c
c
      subroutine smooth
      implicit none
      include 'sizes.i'
      include 'atoms.i'
      include 'fields.i'
      include 'inform.i'
      include 'iounit.i'
      include 'keys.i'
      include 'warp.i'
      integer i,next
      logical query,exist
      character*7 stype
      character*20 keyword
      character*120 record
      character*120 string
c
c
c     set defaults for deformation and diffusion coefficients
c
      query = .true.
      deform = 0.0d0
      difft = 0.0225d0
      diffv = 1.0d0
      diffc = 1.0d0
c
c     get any keywords related to potential energy smoothing
c
      do i = 1, nkey
         next = 1
         record = keyline(i)
         call gettext (record,keyword,next)
         call upcase (keyword)
         string = record(next:120)
         if (keyword(1:10) .eq. 'SMOOTHING ') then
            use_smooth = .true.
            use_dem = .false.
            use_gda = .false.
            use_tophat = .false.
            use_stophat = .false.
            call getword (record,stype,next)
            call upcase (stype)
            if (stype .eq. 'DEM')  use_dem = .true.
            if (stype .eq. 'GDA')  use_gda = .true.
            if (stype .eq. 'TOPHAT')  use_tophat = .true.
            if (stype .eq. 'STOPHAT')  use_stophat = .true.
         else if (keyword(1:7) .eq. 'DEFORM ') then
            read (string,*,err=10,end=10)  deform
            query = .false.
         else if (keyword(1:16) .eq. 'DIFFUSE-TORSION ') then
            read (string,*,err=10,end=10)  difft
         else if (keyword(1:12) .eq. 'DIFFUSE-VDW ') then
            read (string,*,err=10,end=10)  diffv
         else if (keyword(1:15) .eq. 'DIFFUSE-CHARGE ') then
            read (string,*,err=10,end=10)  diffc
         end if
   10    continue
      end do
c
c     try to get the deformation value from the command line
c
      if (use_smooth) then
         if (query) then
            call nextarg (string,exist)
            if (exist) then
               read (string,*,err=20,end=20)  deform
               query = .false.
            end if
   20       continue
         end if
c
c     ask for the potential surface deformation to be used
c
         if (query) then
   30       continue
            if (use_gda) then
               deform = 200.0d0
               write (iout,40)
   40          format (/,' Enter the Initial Mean Squared Gaussian',
     &                    ' Width [200.0] :  ',$)
            else if (use_tophat .or. use_stophat) then
               deform = 0.0d0
               write (iout,50)
   50          format (/,' Enter Length Scale for Potential Surface',
     &                    ' Averaging [0.0] :  ',$)
            else
               deform = 0.0d0
               write (iout,60)
   60          format (/,' Enter the Potential Surface Smoothing',
     &                    ' Parameter [0.0] :  ',$)
            end if
            read (input,70)  record
   70       format (a120)
            read (record,*,err=30,end=80)  deform
   80       continue
         end if
      end if
c
c     set second moment of Gaussian on each atom for GDA methods
c
      if (use_gda) then
         do i = 1, n
            m2(i) = deform
         end do
      end if
      return
      end
