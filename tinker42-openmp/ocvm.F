 
C     $Id$
c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1990  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     ################################################################
c     ##                                                            ##
c     ##  subroutine ocvm  --  variable metric optimization method  ##
c     ##                                                            ##
c     ################################################################
c
c
c     "ocvm" is an optimally conditioned variable metric nonlinear
c     optimization routine without line searches
c
c     literature references:
c
c     W. C. Davidon, "Optimally Conditioned Optimization Algorithms
c     Without Line Searches", Mathematical Programming, 9, 1-30 (1975)
c
c     D. F. Shanno and K-H. Phua, "Matrix Conditioning and Nonlinear
c     Optimization", Mathematical Programming, 14, 149-16 (1977)
c
c     D. F. Shanno and K-H. Phua, "Numerical Comparison of Several
c     Variable-Metric Algorithms", Journal of Optimization Theory
c     and Applications, 25, 507-518 (1978)
c
c     variables and parameters:
c
c     nvar      number of parameters in the objective function
c     x0        contains starting point upon input, upon return
c                 contains the best point found
c     f0        during optimization contains best current function
c                 value; returns final best function value
c     grdmin    normal exit if rms gradient gets below this value
c     ncalls    total number of function/gradient evaluations
c
c     required external routines:
c
c     fgvalue    function to evaluate function and gradient values
c     optsave    subroutine to write out info about current status
c
c
      subroutine ocvm (nvar,x0,f0,grdmin,fgvalue,optsave)
      implicit none
      include 'sizes.i'
      include 'inform.i'
      include 'iounit.i'
      include 'keys.i'
      include 'linmin.i'
      include 'math.i'
      include 'minima.i'
      include 'output.i'
      include 'potent.i'
      include 'scales.i'
      integer i,j,nvar
      integer mvar,next
      integer niter,ncalls
      integer nbig,nstep
      integer maxbig,maxstep
      real*8 fgvalue,eps
      real*8 grdmin,precise
      real*8 f,f0,f0old
      real*8 fprime,f0prime
      real*8 srchnorm
      real*8 sgangle,sg,snorm
      real*8 zeta,cosang
      real*8 fmove,xmove
      real*8 gnorm,grms,rms
      real*8 m2,n2,u2,v
      real*8 micron,mw,us,qk0
      real*8 a,b,b0,c
      real*8 alpha,gamma,delta
      real*8 x(maxopt),g(maxopt)
      real*8 x0(maxopt)
      real*8 x0old(maxopt)
      real*8 search(maxopt)
      real*8 s(maxopt),w(maxopt)
      real*8 k(maxopt),k0(maxopt)
      real*8 m(maxopt),n(maxopt)
      real*8 p(maxopt),q(maxopt)
      real*8 u(maxopt),hq(maxopt)
      real*8 h(maxopt,maxopt)
      logical restart,done
      character*9 status
      character*20 keyword
      character*120 record
      character*120 string
      external fgvalue,optsave
c
c
c     initialization and set-up for the optimization
c
      if (nvar .gt. maxopt) then
         write (iout,10)
   10    format (/,' OCVM  --  Too many Parameters,',
     &              ' Increase the Value of MAXOPT')
         return
      end if
      mvar = nvar
      rms = sqrt(dble(nvar))
      if (coordtype .eq. 'CARTESIAN') then
         rms = rms / sqrt(3.0d0)
      else if (coordtype .eq. 'RIGIDBODY') then
         rms = rms / sqrt(6.0d0)
      end if
      maxbig = 2
      maxstep = 10
      eps = precise (2)
      restart = .true.
      done = .false.
c
c     set default values for variable scale factors
c
      if (.not. set_scale) then
         do i = 1, nvar
            if (scale(i) .eq. 0.0d0)  scale(i) = 1.0d0
         end do
      end if
c
c     set default parameters for the optimization
c
      if (fctmin .eq. 0.0d0)  fctmin = -1000000.0d0
      if (maxiter .eq. 0)  maxiter = 1000000
      if (nextiter .eq. 0)  nextiter = 1
      if (iprint .lt. 0)  iprint = 1
      if (iwrite .lt. 0)  iwrite = 1
      if (stpmax .eq. 0.0d0)  stpmax = 5.0d0
      if (hguess .eq. 0.0d0)  hguess = 0.4d0
      angmax = 180.0d0
c
c     search the keywords for optimization parameters
c
      do i = 1, nkey
         next = 1
         record = keyline(i)
         call gettext (record,keyword,next)
         call upcase (keyword)
         string = record(next:120)
         if (keyword(1:7) .eq. 'FCTMIN ') then
            read (string,*,err=20,end=20)  fctmin
         else if (keyword(1:8) .eq. 'MAXITER ') then
            read (string,*,err=20,end=20)  maxiter
         else if (keyword(1:9) .eq. 'NEXTITER ') then
            read (string,*,err=20,end=20)  nextiter
         else if (keyword(1:7) .eq. 'HGUESS ') then
            read (string,*,err=20,end=20)  hguess
         else if (keyword(1:8) .eq. 'STEPMAX ') then
            read (string,*,err=20,end=20)  stpmax
         else if (keyword(1:7) .eq. 'ANGMAX ') then
            read (string,*,err=20,end=20)  angmax
         end if
   20    continue
      end do
c
c     evaluate the function and get the initial gradient
c
      niter = nextiter - 1
      maxiter = niter + maxiter
      do i = 1, nvar
         x0old(i) = x0(i)
      end do
      ncalls = 1
      f0 = fgvalue (x0,g)
      f0old = f0
c
c     print initial information prior to first iteration
c
      if (iprint .gt. 0) then
         write (iout,30)
   30    format (/,' Optimally Conditioned Variable Metric',
     &             ' Optimization :')
         write (iout,40)
   40    format (/,' VM Iter    F Value       G RMS     F Move',
     &              '    X Move      Angle   FG Call',/)
      end if
c
c     set the "h" matrix to a diagonal upon restarting
c
      dowhile (.not. done)
         if (restart) then
            do j = 1, mvar
               do i = 1, nvar
                  h(i,j) = 0.0d0
               end do
            end do
            do j = 1, mvar
               h(j,j) = hguess
            end do
            do j = 1, mvar
               k0(j) = 0.0d0
               do i = 1, nvar
                  k0(j) = k0(j) + h(i,j)*g(i)
               end do
               w(j) = k0(j)
            end do
            restart = .false.
         end if
c
c     start the next iteration using either an updated "h"
c     matrix or the "h" matrix from the previous iteration
c
         gnorm = 0.0d0
         grms = 0.0d0
         do i = 1, nvar
            gnorm = gnorm + g(i)**2
            grms = grms + (g(i)*scale(i))**2
         end do
         gnorm = sqrt(gnorm)
         grms = sqrt(grms) / rms
         xmove = 0.0d0
         if (niter .ne. 0) then
            do i = 1, nvar
               xmove = xmove + ((x0(i)-x0old(i))/scale(i))**2
               x0old(i) = x0(i)
            end do
            xmove = sqrt(xmove) / rms
            if (coordtype .eq. 'INTERNAL') then
               xmove = radian * xmove
            end if
            fmove = f0old - f0
            f0old = f0
         end if
c
c     print intermediate results for the current iteration
c
         if (iprint .gt. 0) then
            if (niter .eq. 0) then
               if (f0.lt.1.0d7 .and. f0.gt.-1.0d6 .and.
     &                    grms.lt.1.0d6) then
                  write (iout,50)  niter,f0,grms,ncalls
   50             format (i6,f13.4,f12.4,32x,i9)
               else
                  write (iout,60)  niter,f0,grms,ncalls
   60             format (i6,d13.4,d12.4,32x,i9)
               end if
            else if (mod(niter,iprint) .eq. 0) then
               if (f0.lt.1.0d7 .and. f0.gt.-1.0d6 .and.
     &             grms.lt.1.0d6 .and. fmove.lt.1.0d5) then
                  write (iout,70)  niter,f0,grms,fmove,
     &                             xmove,sgangle,ncalls
   70             format (i6,f13.4,f12.4,f11.4,f10.4,f11.4,i9)
               else
                  write (iout,80)  niter,f0,grms,fmove,
     &                             xmove,sgangle,ncalls
   80             format (i6,d13.4,d12.4,d11.4,f10.4,f11.4,i9)
               end if
            end if
         end if
c
c     write intermediate results for the current iteration
c
         if (iwrite .gt. 0) then
            if (mod(niter,iwrite) .eq. 0) then
               call optsave (niter,f0,x)
            end if
         end if
c
c     before starting the next iteration, check to see whether
c     the gradient norm, function decrease or iteration limit
c     termination criteria have been satisfied
c
         if (grms.lt.grdmin .or. f0.lt.fctmin
     &          .or. niter.ge.maxiter) then
            if (iprint .gt. 0) then
               if (niter.ne.0 .and. mod(niter,iprint).ne.0) then
                  if (f0.lt.1.0d7 .and. f0.gt.-1.0d6 .and.
     &                grms.lt.1.0d6 .and. fmove.lt.1.0d5) then
                     write (iout,90)  niter,f0,grms,fmove,
     &                                xmove,sgangle,ncalls
   90                format (i6,f13.4,f12.4,f11.4,f10.4,f11.4,i9)
                  else
                     write (iout,100)  niter,f0,grms,fmove,
     &                                 xmove,sgangle,ncalls
  100                format (i6,d13.4,d12.4,d11.4,f10.4,f11.4,i9)
                  end if
               end if
               if (niter .ge. maxiter)  status = 'IterLimit'
               if (f0 .lt. fctmin)  status = 'SmallFct '
               if (grms .lt. grdmin)  status = 'SmallGrad'
               if (status .eq. 'IterLimit') then
                  write (iout,110)  status
  110             format (/,' OCVM  --  Incomplete Convergence',
     &                       ' due to ',a9)
               else
                  write (iout,120)  status
  120             format (/,' OCVM  --  Normal Termination',
     &                       ' due to ',a9)
               end if
            end if
            if (iwrite .gt. 0) then
               if (mod(niter,iwrite) .ne. 0) then
                  call optsave (niter,f0,x)
               end if
            end if
            done = .true.
            goto 170
         end if
c
c     start of the next iteration
c
         niter = niter + 1
         sg = 0.0d0
         snorm = 0.0d0
         do j = 1, mvar
            s(j) = -k0(j)
            snorm = snorm + s(j)**2
            sg = sg - s(j)*g(j)
         end do
         f0prime = -snorm
         snorm = sqrt(snorm)
         cosang = sg / (snorm*gnorm)
         cosang = min(1.0d0,max(-1.0d0,cosang))
         sgangle = radian * acos(cosang)
         if (sgangle .gt. angmax) then
            nbig = nbig + 1
         else
            nbig = 0
         end if
         zeta = 2.0d0
         if (4.0d0*(f0-fctmin) .lt. -f0prime) then
            do j = 1, mvar
               s(j) = -s(j) * (4.0d0*(f0-fctmin)/f0prime)
            end do
            f0prime = -4.0d0 * (f0-fctmin)
         end if
c
c     location of the next starting point
c
         nstep = 0
  130    continue
         do i = 1, nvar
            search(i) = 0.0d0
         end do
         do j = 1, mvar
            do i = 1, nvar
               search(i) = search(i) + h(i,j)*s(j)
            end do
         end do
         srchnorm = 0.0d0
         do i = 1, nvar
            srchnorm = srchnorm + search(i)**2
         end do
         srchnorm = sqrt(srchnorm)
         if (srchnorm .gt. stpmax) then
            do j = 1, mvar
               s(j) = (stpmax/srchnorm) * s(j)
            end do
            do i = 1, nvar
               search(i) = (stpmax/srchnorm) * search(i)
            end do
            f0prime = (stpmax/srchnorm) * f0prime
            zeta = 0.5d0
         end if
c
c     invoke abnormal termination if -f0prime is too small
c
         if (-f0prime .lt. eps) then
            if (iprint .gt. 0) then
               if (niter.ne.0 .and. mod(niter,iprint).ne.0) then
                  if (f0.lt.1.0d7 .and. f0.gt.-1.0d6 .and.
     &                       grms.lt.1.0d6) then
                     write (iout,140)  niter,f0,grms,0.0,0.0,
     &                                 sgangle,ncalls
  140                format (i6,f13.4,f12.4,f11.4,f10.4,f11.4,i9)
                  else
                     write (iout,150)  niter,f0,grms,0.0,0.0,
     &                                 sgangle,ncalls
  150                format (i6,d13.4,d12.4,f11.4,f10.4,f11.4,i9)
                  end if
               end if
               status = 'SmallMove'
               write (iout,160)  status
  160          format (/,' OCVM  --  Incomplete Convergence',
     &                    ' due to ',a9)
            end if
            if (iwrite .gt. 0) then
               if (mod(niter,iwrite) .ne. 0) then
                  call optsave (niter,f0,x)
               end if
            end if
            done = .true.
            goto 170
         end if
         do i = 1, nvar
            x(i) = x0(i) + search(i)
         end do
         ncalls = ncalls + 1
         f = fgvalue (x,g)
         if (f .ge. f0) then
            do j = 1, mvar
               s(j) = 0.5d0 * s(j)
            end do
            f0prime = 0.5d0 * f0prime
            zeta = 0.5d0
            goto 130
         end if
c
c     decide whether to update or take another step
c
         do j = 1, mvar
            k(j) = 0.0d0
            do i = 1, nvar
               k(j) = k(j) + h(i,j)*g(i)
            end do
         end do
         fprime = 0.0d0
         do j = 1, mvar
            fprime = fprime + k(j)*s(j)
         end do
         b0 = fprime - f0prime
         do j = 1, mvar
            m(j) = s(j) + k0(j) - k(j)
            k0(j) = k(j)
         end do
         do i = 1, nvar
            x0(i) = x(i)
         end do
         f0 = f
         f0prime = fprime
         if (b0 .lt. eps) then
            nstep = nstep + 1
            if (nstep .ge. maxstep) then
               restart = .true.
               goto 170
            end if
            do j = 1, mvar
               s(j) = s(j) * zeta
            end do
            f0prime = f0prime * zeta
            goto 130
         end if
c
c     check to see if we need to update
c
         if (nbig .ge. maxbig) then
            restart = .true.
            goto 170
         end if
         m2 = 0.0d0
         do j = 1, mvar
            m2 = m2 + m(j)**2
         end do
         if (m2 .lt. eps) then
            goto 170
         end if
         v = 0.0d0
         do j = 1, mvar
            v = v + m(j)*s(j)
         end do
         micron = v - m2
         mw = 0.0d0
         do j = 1, mvar
            mw = mw + m(j)*w(j)
         end do
         do j = 1, mvar
            u(j) = w(j) - m(j)*(mw/m2)
         end do
         u2 = 0.0d0
         do j = 1, mvar
            u2 = u2 + u(j)**2
         end do
         if (m2*u2 .ge. eps) then
            us = 0.0d0
            do j = 1, mvar
               us = us + u(j)*s(j)
            end do
            do j = 1, mvar
               n(j) = u(j)*(us/u2)
            end do
            n2 = us * us/u2
         else
            do j = 1, mvar
               n(j) = 0.0d0
            end do
            n2 = 0.0d0
         end if
c
c     test inner product of projected s and del-g
c
         b = n2 + micron * v/m2
         if (b .lt. eps) then
            do j = 1, mvar
               n(j) = s(j) - m(j)*(v/m2)
            end do
            n2 = b0 - micron * v/m2
            b = b0
         end if
c
c     set "gamma" and "delta" for the update
c
         if (micron*v .ge. m2*n2) then
            gamma = 0.0d0
            delta = sqrt(v/micron)
         else
            a = b - micron
            c = b + v
            gamma = sqrt((1.0d0-micron*v/(m2*n2))/(a*b))
            delta = sqrt(c/a)
            if (c .lt. a) then
               gamma = -gamma
            end if
         end if
c
c     perform the update of the "h" matrix
c
         alpha = v + micron*delta + m2*n2*gamma
         do j = 1, mvar
            p(j) = m(j)*(delta-n2*gamma) + n(j)*(gamma*v)
            q(j) = m(j)*((1.0d0+n2*gamma)/alpha)
     &             - n(j)*(gamma * micron/alpha)
            w(j) = m(j)*(n2*(1.0d0+gamma*micron*v)/alpha)
     &             - n(j)*((1.0d0+delta)*micron*v/alpha)
         end do
         qk0 = 0.0d0
         do j = 1, mvar
            qk0 = qk0 + q(j)*k0(j)
         end do
         do j = 1, mvar
            k0(j) = k0(j) + p(j)*qk0
         end do
         do i = 1, nvar
            hq(i) = 0.0d0
         end do
         do j = 1, mvar
            do i = 1, nvar
               hq(i) = hq(i) + h(i,j)*q(j)
            end do
         end do
         do j = 1, mvar
            do i = 1, nvar
               h(i,j) = h(i,j) + hq(i)*p(j)
            end do
         end do
         if (n2 .le. 0.0d0) then
            do j = 1, mvar
               w(j) = k0(j)
            end do
         end if
  170    continue
      end do
      return
      end
