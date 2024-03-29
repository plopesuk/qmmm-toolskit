 
C     $Id$
c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1998  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     #################################################################
c     ##                                                             ##
c     ##  subroutine emm3hb3  --  MM3 vdw & hbond energy & analysis  ##
c     ##                                                             ##
c     #################################################################
c
c
c     "emm3hb3" calculates the MM3 exp-6 van der Waals and directional
c     charge transfer hydrogen bonding energy, and partitions the energy
c     among the atoms
c
c     literature reference:
c
c     J.-H. Lii and N. L. Allinger, "Directional Hydrogen Bonding in
c     the MM3 Force Field. I", Journal of Physical Organic Chemistry,
c     7, 591-609 (1994)
c
c
      subroutine emm3hb3
      implicit none
      include 'cutoff.i'
c
c
c     choose pairwise double loop or method of lights version
c
      if (use_lights) then
         call emm3hb3b
      else
         call emm3hb3a
      end if
      return
      end
c
c
c     ################################################################
c     ##                                                            ##
c     ##  subroutine emm3hb3a  --  double loop MM3 vdw-hb analysis  ##
c     ##                                                            ##
c     ################################################################
c
c
c     "emm3hb3" calculates the MM3 exp-6 van der Waals and
c     directional charge transfer hydrogen bonding energy, and
c     partitions the energy among the atoms
c
c
      subroutine emm3hb3a
      implicit none
      include 'sizes.i'
      include 'action.i'
      include 'analyz.i'
      include 'atmlst.i'
      include 'atmtyp.i'
      include 'atoms.i'
      include 'bond.i'
      include 'bound.i'
      include 'cell.i'
      include 'chgpot.i'
      include 'couple.i'
      include 'energi.i'
      include 'group.i'
      include 'inform.i'
      include 'inter.i'
      include 'iounit.i'
      include 'molcul.i'
      include 'shunt.i'
      include 'usage.i'
      include 'vdw.i'
      include 'vdwpot.i'
      integer i,j,k,ii,kk
      integer ia,ib,ic
      integer iv,kv,it,kt
      integer iv14(maxatm)
      real*8 e,rv,eps
      real*8 rdn,fgrp
      real*8 p,p2,p6,p12
      real*8 xi,yi,zi
      real*8 xr,yr,zr
      real*8 rik,rik2,rik3
      real*8 rik4,rik5,taper
      real*8 expcut,expcut2
      real*8 expterm,expmin2
      real*8 expmerge
      real*8 dot,cosine
      real*8 fterm,ideal
      real*8 xia,yia,zia
      real*8 xib,yib,zib
      real*8 xic,yic,zic
      real*8 xab,yab,zab
      real*8 xcb,ycb,zcb
      real*8 rab2,rab,rcb2
      real*8 xp,yp,zp,rp
      real*8 xred(maxatm)
      real*8 yred(maxatm)
      real*8 zred(maxatm)
      real*8 vscale(maxatm)
      logical proceed,iuse
      logical header,huge
c
c
c     zero out the van der Waals energy and partitioning terms
c
      nev = 0
      ev = 0.0d0
      do i = 1, n
         aev(i) = 0.0d0
      end do
      header = .true.
c
c     zero out the array marking 1-4 vdw interactions
c
      do i = 1, n
         iv14(i) = 0
      end do
c
c     set the coefficients for the switching function
c
      call switch ('VDW')
c
c     special cutoffs for very short and very long range terms
c
      expmin2 = 0.01d0
      expcut = 2.0d0
      expcut2 = expcut * expcut
      expmerge = (abuck*exp(-bbuck/expcut) - cbuck*(expcut**6))
     &                               / (expcut**12)
c
c     apply any reduction factor to the atomic coordinates
c
      do k = 1, nvdw
         i = ivdw(k)
         iv = ired(i)
         rdn = kred(i)
         xred(i) = rdn*(x(i)-x(iv)) + x(iv)
         yred(i) = rdn*(y(i)-y(iv)) + y(iv)
         zred(i) = rdn*(z(i)-z(iv)) + z(iv)
      end do
c
c     find the van der Waals energy via double loop search
c
      do ii = 1, nvdw-1
         i = ivdw(ii)
         iv = ired(i)
         it = class(i)
         xi = xred(i)
         yi = yred(i)
         zi = zred(i)
         iuse = (use(i) .or. use(iv))
         do j = ii+1, nvdw
            vscale(ivdw(j)) = 1.0d0
         end do
         do j = 1, n12(i)
            vscale(i12(j,i)) = v2scale
         end do
         do j = 1, n13(i)
            vscale(i13(j,i)) = v3scale
         end do
         do j = 1, n14(i)
            vscale(i14(j,i)) = v4scale
            iv14(i14(j,i)) = i
         end do
         do j = 1, n15(i)
            vscale(i15(j,i)) = v5scale
         end do
c
c     decide whether to compute the current interaction
c
         do kk = ii+1, nvdw
            k = ivdw(kk)
            kv = ired(k)
            proceed = .true.
            if (use_group)  call groups (proceed,fgrp,i,k,0,0,0,0)
            if (proceed)  proceed = (iuse .or. use(k) .or. use(kv))
            if (proceed)  proceed = (vscale(k) .ne. 0.0d0)
c
c     compute the energy contribution for this interaction
c
            if (proceed) then
               kt = class(k)
               xr = xi - xred(k)
               yr = yi - yred(k)
               zr = zi - zred(k)
               if (use_image)  call image (xr,yr,zr,0)
               rik2 = xr*xr + yr*yr + zr*zr
c
c     check for an interaction distance less than the cutoff
c
               if (rik2 .le. off2) then
                  fterm = 1.0d0
                  rv = radmin(kt,it)
                  eps = epsilon(kt,it)
                  if (iv14(k) .eq. i) then
                     rv = radmin4(kt,it)
                     eps = epsilon4(kt,it)
                  else if (radhbnd(kt,it) .ne. 0.0d0) then
                     rv = radhbnd(kt,it)
                     eps = epshbnd(kt,it) / dielec
                     if (atomic(i) .eq. 1) then
                        ia = i
                        ib = i12(1,i)
                        ic = k
                     else
                        ia = k
                        ib = i12(1,k)
                        ic = i
                     end if
                     xia = x(ia)
                     yia = y(ia)
                     zia = z(ia)
                     xib = x(ib)
                     yib = y(ib)
                     zib = z(ib)
                     xic = x(ic)
                     yic = y(ic)
                     zic = z(ic)
                     xab = xia - xib
                     yab = yia - yib
                     zab = zia - zib
                     rab2 = xab*xab + yab*yab + zab*zab
                     rab = sqrt(rab2)
                     xcb = xic - xib
                     ycb = yic - yib
                     zcb = zic - zib
                     if (use_image)  call image (xcb,ycb,zcb,0)
                     rcb2 = xcb*xcb + ycb*ycb + zcb*zcb
                     rcb2 = max(0.01d0,rcb2)
                     xp = ycb*zab - zcb*yab
                     yp = zcb*xab - xcb*zab
                     zp = xcb*yab - ycb*xab
                     rp = sqrt(xp*xp + yp*yp + zp*zp)
                     dot = xab*xcb + yab*ycb + zab*zcb
                     cosine = dot / sqrt(rab2*rcb2)
                     ideal = bl(bndlist(1,ia))
                     fterm = cosine * (rab/ideal)
                  end if
                  eps = eps * vscale(k)
                  p2 = (rv*rv) / rik2
                  p6 = p2 * p2 * p2
                  if (p2 .le. expmin2) then
                     e = 0.0d0
                  else if (p2 .le. expcut2) then
                     p = sqrt(p2)
                     expterm = abuck * exp(-bbuck/p)
                     e = eps * (expterm - fterm*cbuck*p6)
                  else
                     p12 = p6 * p6
                     e = expmerge * eps * p12
                  end if
c
c     use energy switching if near the cutoff distance
c
                  if (rik2 .gt. cut2) then
                     rik = sqrt(rik2)
                     rik3 = rik2 * rik
                     rik4 = rik2 * rik2
                     rik5 = rik2 * rik3
                     taper = c5*rik5 + c4*rik4 + c3*rik3
     &                          + c2*rik2 + c1*rik + c0
                     e = e * taper
                  end if
c
c     scale the interaction based on its group membership
c
                  if (use_group)  e = e * fgrp
c
c     increment the overall van der Waals energy components
c
                  nev = nev + 1
                  ev = ev + e
                  aev(i) = aev(i) + 0.5d0*e
                  aev(k) = aev(k) + 0.5d0*e
c
c     increment the total intermolecular energy
c
                  if (molcule(i) .ne. molcule(k)) then
                     einter = einter + e
                  end if
c
c     print a message if the energy of this interaction is large
c
                  huge = (e .gt. 10.0d0)
                  if (debug .or. (verbose.and.huge)) then
                     if (header) then
                        header = .false.
                        write (iout,10)
   10                   format (/,' Individual van der Waals',
     &                             ' Interactions :',
     &                          //,' Type',13x,'Atom Names',
     &                             18x,'Minimum',4x,'Actual',
     &                             6x,'Energy',/)
                     end if
                     write (iout,20)  i,name(i),k,name(k),
     &                                rv,sqrt(rik2),e
   20                format (' VDW-MM3',4x,i5,'-',a3,1x,i5,
     &                          '-',a3,12x,2f10.4,f12.4)
                  end if
               end if
            end if
         end do
      end do
c
c     for periodic boundary conditions with large cutoffs
c     neighbors must be found by the replicates method
c
      if (.not. use_replica)  return
c
c     calculate interaction energy with other unit cells
c
      do ii = 1, nvdw
         i = ivdw(ii)
         iv = ired(i)
         it = class(i)
         xi = xred(i)
         yi = yred(i)
         zi = zred(i)
         iuse = (use(i) .or. use(iv))
         do j = ii, nvdw
            vscale(ivdw(j)) = 1.0d0
         end do
         do j = 1, n12(i)
            vscale(i12(j,i)) = v2scale
         end do
         do j = 1, n13(i)
            vscale(i13(j,i)) = v3scale
         end do
         do j = 1, n14(i)
            vscale(i14(j,i)) = v4scale
            iv14(i14(j,i)) = i
         end do
         do j = 1, n15(i)
            vscale(i15(j,i)) = v5scale
         end do
c
c     decide whether to compute the current interaction
c
         do kk = ii, nvdw
            k = ivdw(kk)
            kv = ired(k)
            proceed = .true.
            if (use_group)  call groups (proceed,fgrp,i,k,0,0,0,0)
            if (proceed)  proceed = (iuse .or. use(k) .or. use(kv))
c
c     compute the energy contribution for this interaction
c
            if (proceed) then
               kt = class(k)
               do j = 1, ncell
                  xr = xi - xred(k)
                  yr = yi - yred(k)
                  zr = zi - zred(k)
                  call image (xr,yr,zr,j)
                  rik2 = xr*xr + yr*yr + zr*zr
c
c     check for an interaction distance less than the cutoff
c
                  if (rik2 .le. off2) then
                     fterm = 1.0d0
                     rv = radmin(kt,it)
                     eps = epsilon(kt,it)
                     if (radhbnd(kt,it) .ne. 0.0d0) then
                        rv = radhbnd(kt,it)
                        eps = epshbnd(kt,it) / dielec
                        if (atomic(i) .eq. 1) then
                           ia = i
                           ib = i12(1,i)
                           ic = k
                        else
                           ia = k
                           ib = i12(1,k)
                           ic = i
                        end if
                        xia = x(ia)
                        yia = y(ia)
                        zia = z(ia)
                        xib = x(ib)
                        yib = y(ib)
                        zib = z(ib)
                        xic = x(ic)
                        yic = y(ic)
                        zic = z(ic)
                        xab = xia - xib
                        yab = yia - yib
                        zab = zia - zib
                        rab2 = xab*xab + yab*yab + zab*zab
                        rab = sqrt(rab2)
                        xcb = xic - xib
                        ycb = yic - yib
                        zcb = zic - zib
                        call image (xcb,ycb,zcb,j)
                        rcb2 = xcb*xcb + ycb*ycb + zcb*zcb
                        rcb2 = max(0.01d0,rcb2)
                        xp = ycb*zab - zcb*yab
                        yp = zcb*xab - xcb*zab
                        zp = xcb*yab - ycb*xab
                        rp = sqrt(xp*xp + yp*yp + zp*zp)
                        dot = xab*xcb + yab*ycb + zab*zcb
                        cosine = dot / sqrt(rab2*rcb2)
                        ideal = bl(bndlist(1,ia))
                        fterm = cosine * (rab/ideal)
                     end if
                     if (use_polymer) then
                        if (rik2 .le. polycut2) then
                           if (iv14(k) .eq. i) then
                              fterm = 1.0d0
                              rv = radmin4(kt,it)
                              eps = epsilon4(kt,it)
                           end if
                           eps = eps * vscale(k)
                        end if
                     end if
                     p2 = (rv*rv) / rik2
                     p6 = p2 * p2 * p2
                     if (p2 .le. expmin2) then
                        e = 0.0d0
                     else if (p2 .le. expcut2) then
                        p = sqrt(p2)
                        expterm = abuck * exp(-bbuck/p)
                        e = eps * (expterm - fterm*cbuck*p6)
                     else
                        p12 = p6 * p6
                        e = expmerge * eps * p12
                     end if
c
c     use energy switching if near the cutoff distance
c
                     if (rik2 .gt. cut2) then
                        rik = sqrt(rik2)
                        rik3 = rik2 * rik
                        rik4 = rik2 * rik2
                        rik5 = rik2 * rik3
                        taper = c5*rik5 + c4*rik4 + c3*rik3
     &                                + c2*rik2 + c1*rik + c0
                        e = e * taper
                     end if
c
c     scale the interaction based on its group membership
c
                     if (use_group)  e = e * fgrp
c
c     increment the overall van der Waals energy component
c
                     if (e .ne. 0.0d0) then
                        nev = nev + 1
                        if (i .eq. k) then
                           ev = ev + 0.5d0*e
                           aev(i) = aev(i) + 0.5d0*e
                        else
                           ev = ev + e
                           aev(i) = aev(i) + 0.5d0*e
                           aev(k) = aev(k) + 0.5d0*e
                        end if
                     end if
c
c     increment the total intermolecular energy
c
                     einter = einter + e
c
c     print a message if the energy of this interaction is large
c
                     huge = (e .gt. 10.0d0)
                     if ((debug.and.e.ne.0.0d0)
     &                     .or. (verbose.and.huge)) then
                        if (header) then
                           header = .false.
                           write (iout,30)
   30                      format (/,' Individual van der Waals',
     &                                ' Interactions :',
     &                             //,' Type',13x,'Atom Names',
     &                                18x,'Minimum',4x,'Actual',
     &                                6x,'Energy',/)
                        end if
                        write (iout,40)  i,name(i),k,name(k),
     &                                   rv,sqrt(rik2),e
   40                   format (' VDW-MM3',4x,i5,'-',a3,1x,i5,'-',
     &                             a3,3x,'(XTAL)',3x,2f10.4,f12.4)
                     end if
                  end if
               end do
            end if
         end do
      end do
      return
      end
c
c
c     ##################################################################
c     ##                                                              ##
c     ##  subroutine emm3hb3b  --  MM3 vdw-hbond analysis via lights  ##
c     ##                                                              ##
c     ##################################################################
c
c
c     "emm3hb3b" calculates the MM3 exp-6 van der Waals and
c     directional charge transfer hydrogen bonding energy using
c     the method of lights to locate neighboring atoms
c
c
      subroutine emm3hb3b
      implicit none
      include 'sizes.i'
      include 'action.i'
      include 'analyz.i'
      include 'atmlst.i'
      include 'atmtyp.i'
      include 'atoms.i'
      include 'bond.i'
      include 'bound.i'
      include 'boxes.i'
      include 'cell.i'
      include 'chgpot.i'
      include 'couple.i'
      include 'energi.i'
      include 'group.i'
      include 'inform.i'
      include 'inter.i'
      include 'iounit.i'
      include 'light.i'
      include 'molcul.i'
      include 'shunt.i'
      include 'usage.i'
      include 'vdw.i'
      include 'vdwpot.i'
      integer i,j,k,ii,kk
      integer iv,kv,it,kt
      integer ia,ib,ic
      integer kgy,kgz
      integer start,stop
      integer iv14(maxatm)
      integer map(maxlight)
      real*8 e,rv,eps
      real*8 rdn,fgrp
      real*8 p,p2,p6,p12
      real*8 xi,yi,zi
      real*8 xk,yk,zk
      real*8 xr,yr,zr
      real*8 rik,rik2,rik3
      real*8 rik4,rik5,taper
      real*8 expcut,expcut2
      real*8 expterm,expmin2
      real*8 expmerge,ideal
      real*8 dot,cosine
      real*8 rterm,fterm
      real*8 xab,yab,zab
      real*8 xcb,ycb,zcb
      real*8 rab2,rab,rcb2
      real*8 xp,yp,zp,rp
      real*8 xred(maxatm)
      real*8 yred(maxatm)
      real*8 zred(maxatm)
      real*8 vscale(maxatm)
      real*8 xsort(maxlight)
      real*8 ysort(maxlight)
      real*8 zsort(maxlight)
      logical proceed,iuse,repeat
      logical header,huge
c
c
c     zero out the van der Waals energy and partitioning terms
c
      nev = 0
      ev = 0.0d0
      do i = 1, n
         aev(i) = 0.0d0
      end do
      header = .true.
c
c     zero out the array marking 1-4 vdw interactions
c
      do i = 1, n
         iv14(i) = 0
      end do
c
c     set the coefficients for the switching function
c
      call switch ('VDW')
c
c     special cutoffs for very short and very long range terms
c
      expmin2 = 0.01d0
      expcut = 2.0d0
      expcut2 = expcut * expcut
      expmerge = (abuck*exp(-bbuck/expcut) - cbuck*(expcut**6))
     &                               / (expcut**12)
c
c     apply any reduction factor to the atomic coordinates
c
      do j = 1, nvdw
         i = ivdw(j)
         iv = ired(i)
         rdn = kred(i)
         xred(j) = rdn*(x(i)-x(iv)) + x(iv)
         yred(j) = rdn*(y(i)-y(iv)) + y(iv)
         zred(j) = rdn*(z(i)-z(iv)) + z(iv)
      end do
c
c     transfer the interaction site coordinates to sorting arrays
c
      do i = 1, nvdw
         xsort(i) = xred(i)
         ysort(i) = yred(i)
         zsort(i) = zred(i)
      end do
c
c     use the method of lights to generate neighbors
c
      call lights (nvdw,map,xsort,ysort,zsort)
c
c     now, loop over all atoms computing the interactions
c
      do ii = 1, nvdw
         i = ivdw(ii)
         iv = ired(i)
         it = class(i)
         xi = xsort(rgx(ii))
         yi = ysort(rgy(ii))
         zi = zsort(rgz(ii))
         iuse = (use(i) .or. use(iv))
         do j = 1, nvdw
            vscale(ivdw(j)) = 1.0d0
         end do
         do j = 1, n12(i)
            vscale(i12(j,i)) = v2scale
         end do
         do j = 1, n13(i)
            vscale(i13(j,i)) = v3scale
         end do
         do j = 1, n14(i)
            vscale(i14(j,i)) = v4scale
            iv14(i14(j,i)) = i
         end do
         do j = 1, n15(i)
            vscale(i15(j,i)) = v5scale
         end do
         if (kbx(ii) .le. kex(ii)) then
            repeat = .false.
            start = kbx(ii) + 1
            stop = kex(ii)
         else
            repeat = .true.
            start = 1
            stop = kex(ii)
         end if
   10    continue
         do j = start, stop
            kk = locx(j)
            kgy = rgy(kk)
            if (kby(ii) .le. key(ii)) then
               if (kgy.lt.kby(ii) .or. kgy.gt.key(ii))  goto 40
            else
               if (kgy.lt.kby(ii) .and. kgy.gt.key(ii))  goto 40
            end if
            kgz = rgz(kk)
            if (kbz(ii) .le. kez(ii)) then
               if (kgz.lt.kbz(ii) .or. kgz.gt.kez(ii))  goto 40
            else
               if (kgz.lt.kbz(ii) .and. kgz.gt.kez(ii))  goto 40
            end if
            k = ivdw(map(kk))
            kv = ired(k)
c
c     decide whether to compute the current interaction
c
            proceed = .true.
            if (use_group)  call groups (proceed,fgrp,i,k,0,0,0,0)
            if (proceed)  proceed = (iuse .or. use(k) .or. use(kv))
c
c     compute the energy contribution for this interaction
c
            if (proceed) then
               kt = class(k)
               xk = xsort(j)
               yk = ysort(kgy)
               zk = zsort(kgz)
               xr = xi - xk
               yr = yi - yk
               zr = zi - zk
               if (use_image) then
                  if (abs(xr) .gt. xcell2)  xr = xr - sign(xcell,xr)
                  if (abs(yr) .gt. ycell2)  yr = yr - sign(ycell,yr)
                  if (abs(zr) .gt. zcell2)  zr = zr - sign(zcell,zr)
                  if (monoclinic) then
                     xr = xr + zr*beta_cos
                     zr = zr * beta_sin
                  else if (triclinic) then
                     xr = xr + yr*gamma_cos + zr*beta_cos
                     yr = yr*gamma_sin + zr*beta_term
                     zr = zr * gamma_term
                  end if
               end if
               rik2 = xr*xr + yr*yr + zr*zr
c
c     check for an interaction distance less than the cutoff
c
               if (rik2 .le. off2) then
                  fterm = 1.0d0
                  rv = radmin(kt,it)
                  eps = epsilon(kt,it)
                  if (iv14(k) .eq. i) then
                     rv = radmin4(kt,it)
                     eps = epsilon4(kt,it)
                  else if (radhbnd(kt,it) .ne. 0.0d0) then
                     rv = radhbnd(kt,it)
                     eps = epshbnd(kt,it) / dielec
                     if (atomic(i) .eq. 1) then
                        ia = i
                        ib = i12(1,i)
                        ic = k
                        rterm = kred(ia)
                        xab = x(ia) - x(ib)
                        yab = y(ia) - y(ib)
                        zab = z(ia) - z(ib)
                        xcb = xab*rterm - xr
                        ycb = yab*rterm - yr
                        zcb = zab*rterm - zr
                     else
                        ia = k
                        ib = i12(1,k)
                        ic = i
                        rterm = kred(ia)
                        xab = x(ia) - x(ib)
                        yab = y(ia) - y(ib)
                        zab = z(ia) - z(ib)
                        xcb = xab*rterm + xr
                        ycb = yab*rterm + yr
                        zcb = zab*rterm + zr
                     end if
                     rab2 = xab*xab + yab*yab + zab*zab
                     rab = sqrt(rab2)
                     rcb2 = xcb*xcb + ycb*ycb + zcb*zcb
                     rcb2 = max(0.01d0,rcb2)
                     xp = ycb*zab - zcb*yab
                     yp = zcb*xab - xcb*zab
                     zp = xcb*yab - ycb*xab
                     rp = sqrt(xp*xp + yp*yp + zp*zp)
                     dot = xab*xcb + yab*ycb + zab*zcb
                     cosine = dot / sqrt(rab2*rcb2)
                     ideal = bl(bndlist(1,ia))
                     fterm = cosine * (rab/ideal)
                  end if
                  eps = eps * vscale(k)
                  p2 = (rv*rv) / rik2
                  p6 = p2 * p2 * p2
                  if (p2 .le. expmin2) then
                     e = 0.0d0
                  else if (p2 .le. expcut2) then
                     p = sqrt(p2)
                     expterm = abuck * exp(-bbuck/p)
                     e = eps * (expterm - fterm*cbuck*p6)
                  else
                     p12 = p6 * p6
                     e = expmerge * eps * p12
                  end if
c
c     use energy switching if near the cutoff distance
c
                  if (rik2 .gt. cut2) then
                     rik = sqrt(rik2)
                     rik3 = rik2 * rik
                     rik4 = rik2 * rik2
                     rik5 = rik2 * rik3
                     taper = c5*rik5 + c4*rik4 + c3*rik3
     &                             + c2*rik2 + c1*rik + c0
                     e = e * taper
                  end if
c
c     scale the interaction based on its group membership
c
                  if (use_group)  e = e * fgrp
c
c     increment the overall van der Waals energy components
c
                  if (e .ne. 0.0d0)  nev = nev + 1
                  ev = ev + e
                  aev(i) = aev(i) + 0.5d0*e
                  aev(k) = aev(k) + 0.5d0*e
c
c     increment the total intermolecular energy
c
                  if (molcule(i) .ne. molcule(k)) then
                     einter = einter + e
                  end if
c
c     print a message if the energy of this interaction is large
c
                  huge = (e .gt. 10.0d0)
                  if ((debug.and.e.ne.0.0d0)
     &                  .or. (verbose.and.huge)) then
                     if (header) then
                        header = .false.
                        write (iout,20)
   20                   format (/,' Individual van der Waals',
     &                             ' Interactions :',
     &                          //,' Type',13x,'Atom Names',
     &                             18x,'Minimum',4x,'Actual',
     &                             6x,'Energy',/)
                     end if
                     write (iout,30)  i,name(i),k,name(k),
     &                                rv,sqrt(rik2),e
   30                format (' VDW-MM3',4x,i5,'-',a3,1x,i5,'-',
     &                          a3,12x,2f10.4,f12.4)
                  end if
               end if
            end if
   40       continue
         end do
         if (repeat) then
            repeat = .false.
            start = kbx(ii) + 1
            stop = nlight
            goto 10
         end if
      end do
      return
      end
