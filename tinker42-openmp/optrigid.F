 
C     $Id$
c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1997  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     ##################################################################
c     ##                                                              ##
c     ##  program optrigid  --  variable metric rigid body optimizer  ##
c     ##                                                              ##
c     ##################################################################
c
c
c     "optrigid" performs an energy minimization of rigid body atom
c     groups using an optimally conditioned variable metric method
c
c
      program optrigid
      implicit none
      include 'sizes.i'
      include 'files.i'
      include 'group.i'
      include 'inform.i'
      include 'iounit.i'
      include 'keys.i'
      include 'output.i'
      include 'rigid.i'
      integer i,j,imin,nvar
      integer next,freeunit
      real*8 optrigid1,minimum
      real*8 grdmin,grms,gnorm
      real*8 xx(maxopt)
      real*8 derivs(6,maxgrp)
      character*20 keyword
      character*120 minfile
      character*120 record
      character*120 string
      logical exist
      external optrigid1
      external optsave
c
c
c     set up the molecular mechanics calculation
c
      call initial
      call getxyz
      call mechanic
c
c     set up the use of rigid body coordinate system
c
      use_rigid = .true.
      call orient
c
c     check for too many parameters to be optimized
c
      if (ngrp*6 .gt. maxopt) then
         write (iout,10)
   10    format (/,' OPTRIGID  --  Too many Parameters,',
     &              ' Increase the Value of MAXOPT')
         call fatal
      end if
c
c     search the keywords for output frequency parameters
c
      do i = 1, nkey
         next = 1
         record = keyline(i)
         call gettext (record,keyword,next)
         call upcase (keyword)
         string = record(next:120)
         if (keyword(1:9) .eq. 'PRINTOUT ') then
            read (string,*,err=20,end=20)  iprint
         else if (keyword(1:9) .eq. 'WRITEOUT ') then
            read (string,*,err=20,end=20)  iwrite
         end if
   20    continue
      end do
c
c     get termination criterion as RMS rigid body gradient
c
      grdmin = -1.0d0
      call nextarg (string,exist)
      if (exist)  read (string,*,err=30,end=30)  grdmin
   30 continue
      if (grdmin .le. 0.0d0) then
         write (iout,40)
   40    format (/,' Enter RMS Gradient per Rigid Body Criterion',
     &              ' [0.01] :  ',$)
         read (input,50)  grdmin
   50    format (f20.0)
      end if
      if (grdmin .eq. 0.0d0)  grdmin = 0.01d0
c
c     write out a copy of coordinates for later update
c
      imin = freeunit ()
      minfile = filename(1:leng)//'.xyz'
      call version (minfile,'new')
      open (unit=imin,file=minfile,status='new')
      call prtxyz (imin)
      close (unit=imin)
      outfile = minfile
c
c     transfer rigid body coordinates to optimization parameters
c
      nvar = 0
      do i = 1, ngrp
         do j = 1, 6
            nvar = nvar + 1
            xx(nvar) = rbc(j,i)
         end do
      end do
c
c     check for too many parameters to be optimized
c
      if (nvar .gt. maxopt) then
         write (iout,60)
   60    format (/,' OPTRIGID  --  Too many Parameters,',
     &              ' Increase the Value of MAXOPT')
         call fatal
      end if
c
c     make the call to the optimization routine
c
      coordtype = 'RIGIDBODY'
      call ocvm (nvar,xx,minimum,grdmin,optrigid1,optsave)
c
c     transfer optimization parameters to rigid body coordinates
c
      nvar = 0
      do i = 1, ngrp
         do j = 1, 6
            nvar = nvar + 1
            rbc(j,i) = xx(nvar)
         end do
      end do
c
c     compute the final function and RMS gradient values
c
      call gradrgd (minimum,derivs)
      gnorm = 0.0d0
      do i = 1, ngrp
         do j = 1, 6
            gnorm = gnorm + derivs(j,i)**2
         end do
      end do
      gnorm = sqrt(gnorm)
      grms = gnorm / sqrt(dble(ngrp))
c
c     write out the final function and gradient values
c
      if (digits .ge. 8) then
         if (grms .gt. 1.0d-8) then
            write (iout,70)  minimum,grms,gnorm
   70       format (/,' Final Function Value :',2x,f20.8,
     &              /,' Final RMS Gradient :',4x,f20.8,
     &              /,' Final Gradient Norm :',3x,f20.8)
         else
            write (iout,80)  minimum,grms,gnorm
   80       format (/,' Final Function Value :',2x,f20.8,
     &              /,' Final RMS Gradient :',4x,d20.8,
     &              /,' Final Gradient Norm :',3x,d20.8)
         end if
      else if (digits .ge. 6) then
         if (grms .gt. 1.0d-6) then
            write (iout,90)  minimum,grms,gnorm
   90       format (/,' Final Function Value :',2x,f18.6,
     &              /,' Final RMS Gradient :',4x,f18.6,
     &              /,' Final Gradient Norm :',3x,f18.6)
         else
            write (iout,100)  minimum,grms,gnorm
  100       format (/,' Final Function Value :',2x,f18.6,
     &              /,' Final RMS Gradient :',4x,d18.6,
     &              /,' Final Gradient Norm :',3x,d18.6)
         end if
      else
         if (grms .gt. 1.0d-4) then
            write (iout,110)  minimum,grms,gnorm
  110       format (/,' Final Function Value :',2x,f16.4,
     &              /,' Final RMS Gradient :',4x,f16.4,
     &              /,' Final Gradient Norm :',3x,f16.4)
         else
            write (iout,120)  minimum,grms,gnorm
  120       format (/,' Final Function Value :',2x,f16.4,
     &              /,' Final RMS Gradient :',4x,d16.4,
     &              /,' Final Gradient Norm :',3x,d16.4)
         end if
      end if
c
c     write the final coordinates into a file
c
      imin = freeunit ()
      open (unit=imin,file=minfile,status='old')
      rewind (unit=imin)
      call prtxyz (imin)
      close (unit=imin)
c
c     perform any final tasks before program exit
c
      call final
      end
c
c
c     ################################################################
c     ##                                                            ##
c     ##  function optrigid1  --  energy and gradient for optrigid  ##
c     ##                                                            ##
c     ################################################################
c
c
c     "optrigid1" is a service routine that computes the energy
c     and gradient for optimally conditioned variable metric
c     optimization of rigid bodies
c
c
      function optrigid1 (xx,g)
      implicit none
      include 'sizes.i'
      include 'group.i'
      include 'math.i'
      include 'rigid.i'
      integer i,j,nvar
      real*8 optrigid1,e
      real*8 xx(maxopt)
      real*8 g(maxopt)
      real*8 derivs(6,maxgrp)
c
c
c     translate optimization parameters to rigid body coordinates
c
      nvar = 0
      do i = 1, ngrp
         do j = 1, 6
            nvar = nvar + 1
            rbc(j,i) = xx(nvar)
         end do
      end do
c
c     compute and store the energy and gradient
c
      call rigidxyz
      call gradrgd (e,derivs)
      optrigid1 = e
c
c     store rigid body gradient as optimization gradient
c
      nvar = 0
      do i = 1, ngrp
         do j = 1, 6
            nvar = nvar + 1
            g(nvar) = derivs(j,i)
         end do
      end do
      return
      end
