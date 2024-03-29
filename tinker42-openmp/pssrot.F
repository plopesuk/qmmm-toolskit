 
C     $Id$
c
c
c     ##############################################################
c     ##  COPYRIGHT (C) 1997 by Rohit Pappu & Jay William Ponder  ##
c     ##                   All Rights Reserved                    ##
c     ##############################################################
c
c     ##################################################################
c     ##                                                              ##
c     ##  program pssrot  --  torsional potential smoothing & search  ##
c     ##                                                              ##
c     ##################################################################
c
c
c     "pssrot" implements the potential smoothing plus search method
c     for global optimization in torsional space
c
c     literature reference:
c
c     J. Kostrowicki and H. A. Scheraga, "Application of the Diffusion
c     Equation Method for Global Optimization to Oligopeptides", Journal
c     of Physical Chemistry, 96, 7442-7449 (1992)
c
c     S. Nakamura, H. Hirose, M. Ikeguchi and J. Doi, "Conformational
c     Energy Minimization Using a Two-Stage Method", Journal of Physical
c     Chemistry, 99, 8374-8378 (1995)
c
c
      program pssrot
      implicit none
      include 'sizes.i'
      include 'atoms.i'
      include 'files.i'
      include 'inform.i'
      include 'iounit.i'
      include 'math.i'
      include 'omega.i'
      include 'refer.i'
      include 'warp.i'
      include 'zcoord.i'
      integer i,k
      integer ixyz,next
      integer npoint,neigen
      integer lext,freeunit
      real*8 minimum,grdmin
      real*8 pssrot1,rms
      real*8 srchmax
      real*8 deform0,ratio
      real*8 xx(maxvar)
      logical exist
      logical use_local
      character*1 answer
      character*7 ext
      character*120 coordfile
      character*120 record
      character*120 string
      external pssrot1
      external optsave
c
c
c     set up the structure, mechanics calculation and smoothing
c
      call initial
      call getxyz
      use_smooth = .true.
      use_dem = .true.
      call mechanic
      call initrot
c
c     convert to Cartesian coordinates and save the initial set
c
      call makexyz
      call makeref
c
c     set maximum deformation value and disable coordinate dumps
c
      deform0 = deform
      iwrite = 0
c
c     get the number of points along the deformation schedule
c
      npoint = -1
      call nextarg (string,exist)
      if (exist)  read (string,*,err=10,end=10)  npoint
   10 continue
      if (npoint .lt. 0) then
         write (iout,20)
   20    format (/,' Enter the Number of Steps for the PSS Schedule',
     &              ' [100] :  ',$)
         read (input,30)  npoint
   30    format (i10)
         if (npoint .le. 0)  npoint = 100
      end if
c
c     decide whether to use the local search procedure
c
      use_local = .false.
      call nextarg (answer,exist)
      if (.not. exist) then
         write (iout,40)
   40    format (/,' Use Local Search to Explore the Smoothing Levels',
     &              ' [N] :  ',$)
         read (input,50)  record
   50    format (a120)
         next = 1
         call gettext (record,answer,next)
      end if
      call upcase (answer)
      if (answer .eq. 'Y')  use_local = .true.
c
c     get the number of eigenvectors to use for the local search
c
      if (use_local) then
         neigen = -1
         call nextarg (string,exist)
         if (exist)  read (string,*,err=60,end=60)  neigen
   60    continue
         if (neigen .le. 0) then
            write (iout,70)
   70       format (/,' Enter the Number of Directions for Local',
     &                 ' Search [5] :  ',$)
            read (input,80)  neigen
   80       format (i10)
            if (neigen .le. 0)  neigen = 5
         end if
      end if
c
c     get the maximal smoothing level for use of local search
c
      if (use_local) then
         srchmax = -1.0d0
         call nextarg (string,exist)
         if (exist)  read (string,*,err=90,end=90)  srchmax
   90    continue
         if (srchmax .lt. 0.0d0) then
            write (iout,100)
  100       format (/,' Enter the Largest Smoothing Value for Local',
     &                 ' Search [5.0] :  ',$)
            read (input,110)  srchmax
  110       format (f20.0)
            if (srchmax .lt. 0.0d0)  srchmax = 5.0d0
         end if
      end if
c
c     get the termination criterion as RMS gradient per atom
c
      grdmin = -1.0d0
      call nextarg (string,exist)
      if (exist)  read (string,*,err=120,end=120)  grdmin
  120 continue
      if (grdmin .le. 0.0d0) then
         write (iout,130)
  130    format (/,' Enter RMS Gradient per Atom Criterion',
     &              ' [0.0001] :  ',$)
         read (input,140)  grdmin
  140    format (f20.0)
      end if
      if (grdmin .le. 0.0d0)  grdmin = 0.0001d0
c
c     perform PSS iteration by looping over smoothed surfaces
c
      do k = 0, 2*npoint
         ratio = 1.0d0 - dble(abs(npoint-k))/dble(npoint)
         deform = deform0 * ratio**3
c
c     translate the initial coordinates
c
         do i = 1, nomega
            xx(i) = dihed(i)
         end do
c
c     make the call to the variable metric optimization routine
c
         iprint = 1
         call ocvm (nomega,xx,minimum,grdmin,pssrot1,optsave)
c
c     untranslate the final coordinates for each atom
c
         do i = 1, nomega
            dihed(i) = xx(i)
            ztors(zline(i)) = dihed(i) * radian
         end do
c
c     use normal mode local search to explore adjacent minima
c
         if (use_local) then
            if (k.ge.npoint .and. deform.le.srchmax)
     &         call moderot (neigen,minimum,grdmin)
         end if
c
c     write out final energy function value and smoothing level
c
         write (iout,150)  minimum,deform
  150    format (/,' Final Function Value and Deformation :',2f15.4)
c
c     get Cartesian coordinates and superimpose on reference
c
         call makexyz
         call impose (n,xref,yref,zref,n,x,y,z,rms)
c
c     write the coordinates of the current minimum to a file
c
         lext = 3
         call numeral (k,ext,lext)
         ixyz = freeunit ()
         coordfile = filename(1:leng)//'.'//ext(1:lext)
         call version (coordfile,'new')
         open (unit=ixyz,file=coordfile,status='new')
         call prtxyz (ixyz)
         close (unit=ixyz)
      end do
c
c     perform any final tasks before program exit
c
      call final
      end
c
c
c     ################################################################
c     ##                                                            ##
c     ##  function pssrot1  --  energy and gradient values for PSS  ##
c     ##                                                            ##
c     ################################################################
c
c
c     "pssrot1" is a service routine that computes the energy and
c     gradient during PSS global optimization in torsional space
c
c
      function pssrot1 (xx,g)
      implicit none
      include 'sizes.i'
      include 'math.i'
      include 'omega.i'
      include 'zcoord.i'
      integer i
      real*8 pssrot1,e
      real*8 xx(maxvar)
      real*8 g(maxvar)
      real*8 derivs(maxrot)
c
c
c     translate optimization variables into dihedrals
c
      do i = 1, nomega
         dihed(i) = xx(i)
         ztors(zline(i)) = dihed(i) * radian
      end do
c
c     compute and store the energy and gradient
c
      call makexyz
      call gradrot (e,derivs)
      pssrot1 = e
c
c     store torsional gradient as optimization gradient
c
      do i = 1, nomega
         g(i) = derivs(i)
      end do
      return
      end
c
c
c     ##############################################################
c     ##                                                          ##
c     ##  subroutine moderot  --  torsional local search for PSS  ##
c     ##                                                          ##
c     ##############################################################
c
c
      subroutine moderot (neigen,minimum,grdmin)
      implicit none
      include 'sizes.i'
      include 'iounit.i'
      include 'math.i'
      include 'omega.i'
      include 'zcoord.i'
      integer i,k,neigen
      integer ndoi,nsearch
      real*8 minimum,grdmin
      real*8 minref,minbest
      real*8 eps,step(maxrot)
      real*8 zorig(maxrot)
      real*8 zbest(maxrot)
      real*8 eigen(maxrot)
      real*8 vects(maxrot,maxrot)
      logical done
c
c
c     set parameters related to the local search procedure
c
      done = .false.
      eps = 0.0001d0
      minref = minimum
      minbest = minimum
      ndoi = 0
      do k = 1, nomega
         zorig(k) = ztors(zline(k))
      end do
c
c     find local minimum along each of the steepest directions
c
      dowhile (.not. done)
         ndoi = ndoi + 1
         write (iout,10)  ndoi,minref
   10    format (/,' Torsional Mode Search :',5x,'Iteration',i4,
     &              6x,'Energy',f12.4,/)
         call makexyz
         call eigenrot (eigen,vects)
c
c     search both directions along each eigenvector in turn
c
         nsearch = 0
         do i = 1, neigen
            do k = 1, nomega
               step(k) = vects(k,nomega-i+1)
               ztors(zline(k)) = zorig(k)
            end do
            nsearch = nsearch + 1
            call climbrot (nsearch,minimum,step,grdmin)
            if (minimum .lt. minbest) then
               minbest = minimum
               do k = 1, nomega
                  zbest(k) = ztors(zline(k))
               end do
            end if
            do k = 1, nomega
               step(k) = -vects(k,nomega-i+1)
               ztors(zline(k)) = zorig(k)
            end do
            nsearch = nsearch + 1
            call climbrot (nsearch,minimum,step,grdmin)
            if (minimum .lt. minbest) then
               minbest = minimum
               do k = 1, nomega
                  zbest(k) = ztors(zline(k))
               end do
            end if
         end do
c
c     check for convergence of the local search procedure
c
         if (minbest .lt. minref-eps) then
            done = .false.
            minref = minbest
            do k = 1, nomega
               zorig(k) = zbest(k)
            end do
         else
            done = .true.
            minimum = minref
            do k = 1, nomega
               dihed(k) = zorig(k) / radian
               ztors(zline(k)) = zorig(k)
            end do
         end if
      end do
      return
      end
c
c
c     ###############################################################
c     ##                                                           ##
c     ##  subroutine eigenrot  --  torsional Hessian eigenvectors  ##
c     ##                                                           ##
c     ###############################################################
c
c
      subroutine eigenrot (eigen,vects)
      implicit none
      include 'sizes.i'
      include 'atoms.i'
      include 'omega.i'
      integer i,j,ihess
      real*8 hrot(maxrot,maxrot)
      real*8 matrix((maxrot+1)*maxrot/2)
      real*8 a(maxrot+1),b(maxrot+1)
      real*8 p(maxrot+1),ta(maxrot+1)
      real*8 w(maxrot+1),tb(maxrot+1)
      real*8 ty(maxrot+1)
      real*8 eigen(maxrot)
      real*8 vects(maxrot,maxrot)
c
c
c     compute the Hessian in torsional space
c
      call hessrot ('FULL',hrot)
c
c     place Hessian elements into triangular form
c
      ihess = 0
      do i = 1, nomega
         do j = i, nomega
            ihess = ihess + 1
            matrix(ihess) = hrot(i,j)
         end do
      end do
c
c     diagonalize the Hessian to obtain eigenvalues
c
      call diagq (nomega,maxrot,nomega,matrix,eigen,vects,
     &                     a,b,p,w,ta,tb,ty)
      return
      end
c
c
c     ################################################################
c     ##                                                            ##
c     ##  subroutine climbrot  --  minimum from a PSS local search  ##
c     ##                                                            ##
c     ################################################################
c
c
      subroutine climbrot (nsearch,minimum,step,grdmin)
      implicit none
      include 'sizes.i'
      include 'iounit.i'
      include 'math.i'
      include 'omega.i'
      include 'zcoord.i'
      integer maxstep
      parameter (maxstep=500)
      integer i,nsearch
      integer kstep,nstep
      real*8 minimum,grdmin
      real*8 energy
      real*8 big,small,size
      real*8 step(maxrot)
      real*8 estep(0:maxstep)
      logical done
c
c
c     set the maximum number of steps and the step size
c
      done = .false.
      big = 1.0d10
      small = -1.0d5
      minimum = big
      kstep = 0
      nstep = 65
      size = 0.1d0 * radian
      do i = 1, nomega
         step(i) = size * step(i)
      end do
c
c     scan the search direction for a minimization candidate
c
      dowhile (.not. done)
         if (kstep .ne. 0) then
            do i = 1, nomega
               ztors(zline(i)) = ztors(zline(i)) + step(i)
            end do
         end if
         call makexyz
         estep(kstep) = energy ()
         if (kstep .ge. 2) then
            if (estep(kstep) .lt. estep(kstep-2) .and.
     &          estep(kstep-1) .lt. estep(kstep-2)) then
               done = .true.
               do i = 1, nomega
                  ztors(zline(i)) = ztors(zline(i)) - step(i)
               end do
               call makexyz
               call localrot (minimum,grdmin)
               if (minimum .ge. small) then
                  write (iout,10)  nsearch,kstep-1,minimum
   10             format (4x,'Search Direction',i4,10x,'Step',
     &                       i6,10x,f12.4)
               else
                  minimum = big
                  write (iout,20)  nsearch
   20             format (4x,'Search Direction',i4,36x,'------')
               end if
            end if
         end if
         if (kstep.ge.nstep .and. .not.done) then
            done = .true.
            write (iout,30)  nsearch
   30       format (4x,'Search Direction',i4,36x,'------')
         end if
         kstep = kstep + 1
      end do
      return
      end
c
c
c     ##############################################################
c     ##                                                          ##
c     ##  subroutine localrot  --  PSS local search optimization  ##
c     ##                                                          ##
c     ##############################################################
c
c
c     "localrot" is used during the PSS local search procedure
c     to perform a torsional space energy minimization
c
c
      subroutine localrot (minimum,grdmin)
      implicit none
      include 'sizes.i'
      include 'inform.i'
      include 'minima.i'
      include 'math.i'
      include 'omega.i'
      include 'zcoord.i'
      integer i,oldprt
      real*8 minimum
      real*8 grdmin
      real*8 pssrot1
      real*8 xx(maxvar)
      logical oldverb
      external pssrot1
      external optsave
c
c
c     translate the coordinates of each atom
c
      do i = 1, nomega
         dihed(i) = ztors(zline(i)) / radian
         xx(i) = dihed(i)
      end do
c
c     make the call to the optimization routine
c
      oldverb = verbose
      oldprt = iprint
      verbose = .false.
      iprint = 0
      call ocvm (nomega,xx,minimum,grdmin,pssrot1,optsave)
      verbose = oldverb
      iprint = oldprt
c
c     untranslate the final coordinates for each atom
c
      do i = 1, nomega
         dihed(i) = xx(i)
         ztors(zline(i)) = dihed(i) * radian
      end do
      return
      end
