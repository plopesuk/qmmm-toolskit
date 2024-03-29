 
C     $Id$
c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1999  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     #################################################################
c     ##                                                             ##
c     ##  subroutine eopdist3  --  out-of-plane distance & analysis  ##
c     ##                                                             ##
c     #################################################################
c
c
c     "eopdist3" computes the out-of-plane distance potential energy
c     at trigonal centers via the central atom height; also partitions
c     the energy among the atoms
c
c
      subroutine eopdist3
      implicit none
      include 'sizes.i'
      include 'action.i'
      include 'analyz.i'
      include 'angpot.i'
      include 'atmtyp.i'
      include 'atoms.i'
      include 'bound.i'
      include 'energi.i'
      include 'group.i'
      include 'inform.i'
      include 'iounit.i'
      include 'opdist.i'
      include 'usage.i'
      integer i,ia,ib,ic,id
      real*8 e,force,fgrp
      real*8 dt2,rt2
      real*8 xia,yia,zia
      real*8 xib,yib,zib
      real*8 xic,yic,zic
      real*8 xid,yid,zid
      real*8 xad,yad,zad
      real*8 xbd,ybd,zbd
      real*8 xcd,ycd,zcd
      real*8 xt,yt,zt
      logical proceed
      logical header,huge
c
c
c     zero out the out-of-plane distance energy and partitioning
c
      neopd = 0
      eopd = 0.0d0
      do i = 1, n
         aeopd(i) = 0.0d0
      end do
      header = .true.
c
c     calculate the out-of-plane distance energy term
c
      do i = 1, nopdist
         ia = iopd(1,i)
         ib = iopd(2,i)
         ic = iopd(3,i)
         id = iopd(4,i)
         force = kopd(i)
c
c     decide whether to compute the current interaction
c
         proceed = .true.
         if (use_group)  call groups (proceed,fgrp,ia,ib,ic,id,0,0)
         if (proceed)  proceed = (use(ia) .or. use(ib) .or.
     &                              use(ic) .or. use(id))
c
c     get the coordinates of the central and peripheral atoms
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
            xid = x(id)
            yid = y(id)
            zid = z(id)
c
c     compute the out-of-plane distance for central atom
c
            xad = xia - xid
            yad = yia - yid
            zad = zia - zid
            xbd = xib - xid
            ybd = yib - yid
            zbd = zib - zid
            xcd = xic - xid
            ycd = yic - yid
            zcd = zic - zid
            if (use_polymer) then
               call image (xad,yad,zad,0)
               call image (xbd,ybd,zbd,0)
               call image (xcd,ycd,zcd,0)
            end if
            xt = ybd*zcd - zbd*ycd
            yt = zbd*xcd - xbd*zcd
            zt = xbd*ycd - ybd*xcd
            rt2 = xt*xt + yt*yt + zt*zt
            dt2 = (xt*xad + yt*yad + zt*zad)**2 / rt2
c
c     find the out-of-plane distance energy
c
            e = opdunit * force * dt2
c
c     scale the interaction based on its group membership
c
            if (use_group)  e = e * fgrp
c
c     increment the total out-of-plane distance energy
c
            neopd = neopd + 1
            eopd = eopd + e
            aeopd(ia) = aeopd(ia) + e
c
c     print a message if the energy of this interaction is large
c
            huge = (e .gt. 2.0d0)
            if (debug .or. (verbose.and.huge)) then
               if (header) then
                  header = .false.
                  write (iout,10)
   10             format (/,' Individual Out-of-Plane Distance',
     &                       ' Interactions :',
     &                    //,' Type',23x,'Atom Names',17x,'Distance',
     &                       6x,'Energy',/)
               end if
               write (iout,20)  ia,name(ia),ib,name(ib),ic,
     &                          name(ic),id,name(id),sqrt(dt2),e
   20          format (' O-P-Dist',3x,i5,'-',a3,3(1x,i5,'-',a3),
     &                    2x,f10.4,f12.4)
            end if
         end if
      end do
      return
      end
