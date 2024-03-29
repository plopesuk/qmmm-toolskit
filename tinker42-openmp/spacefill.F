 
C     $Id$
c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1990  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     ###############################################################
c     ##                                                           ##
c     ##  program spacefill  --  surface area and volume of model  ##
c     ##                                                           ##
c     ###############################################################
c
c
c     "spacefill" computes the surface area and volume of
c     a structure; the van der Waals, accessible-excluded,
c     and contact-reentrant definitions are available
c
c
      program spacefill
      implicit none
      include 'sizes.i'
      include 'atmtyp.i'
      include 'atoms.i'
      include 'files.i'
      include 'inform.i'
      include 'iounit.i'
      include 'kvdws.i'
      include 'math.i'
      include 'usage.i'
      integer i,ixyz,next
      integer mode,frame
      integer freeunit
      real*8 volume,area,value
      real*8 probe,exclude
      real*8 radius(maxatm)
      logical exist,query
      character*1 answer
      character*120 xyzfile
      character*120 record
      character*120 string
c
c
c     get the Cartesian coordinates for the system
c
      call initial
      call getxyz
c
c     determine the atoms to be used in computation;
c     radii can be changed via the keyword mechanism
c
      call field
      call active
      call katom
      call kvdw
c
c     turn on extra printing of output information
c
      debug = .true.
      verbose = .true.
c
c     select either vdw, excluded or molecular volume and area
c
      query = .true.
      call nextarg (string,exist)
      if (exist) then
         read (string,*,err=10,end=10)  mode
         query = .false.
      end if
   10 continue
      if (query) then
         write (iout,20)
   20    format (/,' Three Types of Area and Volume can be Computed :',
     &           //,4x,'(1) Van der Waals Area and Volume',
     &           /,4x,'(2) Accessible Area and Excluded Volume',
     &           /,4x,'(3) Contact-Reentrant Area and Volume')
         write (iout,30)
   30    format (/,' Enter the Number of your Choice [1] :  ',$)
         read (input,40)  mode
   40    format (i10)
      end if
      if (mode.ne.2 .and. mode.ne.3)  mode = 1
c
c     set the excluded/accessible and contact/reentrant probes
c
      probe = 0.0d0
      exclude = 0.0d0
      if (mode.eq.2 .or. mode.eq.3) then
         query = .true.
         call nextarg (string,exist)
         if (exist) then
            read (string,*,err=50,end=50)  value
            query = .false.
         end if
   50    continue
         if (query) then
            write (iout,60)
   60       format (/,' Enter a Value for the Probe Radius',
     &                 ' [1.4 Ang] :  ',$)
            read (input,70)  value
   70       format (f20.0)
         end if
         if (value .eq. 0.0d0)  value = 1.4d0
         if (mode .eq. 2)  exclude = value
         if (mode .eq. 3)  probe = value
      end if
c
c     decide whether to include hydrogens in the calculation
c
      call nextarg (answer,exist)
      if (.not. exist) then
         write (iout,80)
   80    format (/,' Include the Hydrogen Atoms in Computation',
     &              ' [N] :  ',$)
         read (input,90)  record
   90    format (a120)
         next = 1
         call gettext (record,answer,next)
      end if
      call upcase (answer)
      if (answer .ne. 'Y') then
         do i = 1, n
            if (atomic(i) .eq. 1)  use(i) = .false.
         end do
      end if
c
c     set each atomic radius to the Lennard-Jones sigma value
c
      do i = 1, n
         if (use(i)) then
            radius(i) = rad(class(i)) / twosix
         else
            radius(i) = 0.0d0
         end if
      end do
c
c     reopen the coordinates file and read the first structure
c
      frame = 0
      ixyz = freeunit ()
      xyzfile = filename
      call suffix (xyzfile,'xyz')
      call version (xyzfile,'old')
      open (unit=ixyz,file=xyzfile,status ='old')
      rewind (unit=ixyz)
      call readxyz (ixyz)
c
c     get area and volume for successive coordinate structures
c
      dowhile (.not. abort)
         frame = frame + 1
         if (frame .gt. 1) then
            write (iout,100)  frame
  100       format (/,' Area and Volume for Archive Structure :',5x,i8)
         end if
c
c     use the Connolly routines to find the area and volume
c
         call connolly (volume,area,radius,probe,exclude)
c
c     print out the values of the total surface area and volume
c
         write (iout,110)  area
  110    format (/,' Total Area :',f20.3,' Square Angstroms')
         write (iout,120)  volume
  120    format (' Total Volume :',f18.3,' Cubic Angstroms')
c
c     attempt to read next structure from the coordinate file
c
         call readxyz (ixyz)
      end do
c
c     perform any final tasks before program exit
c
      close (unit=ixyz)
      debug = .false.
      call final
      end
