 
C     $Id$
c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1995  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     ###############################################################
c     ##                                                           ##
c     ##  subroutine eopbend1  --  out-of-plane energy and derivs  ##
c     ##                                                           ##
c     ###############################################################
c
c
c     "eopbend1" computes the out-of-plane bend potential
c     energy and first derivatives at trigonal centers via
c     a Wilson-Decius-Cross angle bend
c
c
      subroutine eopbend1
      implicit none
      include 'sizes.i'
      include 'angle.i'
      include 'angpot.i'
      include 'atoms.i'
      include 'bound.i'
      include 'deriv.i'
      include 'energi.i'
      include 'group.i'
      include 'math.i'
      include 'opbend.i'
      include 'usage.i'
      include 'virial.i'
      integer i,iopbend
      integer ia,ib,ic,id
      real*8 e,angle,force
      real*8 dot,cosine,fgrp
      real*8 cc,ee,bkk2,term
      real*8 deddt,dedcos
      real*8 dt,dt2,dt3,dt4
      real*8 xia,yia,zia
      real*8 xib,yib,zib
      real*8 xic,yic,zic
      real*8 xid,yid,zid
      real*8 xab,yab,zab
      real*8 xcb,ycb,zcb
      real*8 xdb,ydb,zdb
      real*8 xad,yad,zad
      real*8 xcd,ycd,zcd
      real*8 rdb2,rad2,rcd2
      real*8 dccdxia,dccdyia,dccdzia
      real*8 dccdxic,dccdyic,dccdzic
      real*8 dccdxid,dccdyid,dccdzid
      real*8 deedxia,deedyia,deedzia
      real*8 deedxic,deedyic,deedzic
      real*8 deedxid,deedyid,deedzid
      real*8 dedxia,dedyia,dedzia
      real*8 dedxib,dedyib,dedzib
      real*8 dedxic,dedyic,dedzic
      real*8 dedxid,dedyid,dedzid
      real*8 vxx,vyy,vzz
      real*8 vyx,vzx,vzy
      logical proceed
c
c
c     zero out out-of-plane energy and first derivatives
c
      eopb = 0.0d0
      do i = 1, n
         deopb(1,i) = 0.0d0
         deopb(2,i) = 0.0d0
         deopb(3,i) = 0.0d0
      end do
c
c     calculate the out-of-plane bending energy and derivatives
c
      do iopbend = 1, nopbend
         i = iopb(iopbend)
         ia = iang(1,i)
         ib = iang(2,i)
         ic = iang(3,i)
         id = iang(4,i)
         force = kopb(iopbend)
c
c     decide whether to compute the current interaction
c
         proceed = .true.
         if (use_group)  call groups (proceed,fgrp,ia,ib,ic,id,0,0)
         if (proceed)  proceed = (use(ia) .or. use(ib) .or.
     &                              use(ic) .or. use(id))
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
            xid = x(id)
            yid = y(id)
            zid = z(id)
c
c     compute the out-of-plane bending angle
c
            xab = xia - xib
            yab = yia - yib
            zab = zia - zib
            xcb = xic - xib
            ycb = yic - yib
            zcb = zic - zib
            xdb = xid - xib
            ydb = yid - yib
            zdb = zid - zib
            xad = xia - xid
            yad = yia - yid
            zad = zia - zid
            xcd = xic - xid
            ycd = yic - yid
            zcd = zic - zid
            if (use_polymer) then
               call image (xab,yab,zab,0)
               call image (xcb,ycb,zcb,0)
               call image (xdb,ydb,zdb,0)
               call image (xad,yad,zad,0)
               call image (xcd,ycd,zcd,0)
            end if
            rdb2 = xdb*xdb + ydb*ydb + zdb*zdb
            rad2 = xad*xad + yad*yad + zad*zad
            rcd2 = xcd*xcd + ycd*ycd + zcd*zcd
            ee = xab*(ycb*zdb-zcb*ydb) +  yab*(zcb*xdb-xcb*zdb)
     &                      + zab*(xcb*ydb-ycb*xdb)
            dot = xad*xcd + yad*ycd + zad*zcd
            cc = rad2*rcd2 - dot*dot
            if (rdb2.ne.0.0d0 .and. cc.ne.0.0d0) then
               bkk2 = rdb2 - ee*ee/cc
               cosine = sqrt(bkk2/rdb2)
               cosine = min(1.0d0,max(-1.0d0,cosine))
               angle = radian * acos(cosine)
c
c     find the out-of-plane energy and master chain rule terms
c
               dt = angle
               dt2 = dt * dt
               dt3 = dt2 * dt
               dt4 = dt2 * dt2
               e = opbunit * force * dt2
     &                * (1.0d0+cang*dt+qang*dt2+pang*dt3+sang*dt4)
               deddt = opbunit * force * dt * radian
     &                    * (2.0d0 + 3.0d0*cang*dt + 4.0d0*qang*dt2
     &                        + 5.0d0*pang*dt3 + 6.0d0*sang*dt4)
               dedcos = -deddt * sign(1.0d0,ee) / sqrt(cc*bkk2)
c
c     scale the interaction based on its group membership
c
               if (use_group) then
                  e = e * fgrp
                  dedcos = dedcos * fgrp
               end if
c
c     chain rule terms for first derivative components
c
               term = ee / cc
               dccdxia = (xad*rcd2-xcd*dot) * term
               dccdyia = (yad*rcd2-ycd*dot) * term
               dccdzia = (zad*rcd2-zcd*dot) * term
               dccdxic = (xcd*rad2-xad*dot) * term
               dccdyic = (ycd*rad2-yad*dot) * term
               dccdzic = (zcd*rad2-zad*dot) * term
               dccdxid = -dccdxia - dccdxic
               dccdyid = -dccdyia - dccdyic
               dccdzid = -dccdzia - dccdzic
               term = ee / rdb2
               deedxia = ydb*zcb - zdb*ycb
               deedyia = zdb*xcb - xdb*zcb
               deedzia = xdb*ycb - ydb*xcb
               deedxic = yab*zdb - zab*ydb
               deedyic = zab*xdb - xab*zdb
               deedzic = xab*ydb - yab*xdb
               deedxid = ycb*zab - zcb*yab + xdb*term
               deedyid = zcb*xab - xcb*zab + ydb*term
               deedzid = xcb*yab - ycb*xab + zdb*term
c
c     compute first derivative components for this angle
c
               dedxia = dedcos * (dccdxia+deedxia)
               dedyia = dedcos * (dccdyia+deedyia)
               dedzia = dedcos * (dccdzia+deedzia)
               dedxic = dedcos * (dccdxic+deedxic)
               dedyic = dedcos * (dccdyic+deedyic)
               dedzic = dedcos * (dccdzic+deedzic)
               dedxid = dedcos * (dccdxid+deedxid)
               dedyid = dedcos * (dccdyid+deedyid)
               dedzid = dedcos * (dccdzid+deedzid)
               dedxib = -dedxia - dedxic - dedxid
               dedyib = -dedyia - dedyic - dedyid
               dedzib = -dedzia - dedzic - dedzid
c
c     increment the out-of-plane bending energy and gradient
c
               eopb = eopb + e
               deopb(1,ia) = deopb(1,ia) + dedxia
               deopb(2,ia) = deopb(2,ia) + dedyia
               deopb(3,ia) = deopb(3,ia) + dedzia
               deopb(1,ib) = deopb(1,ib) + dedxib
               deopb(2,ib) = deopb(2,ib) + dedyib
               deopb(3,ib) = deopb(3,ib) + dedzib
               deopb(1,ic) = deopb(1,ic) + dedxic
               deopb(2,ic) = deopb(2,ic) + dedyic
               deopb(3,ic) = deopb(3,ic) + dedzic
               deopb(1,id) = deopb(1,id) + dedxid
               deopb(2,id) = deopb(2,id) + dedyid
               deopb(3,id) = deopb(3,id) + dedzid
c
c     increment the internal virial tensor components
c
               vxx = xab*dedxia + xcb*dedxic + xdb*dedxid
               vyx = yab*dedxia + ycb*dedxic + ydb*dedxid
               vzx = zab*dedxia + zcb*dedxic + zdb*dedxid
               vyy = yab*dedyia + ycb*dedyic + ydb*dedyid
               vzy = zab*dedyia + zcb*dedyic + zdb*dedyid
               vzz = zab*dedzia + zcb*dedzic + zdb*dedzid
               vir(1,1) = vir(1,1) + vxx
               vir(2,1) = vir(2,1) + vyx
               vir(3,1) = vir(3,1) + vzx
               vir(1,2) = vir(1,2) + vyx
               vir(2,2) = vir(2,2) + vyy
               vir(3,2) = vir(3,2) + vzy
               vir(1,3) = vir(1,3) + vzx
               vir(2,3) = vir(2,3) + vzy
               vir(3,3) = vir(3,3) + vzz
            end if
         end if
      end do
      return
      end
