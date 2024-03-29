 
C     $Id$
c
c
c     #############################################################
c     ##  COPYRIGHT (C) 2004 by Pengyu Ren & Jay William Ponder  ##
c     ##                   All Rights Reserved                   ##
c     #############################################################
c
c     ##############################################################
c     ##                                                          ##
c     ##  program xtalmin  --  full lattice crystal minimization  ##
c     ##                                                          ##
c     ##############################################################
c
c
c     "xtalmin" performs a full crystal energy minimization by
c     optimizing over fractional atomic coordinates and the six
c     lattice lengths and angles
c
c
      program xtalmin
      implicit none
      include 'sizes.i'
      include 'atoms.i'
      include 'boxes.i'
      include 'files.i'
      include 'inform.i'
      include 'iounit.i'
      include 'keys.i'
      include 'scales.i'
      integer i,j,imin,nvar
      integer next,freeunit
      real*8 minimum,grdmin
      real*8 gnorm,grms
      real*8 glnorm,glrms
      real*8 xtalmin1,e
      real*8 xx(maxvar)
      real*8 glat(maxvar)
      real*8 xf(maxatm)
      real*8 yf(maxatm)
      real*8 zf(maxatm)
      real*8 derivs(3,maxatm)
      logical exist
      character*20 keyword
      character*120 minfile
      character*120 record
      character*120 string
      external xtalmin1
      external optsave
c
c
c     set up the structure and mechanics calculation
c
      call initial
      call getxyz
      call mechanic
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
            read (string,*,err=10,end=10)  iprint
         else if (keyword(1:9) .eq. 'WRITEOUT ') then
            read (string,*,err=10,end=10)  iwrite
         end if
   10    continue
      end do
c
c     get termination criterion as RMS gradient per atom
c
      grdmin = -1.0d0
      call nextarg (string,exist)
      if (exist)  read (string,*,err=20,end=20)  grdmin
   20 continue
      if (grdmin .le. 0.0d0) then
         write (iout,30)
   30    format (/,' Enter RMS Gradient per Atom Criterion',
     &              ' [0.01] :  ',$)
         read (input,40)  grdmin
   40    format (f20.0)
      end if
      if (grdmin .le. 0.0d0)  grdmin = 0.01d0
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
c     write out the initial values of the lattice parameters
c
      write (iout,50)  xbox,ybox,zbox,alpha,beta,gamma
   50 format (/,' Initial Lattice Dimensions :    a   ',f12.4,
     &        /,'                                 b   ',f12.4,
     &        /,'                                 c   ',f12.4,
     &        /,'                                Alpha',f12.4,
     &        /,'                                Beta ',f12.4,
     &        /,'                                Gamma',f12.4)
c
c     set scale factors to apply to optimization variables
c
      set_scale = .true.
      nvar = 0
      do i = 1, n
         nvar = nvar + 1
         scale(nvar) = 12.0d0 * xbox
         nvar = nvar + 1
         scale(nvar) = 12.0d0 * ybox
         nvar = nvar + 1
         scale(nvar) = 12.0d0 * zbox
      end do
      scale(nvar+1) = 4.0d0 * sqrt(xbox)
      scale(nvar+2) = 4.0d0 * sqrt(ybox)
      scale(nvar+3) = 4.0d0 * sqrt(zbox)
      scale(nvar+4) = 0.02d0 * sqrt(volbox)
      scale(nvar+5) = 0.02d0 * sqrt(volbox)
      scale(nvar+6) = 0.02d0 * sqrt(volbox)
c
c     compute the fractional coordinates for each atom
c
      call lattice
      do i = 1, n
         j = 3*i - 3
         xx(j+1) = x(i)*recip(1,1) + y(i)*recip(2,1) + z(i)*recip(3,1)
         xx(j+2) = x(i)*recip(1,2) + y(i)*recip(2,2) + z(i)*recip(3,2)
         xx(j+3) = x(i)*recip(1,3) + y(i)*recip(2,3) + z(i)*recip(3,3)
      end do
c
c     scale the fractional coordinates and lattice parameters
c
      nvar = 3 * n
      do i = 1, nvar
         xx(i) = xx(i) * scale(i)
      end do
      xx(nvar+1) = xbox * scale(nvar+1)
      xx(nvar+2) = ybox * scale(nvar+2)
      xx(nvar+3) = zbox * scale(nvar+3)
      xx(nvar+4) = alpha * scale(nvar+4)
      xx(nvar+5) = beta * scale(nvar+5)
      xx(nvar+6) = gamma * scale(nvar+6)
      nvar = nvar + 6
c
c     make the call to the optimization routine
c
      if (nvar .le. maxopt) then
         call ocvm (nvar,xx,minimum,grdmin,xtalmin1,optsave)
      else
         call lbfgs (nvar,xx,minimum,grdmin,xtalmin1,optsave)
      end if
c
c     unscale fractional coordinates and get atomic coordinates
c
      do i = 1, n
         j = 3*i - 3
         xf(i) = xx(j+1) / scale(j+1)
         yf(i) = xx(j+2) / scale(j+2)
         zf(i) = xx(j+3) / scale(j+3)
      end do
      do i = 1, n
         x(i) = xf(i)*lvec(1,1) + yf(i)*lvec(2,1) + zf(i)*lvec(3,1)
         y(i) = xf(i)*lvec(1,2) + yf(i)*lvec(2,2) + zf(i)*lvec(3,2)
         z(i) = xf(i)*lvec(1,3) + yf(i)*lvec(2,3) + zf(i)*lvec(3,3)
      end do
c
c     compute final energy value and coordinate RMS gradient
c
      call gradient (e,derivs)
      gnorm = 0.0d0
      do i = 1, n
         do j = 1, 3
            gnorm = gnorm + derivs(j,i)**2
         end do
      end do
      gnorm = sqrt(gnorm)
      nvar = 3 * n
      grms = gnorm / sqrt(dble(nvar/3))
c
c     compute the final RMS gradient for lattice parameters
c
      minimum = xtalmin1 (xx,glat)
      glnorm = 0.0d0
      do i = nvar+1, nvar+6
         glnorm = glnorm + (scale(i)*glat(i))**2
      end do
      glnorm = sqrt(glnorm)
      glrms = glnorm / sqrt(6.0d0)
c
c     write out the final energy and coordinate gradients
c
      if (grms.gt.1.0d-4 .and. glrms.gt.1.0d-4) then
         write (iout,60)  minimum,grms,gnorm,glrms,glnorm
   60    format (/,' Final Potential Function Value :',f16.4,
     &           /,' Final RMS Coordinate Gradient : ',f16.4,
     &           /,' Final Coordinate Gradient Norm :',f16.4,
     &           /,' Final RMS Lattice Gradient :    ',f16.4,
     &           /,' Final Lattice Gradient Norm :   ',f16.4)
      else
         write (iout,70)  minimum,grms,gnorm,glrms,glnorm
   70    format (/,' Final Potential Function Value :',f16.4,
     &           /,' Final RMS Coordinate Gradient : ',d16.4,
     &           /,' Final Coordinate Gradient Norm :',d16.4,
     &           /,' Final RMS Lattice Gradient :    ',d16.4,
     &           /,' Final Lattice Gradient Norm :   ',d16.4)
      end if
c
c     write out the final values of the lattice parameters
c
      write (iout,80)  xbox,ybox,zbox,alpha,beta,gamma
   80 format (/,' Final Lattice Dimensions :      a   ',f12.4,
     &        /,'                                 b   ',f12.4,
     &        /,'                                 c   ',f12.4,
     &        /,'                                Alpha',f12.4,
     &        /,'                                Beta ',f12.4,
     &        /,'                                Gamma',f12.4)
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
c     ##############################################################
c     ##                                                          ##
c     ##  function xtalmin1  --  energy and gradient for lattice  ##
c     ##                                                          ##
c     ##############################################################
c
c
c     "xtalmin1" is a service routine that computes the energy and
c     gradient with respect to fractional coordinates and lattice
c     dimensions for a crystal energy minimization
c
c
      function xtalmin1 (xx,g)
      implicit none
      include 'sizes.i'
      include 'atoms.i'
      include 'boxes.i'
      include 'math.i'
      include 'scales.i'
      integer i,j
      real*8 xtalmin1,energy
      real*8 e,e0,old,eps
      real*8 xx(maxvar)
      real*8 g(maxvar)
      real*8 xf(maxatm)
      real*8 yf(maxatm)
      real*8 zf(maxatm)
      real*8 derivs(3,maxatm)
c
c
c     translate optimization variables to fractional coordinates
c
      do i = 1, n
         j = 3*i - 3
         xf(i) = xx(j+1) / scale(j+1)
         yf(i) = xx(j+2) / scale(j+2)
         zf(i) = xx(j+3) / scale(j+3)
      end do
c
c     translate optimization variables to lattice parameters
c
      xbox = xx(3*n+1) / scale(3*n+1)
      ybox = xx(3*n+2) / scale(3*n+2)
      zbox = xx(3*n+3) / scale(3*n+3)
      alpha = xx(3*n+4) / scale(3*n+4)
      beta = xx(3*n+5) / scale(3*n+5)
      gamma = xx(3*n+6) / scale(3*n+6)
c
c     update current atomic coordinates based on optimization values
c
      call lattice
      do i = 1, n
         x(i) = xf(i)*lvec(1,1) + yf(i)*lvec(2,1) + zf(i)*lvec(3,1)
         y(i) = xf(i)*lvec(1,2) + yf(i)*lvec(2,2) + zf(i)*lvec(3,2)
         z(i) = xf(i)*lvec(1,3) + yf(i)*lvec(2,3) + zf(i)*lvec(3,3)
      end do
c
c     find energy and fractional coordinates deriviatives
c
      call gradient (e,derivs)
      xtalmin1 = e
      do i = 1, n
         j = 3*i - 3
         g(j+1) = derivs(1,i)*lvec(1,1) + derivs(2,i)*lvec(1,2)
     &               + derivs(3,i)*lvec(1,3)
         g(j+2) = derivs(1,i)*lvec(2,1) + derivs(2,i)*lvec(2,2)
     &               + derivs(3,i)*lvec(2,3)
         g(j+3) = derivs(1,i)*lvec(3,1) + derivs(2,i)*lvec(3,2)
     &               + derivs(3,i)*lvec(3,3)
      end do
c
c     find derivative with respect to lattice a-axis length
c
      eps = 0.0001d0
      old = xbox
      xbox = xbox - 0.5d0*eps
      call lattice
      do i = 1, n
         x(i) = xf(i)*lvec(1,1) + yf(i)*lvec(2,1) + zf(i)*lvec(3,1)
         y(i) = xf(i)*lvec(1,2) + yf(i)*lvec(2,2) + zf(i)*lvec(3,2)
         z(i) = xf(i)*lvec(1,3) + yf(i)*lvec(2,3) + zf(i)*lvec(3,3)
      end do
      e0 = energy ()
      xbox = xbox + eps
      call lattice
      do i = 1, n
         x(i) = xf(i)*lvec(1,1) + yf(i)*lvec(2,1) + zf(i)*lvec(3,1)
         y(i) = xf(i)*lvec(1,2) + yf(i)*lvec(2,2) + zf(i)*lvec(3,2)
         z(i) = xf(i)*lvec(1,3) + yf(i)*lvec(2,3) + zf(i)*lvec(3,3)
      end do
      e = energy ()
      g(3*n+1) = (e - e0) / eps
      xbox = old
c
c     find derivative with respect to lattice b-axis length
c
      old = ybox
      ybox = ybox - 0.5d0*eps
      call lattice
      do i = 1, n
         x(i) = xf(i)*lvec(1,1) + yf(i)*lvec(2,1) + zf(i)*lvec(3,1)
         y(i) = xf(i)*lvec(1,2) + yf(i)*lvec(2,2) + zf(i)*lvec(3,2)
         z(i) = xf(i)*lvec(1,3) + yf(i)*lvec(2,3) + zf(i)*lvec(3,3)
      end do
      e0 = energy ()
      ybox = ybox + eps
      call lattice
      do i = 1, n
         x(i) = xf(i)*lvec(1,1) + yf(i)*lvec(2,1) + zf(i)*lvec(3,1)
         y(i) = xf(i)*lvec(1,2) + yf(i)*lvec(2,2) + zf(i)*lvec(3,2)
         z(i) = xf(i)*lvec(1,3) + yf(i)*lvec(2,3) + zf(i)*lvec(3,3)
      end do
      e = energy ()
      g(3*n+2) = (e - e0) / eps
      ybox = old
c
c     find derivative with respect to lattice c-axis length
c
      old = zbox
      zbox = zbox - 0.5d0*eps
      call lattice
      do i = 1, n
         x(i) = xf(i)*lvec(1,1) + yf(i)*lvec(2,1) + zf(i)*lvec(3,1)
         y(i) = xf(i)*lvec(1,2) + yf(i)*lvec(2,2) + zf(i)*lvec(3,2)
         z(i) = xf(i)*lvec(1,3) + yf(i)*lvec(2,3) + zf(i)*lvec(3,3)
      end do
      e0 = energy ()
      zbox = zbox + eps
      call lattice
      do i = 1, n
         x(i) = xf(i)*lvec(1,1) + yf(i)*lvec(2,1) + zf(i)*lvec(3,1)
         y(i) = xf(i)*lvec(1,2) + yf(i)*lvec(2,2) + zf(i)*lvec(3,2)
         z(i) = xf(i)*lvec(1,3) + yf(i)*lvec(2,3) + zf(i)*lvec(3,3)
      end do
      e = energy ()
      g(3*n+3) = (e - e0) / eps
      zbox = old
c
c     find derivative with respect to lattice alpha angle
c
      eps = eps * radian
      old = alpha
      alpha = alpha - 0.5d0*eps
      call lattice
      do i = 1, n
         x(i) = xf(i)*lvec(1,1) + yf(i)*lvec(2,1) + zf(i)*lvec(3,1)
         y(i) = xf(i)*lvec(1,2) + yf(i)*lvec(2,2) + zf(i)*lvec(3,2)
         z(i) = xf(i)*lvec(1,3) + yf(i)*lvec(2,3) + zf(i)*lvec(3,3)
      end do
      e0 = energy ()
      alpha = alpha + eps
      call lattice
      do i = 1, n
         x(i) = xf(i)*lvec(1,1) + yf(i)*lvec(2,1) + zf(i)*lvec(3,1)
         y(i) = xf(i)*lvec(1,2) + yf(i)*lvec(2,2) + zf(i)*lvec(3,2)
         z(i) = xf(i)*lvec(1,3) + yf(i)*lvec(2,3) + zf(i)*lvec(3,3)
      end do
      e = energy ()
      g(3*n+4) = (e - e0) / eps
      alpha = old
c
c     find derivative with respect to lattice beta angle
c
      old = beta
      beta = beta - 0.5d0*eps
      call lattice
      do i = 1, n
         x(i) = xf(i)*lvec(1,1) + yf(i)*lvec(2,1) + zf(i)*lvec(3,1)
         y(i) = xf(i)*lvec(1,2) + yf(i)*lvec(2,2) + zf(i)*lvec(3,2)
         z(i) = xf(i)*lvec(1,3) + yf(i)*lvec(2,3) + zf(i)*lvec(3,3)
      end do
      e0 = energy ()
      beta = beta + eps
      call lattice
      do i = 1, n
         x(i) = xf(i)*lvec(1,1) + yf(i)*lvec(2,1) + zf(i)*lvec(3,1)
         y(i) = xf(i)*lvec(1,2) + yf(i)*lvec(2,2) + zf(i)*lvec(3,2)
         z(i) = xf(i)*lvec(1,3) + yf(i)*lvec(2,3) + zf(i)*lvec(3,3)
      end do
      e = energy ()
      g(3*n+5) = (e - e0) / eps
      beta = old
c
c     find derivative with respect to lattice gamma angle
c
      old = gamma
      gamma = gamma - 0.5d0*eps
      call lattice
      do i = 1, n
         x(i) = xf(i)*lvec(1,1) + yf(i)*lvec(2,1) + zf(i)*lvec(3,1)
         y(i) = xf(i)*lvec(1,2) + yf(i)*lvec(2,2) + zf(i)*lvec(3,2)
         z(i) = xf(i)*lvec(1,3) + yf(i)*lvec(2,3) + zf(i)*lvec(3,3)
      end do
      e0 = energy ()
      gamma = gamma + eps
      call lattice
      do i = 1, n
         x(i) = xf(i)*lvec(1,1) + yf(i)*lvec(2,1) + zf(i)*lvec(3,1)
         y(i) = xf(i)*lvec(1,2) + yf(i)*lvec(2,2) + zf(i)*lvec(3,2)
         z(i) = xf(i)*lvec(1,3) + yf(i)*lvec(2,3) + zf(i)*lvec(3,3)
      end do
      e = energy ()
      g(3*n+6) = (e - e0) / eps
      gamma = old
c
c     revert to the original atomic coordinate values
c
      call lattice
      do i = 1, n
         x(i) = xf(i)*lvec(1,1) + yf(i)*lvec(2,1) + zf(i)*lvec(3,1)
         y(i) = xf(i)*lvec(1,2) + yf(i)*lvec(2,2) + zf(i)*lvec(3,2)
         z(i) = xf(i)*lvec(1,3) + yf(i)*lvec(2,3) + zf(i)*lvec(3,3)
      end do
c
c     apply scale factors to the coordinate and lattice gradient
c
      do i = 1, 3*n+6
         g(i) = g(i) / scale(i)
      end do
      return
      end
