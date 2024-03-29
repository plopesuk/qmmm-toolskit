 
C     $Id$
c
c
c     ###################################################
c     ##  COPYRIGHT (C)  2001  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     ##############################################################
c     ##                                                          ##
c     ##  subroutine grpline  --  test atom groups for linearity  ##
c     ##                                                          ##
c     ##############################################################
c
c
c     "grpline" tests each atom group for linearity of the sites
c     contained in the group
c
c
      subroutine grpline
      implicit none
      include 'sizes.i'
      include 'atmtyp.i'
      include 'atoms.i'
      include 'group.i'
      include 'rgddyn.i'
      integer i,j,k,size
      integer start,stop
      real*8 xx,yy,zz
      real*8 x2,y2,z2
      real*8 eps,det
      real*8 weigh
      real*8 rc(3)
      real*8 inert(6)
      real*8 xm(maxatm)
      real*8 ym(maxatm)
      real*8 zm(maxatm)
c
c
c     compute the center of mass coordinates of each group
c
      do i = 1, ngrp
         start = igrp(1,i)
         stop = igrp(2,i)
         do j = 1, 3
            rc(j) = 0.0d0
         end do
         do j = start, stop
            k = kgrp(j)
            weigh = mass(k)
            rc(1) = rc(1) + x(k)*weigh
            rc(2) = rc(2) + y(k)*weigh
            rc(3) = rc(3) + z(k)*weigh
         end do
         weigh = max(1.0d0,grpmass(i))
         do j = 1, 3
            rc(j) = rc(j) / weigh
         end do
         do j = start, stop
            k = kgrp(j)
            xm(k) = x(k) - rc(1)
            ym(k) = y(k) - rc(2)
            zm(k) = z(k) - rc(3)
         end do
      end do
c
c     use the moments of inertia to check for linearity
c
      eps = 1.0d-8
      do i = 1, ngrp
         size = igrp(2,i) - igrp(1,i) + 1
         linear(i) = .false.
         if (size .eq. 2) then
            linear(i) = .true.
         else if (size .gt. 2) then
            do j = 1, 6
               inert(j) = 0.0d0
            end do
            do j = igrp(1,i), igrp(2,i)
               k = kgrp(j)
               xx = xm(k)
               yy = ym(k)
               zz = zm(k)
               x2 = xx * xx
               y2 = yy * yy
               z2 = zz * zz
               weigh = mass(k)
               inert(1) = inert(1) + weigh*(y2+z2)
               inert(2) = inert(2) - weigh*xx*yy
               inert(3) = inert(3) + weigh*(x2+z2)
               inert(4) = inert(4) - weigh*xx*zz
               inert(5) = inert(5) - weigh*yy*zz
               inert(6) = inert(6) + weigh*(x2+y2)
            end do
            det = inert(1)*inert(3)*inert(6)
     &               + 2.0d0*inert(2)*inert(5)*inert(4)
     &               - inert(3)*inert(4)*inert(4)
     &               - inert(1)*inert(5)*inert(5)
     &               - inert(2)*inert(2)*inert(6)
            if (abs(det) .lt. eps)  linear(i) = .true.
         end if
      end do
      return
      end
