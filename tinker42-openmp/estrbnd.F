 
C     $Id$
c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1993  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     ##############################################################
c     ##                                                          ##
c     ##  subroutine estrbnd  --  stretch-bend cross term energy  ##
c     ##                                                          ##
c     ##############################################################
c
c
c     "estrbnd" calculates the stretch-bend potential energy
c
c
      subroutine estrbnd
      implicit none
      include 'sizes.i'
      include 'angle.i'
      include 'angpot.i'
      include 'atoms.i'
      include 'bond.i'
      include 'bound.i'
      include 'energi.i'
      include 'group.i'
      include 'math.i'
      include 'strbnd.i'
      include 'usage.i'
      integer i,j,k,istrbnd
      integer ia,ib,ic
      real*8 e,dr,dt,fgrp
      real*8 angle,force
      real*8 dot,cosine
      real*8 xia,yia,zia
      real*8 xib,yib,zib
      real*8 xic,yic,zic
      real*8 rab,xab,yab,zab
      real*8 rcb,xcb,ycb,zcb
      logical proceed
c
c
c     zero out the stretch-bend cross term energy
c
      eba = 0.0d0
c
c     calculate the stretch-bend energy term
c
      do istrbnd = 1, nstrbnd
         i = isb(1,istrbnd)
         ia = iang(1,i)
         ib = iang(2,i)
         ic = iang(3,i)
         force = ksb(istrbnd)
c
c     decide whether to compute the current interaction
c
         proceed = .true.
         if (use_group)  call groups (proceed,fgrp,ia,ib,ic,0,0,0)
         if (proceed)  proceed = (use(ia) .or. use(ib) .or. use(ic))
c
c     get the coordinates of the atoms in the angle
c
         if (proceed) then
            xia = x(ia)
            yia = y(ia)
            zia = z(ia)
            xib = x(ib)
            yib = y(ib)
            zib = z(ib)
            xic = x(ic)
            yic = y(ic)
            zic = z(ic)
c
c     compute the value of the bond angle
c
            xab = xia - xib
            yab = yia - yib
            zab = zia - zib
            xcb = xic - xib
            ycb = yic - yib
            zcb = zic - zib
            if (use_polymer) then
               call image (xab,yab,zab,0)
               call image (xcb,ycb,zcb,0)
            end if
            rab = sqrt(xab*xab + yab*yab + zab*zab)
            rcb = sqrt(xcb*xcb + ycb*ycb + zcb*zcb)
            if (rab*rcb .ne. 0.0d0) then
               dot = xab*xcb + yab*ycb + zab*zcb
               cosine = dot / (rab*rcb)
               cosine = min(1.0d0,max(-1.0d0,cosine))
               angle = radian * acos(cosine)
               dt = angle - anat(i)
c
c     get the stretch-bend interaction energy
c
               dr = 0.0d0
               j = isb(2,istrbnd)
               k = isb(3,istrbnd)
               if (j .ne. 0)  dr = dr + rab - bl(j)
               if (k .ne. 0)  dr = dr + rcb - bl(k)
               e = stbnunit * force * dt * dr
c
c     scale the interaction based on its group membership
c
               if (use_group)  e = e * fgrp
c
c     increment the total stretch-bend energy
c
               eba = eba + e
            end if
         end if
      end do
      return
      end
