 
C     $Id$
c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1993  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     #############################################################
c     ##                                                         ##
c     ##  program correlate  --  time correlation of a property  ##
c     ##                                                         ##
c     #############################################################
c
c
c     "correlate" computes the time correlation function of some
c     user-supplied property from individual snapshot frames taken
c     from a molecular dynamics or other trajectory
c
c
      program correlate
      implicit none
      include 'sizes.i'
      include 'atoms.i'
      include 'files.i'
      include 'inform.i'
      include 'iounit.i'
      integer maxsite,maxblock,maxframe
      parameter (maxsite=1000)
      parameter (maxblock=1000)
      parameter (maxframe=100000)
      integer i,j,k,m
      integer n1,n2,dt,trimtext
      integer first,last,step
      integer start,stop
      integer nfile,nblock,maxgap
      integer blksize,blkgap,blkdiff
      integer t1(maxblock)
      integer t2(maxblock)
      integer icorr(0:maxframe)
      real*8 value,property
      real*8 vcorr(0:maxframe)
      real*8 ucorr(0:maxframe)
      real*8 x1(maxsite,maxblock)
      real*8 y1(maxsite,maxblock)
      real*8 z1(maxsite,maxblock)
      real*8 x2(maxsite,maxblock)
      real*8 y2(maxsite,maxblock)
      real*8 z2(maxsite,maxblock)
      logical exist,query,normal
      character*1 letter
      character*120 string
c
c
c     get the base name of user specified input structures
c
      call initial
      call nextarg (filename,exist)
      if (.not. exist) then
         write (iout,10)
   10    format (/,' Enter Cartesian Coordinate File Name :  ',$)
         read (input,20)  filename
   20    format (a120)
      end if
c
c     remove any extension from the filename
c
      leng = trimtext (filename)
      last = leng
      do i = 1, leng
         letter = filename(i:i)
         if (letter .eq. '/')  last = leng
c        if (letter .eq. '\')  last = leng
         if (ichar(letter) .eq. 92)  last = leng
         if (letter .eq. ']')  last = leng
         if (letter .eq. ':')  last = leng
         if (letter .eq. '~')  last = leng
         if (letter .eq. '.')  last = i - 1
      end do
      leng = min(leng,last)
c
c     set first and last snapshot frames and step increment
c
      first = 0
      last = 0
      step = 0
      query = .true.
      call nextarg (string,exist)
      if (exist) then
         read (string,*,err=30,end=30)  first
         query = .false.
      end if
      call nextarg (string,exist)
      if (exist)  read (string,*,err=30,end=30)  last
      call nextarg (string,exist)
      if (exist)  read (string,*,err=30,end=30)  step
   30 continue
      if (query) then
         write (iout,40)
   40    format (/,' Numbers of First & Last File and Step',
     &              ' Increment :  ',$)
         read (input,50)  string
   50    format (a120)
         read (string,*,err=60,end=60)  first,last,step
   60    continue
      end if
      if (last .eq. 0)  last = first
      if (step .eq. 0)  step = 1
c
c     set the maximum frame separation to be used for correlation
c
      maxgap = last - first
      query = .true.
      call nextarg (string,exist)
      if (exist) then
         read (string,*,err=70,end=70)  maxgap
         query = .false.
      end if
   70 continue
      if (query) then
         write (iout,80)
   80    format (/,' Maximum Frame Separation to be Used in',
     &              ' Correlation [ALL] :  ',$)
         read (input,90)  string
   90    format (a120)
         read (string,*,err=100,end=100)  maxgap
  100    continue
      end if
      if (maxgap .eq. 0)  maxgap = last - first
c
c     get the number of file blocks from the total files
c
      nfile = 1 + (last-first)/step
      nblock = 1 + (nfile-1)/maxblock
      blksize = maxblock * step
      blkgap = 1 + (maxgap-1)/blksize
      write (iout,110)  nblock,min(nfile,maxblock)
  110 format (/,' Correlation Function Computed using',i5,
     &           ' Blocks of',i6,' Frames')
c
c     zero out the time correlation function cumulative values
c
      do i = 0, maxgap
         icorr(i) = 0
         vcorr(i) = 0.0d0
      end do
c
c     cycle over all pairs of snapshot frame blocks
c
      do i = 1, nblock
         start = first + (i-1) * blksize
         stop = start + blksize - step
         stop = min(last,stop)
         call readblk (start,stop,step,n1,t1,x1,y1,z1)
         write (iout,120)  i
  120    format (/,3x,'Correlation within Frame Block :    ',i8)
c
c     compute time correlation for frames within single block
c
         do k = 1, n1
            do m = k, n1
               dt = t1(m) - t1(k)
               if (dt .le. maxgap) then
                  value = property (k,x1,y1,z1,m,x1,y1,z1)
                  icorr(dt) = icorr(dt) + 1
                  vcorr(dt) = vcorr(dt) + value
               end if
            end do
         end do
c
c     compute time correlation for frames between two blocks
c
         do j = i+1, min(i+blkgap,nblock)
            start = first + (j-1) * blksize
            stop = start + blksize - step
            stop = min(last,stop)
            blkdiff = (j-i) * maxblock
            call readblk (start,stop,step,n2,t2,x2,y2,z2)
            write (iout,130)  i,j
  130       format (3x,'Correlation between Frame Blocks :  ',2i8)
            do k = 1, n1
               do m = 1, n2
                  dt = t2(m) - t1(k) + blkdiff
                  if (dt .le. maxgap) then
                     value = property (k,x1,y1,z1,m,x2,y2,z2)
                     icorr(dt) = icorr(dt) + 1
                     vcorr(dt) = vcorr(dt) + value
                  end if
               end do
            end do
         end do
      end do
c
c     compute the average correlation function values
c
      do i = 0, maxgap
         if (icorr(i) .ne. 0)  vcorr(i) = vcorr(i)/dble(icorr(i))
      end do
c
c     get the normalized correlation function if applicable
c
      normal = .false.
      if (vcorr(0) .ne. 0.0d0)  normal = .true.
      if (normal) then
         do i = 0, maxgap
            ucorr(i) = vcorr(i) / vcorr(0)
         end do
      end if
c
c     print the final values of the correlation function
c
      if (normal) then
         write (iout,140)
  140    format (/,3x,'Separation',7x,'Samples',8x,'Average Value',
     &              7x,'Normalized',/)
         do i = 0, maxgap
            if (icorr(i) .ne. 0) then
               write (iout,150)  i*step,icorr(i),vcorr(i),ucorr(i)
  150          format (i9,6x,i10,6x,2f17.6)
            end if
         end do
      else
         write (iout,160)
  160    format (/,3x,'Separation',7x,'Samples',8x,'Average Value',/)
         do i = 0, maxgap
            if (icorr(i) .ne. 0) then
               write (iout,170)  i*step,icorr(i),vcorr(i)
  170          format (i9,6x,i10,6x,f17.6)
            end if
         end do
      end if
c
c     perform any final tasks before program exit
c
      call final
      end
c
c
c     ###############################################################
c     ##                                                           ##
c     ##  subroutine readblk  --  read a block of snapshot frames  ##
c     ##                                                           ##
c     ###############################################################
c
c
c     "readblk" reads in a set of snapshot frames and transfers
c     the values to internal arrays for use in the computation
c     of time correlation functions
c
c
      subroutine readblk (start,stop,step,nb,tb,xb,yb,zb)
      implicit none
      include 'sizes.i'
      include 'atmtyp.i'
      include 'atoms.i'
      include 'files.i'
      include 'iounit.i'
      integer maxsite,maxblock
      parameter (maxsite=1000)
      parameter (maxblock=1000)
      integer i,k,ixyz
      integer start,stop
      integer next,label
      integer step,lext
      integer nt,nb,freeunit
      integer tb(maxblock)
      real*8 xb(maxsite,maxblock)
      real*8 yb(maxsite,maxblock)
      real*8 zb(maxsite,maxblock)
      logical exist
      character*7 ext
      character*120 record
      character*120 string
      character*120 xyzfile
c
c
c     initialize the number of files and the numeral size
c
      nt = 0
      nb = 0
      lext = 3
c
c     cycle over all snapshot frames in the block of files
c
      do i = start, stop, step
         nt = nt + 1
         call numeral (i,ext,lext)
         xyzfile = filename(1:leng)//'.'//ext(1:lext)
         inquire (file=xyzfile,exist=exist)
c
c     add file to the current block and get number of atoms
c
         if (exist) then
            nb = nb + 1
            tb(nb) = nt
            ixyz = freeunit ()
            open (unit=ixyz,file=xyzfile,status='old')
            read (ixyz,10)  record
   10       format (a120)
            read (record,*)  n
c
c     check for too many correlation sites in the frame
c
            if (n .gt. maxsite) then
               write (iout,20)  maxsite
   20          format (/,' READBLK  --  Too many Correlation Sites;',
     &                    ' Increase MAXSITE')
               call fatal
            end if
c
c     read the frame in the TINKER-generated coordinate format;
c     this is fast, but assumes the fixed format shown below
c
c           do k = 1, n
c              read (ixyz,30)  name(k),xb(k,nb),yb(k,nb),zb(k,nb)
c  30          format (8x,a3,3f12.6)
c           end do
c
c     alternatively, get each frame from a free formated file;
c     this is slow, but correctly handles any valid TINKER file
c
            do k = 1, n
               next = 1
               read (ixyz,40)  record
   40          format (a120)
               read (record,*)  label
               call getword (record,name(k),next)
               string = record(next:120)
               read (string,*)  xb(k,nb),yb(k,nb),zb(k,nb)
            end do
            close (unit=ixyz)
         end if
      end do
      return
      end
c
c
c     #################################################################
c     ##                                                             ##
c     ##  function property  --  compute correlation property value  ##
c     ##                                                             ##
c     #################################################################
c
c
c     "property" takes two input snapshot frames and computes the
c     value of the property for which the correlation function is
c     being accumulated
c
c     this version of "property" finds the velocity autocorrelation
c     or the rms fit as a function of time, and is merely provided
c     as an example; the user will need to write a similar custom
c     function to compute other properties to be correlated
c
c
      function property (i,xi,yi,zi,k,xk,yk,zk)
      implicit none
      include 'sizes.i'
      include 'atoms.i'
      integer maxsite,maxblock
      parameter (maxsite=1000)
      parameter (maxblock=1000)
      integer i,j,k
      real*8 property,value
      real*8 x1(maxsite)
      real*8 y1(maxsite)
      real*8 z1(maxsite)
      real*8 x2(maxsite)
      real*8 y2(maxsite)
      real*8 z2(maxsite)
      real*8 xi(maxsite,maxblock)
      real*8 yi(maxsite,maxblock)
      real*8 zi(maxsite,maxblock)
      real*8 xk(maxsite,maxblock)
      real*8 yk(maxsite,maxblock)
      real*8 zk(maxsite,maxblock)
c
c
c     transfer the input trajectory frames to local vectors
c
      value = 0.0d0
      do j = 1, n
         x1(j) = xi(j,i)
         y1(j) = yi(j,i)
         z1(j) = zi(j,i)
         x2(j) = xk(j,k)
         y2(j) = yk(j,k)
         z2(j) = zk(j,k)
      end do
c
c     sample code to find the velocity autocorrelation function
c
      do j = 1, n
         value = value + x1(j)*x2(j) + y1(j)*y2(j) + z1(j)*z2(j)
      end do
c
c     sample code to find the rms deviation upon superposition
c
c     call impose (n,x1,y1,z1,n,x2,y2,z2,value)
c
c     set property value to be returned for this frame pair
c
      property = value
      return
      end
