 
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
c     ##  subroutine kvdw  --  van der Waals parameter assignment  ##
c     ##                                                           ##
c     ###############################################################
c
c
c     "kvdw" assigns the parameters to be used in computing the
c     van der Waals interactions and processes any new or changed
c     values for these parameters
c
c
      subroutine kvdw
      implicit none
      include 'sizes.i'
      include 'atmtyp.i'
      include 'atoms.i'
      include 'couple.i'
      include 'inform.i'
      include 'iounit.i'
      include 'keys.i'
      include 'khbond.i'
      include 'kvdws.i'
      include 'kvdwpr.i'
      include 'math.i'
      include 'potent.i'
      include 'vdw.i'
      include 'vdwpot.i'
      integer i,k,ia,ib,next
      integer size,number
      real*8 rd,ep,rdn
      real*8 srad(maxclass)
      real*8 srad4(maxclass)
      real*8 seps(maxclass)
      real*8 seps4(maxclass)
      logical header
      character*4 pa,pb
      character*8 blank,pt
      character*20 keyword
      character*120 record
      character*120 string
c
c
c     process keywords containing van der Waals parameters
c
      blank = '        '
      header = .true.
      do i = 1, nkey
         next = 1
         record = keyline(i)
         call gettext (record,keyword,next)
         call upcase (keyword)
         if (keyword(1:4) .eq. 'VDW ') then
            k = 0
            rd = 0.0d0
            ep = 0.0d0
            rdn = 0.0d0
            string = record(next:120)
            read (string,*,err=10,end=10)  k,rd,ep,rdn
   10       continue
            if (k.ge.1 .and. k.le.maxclass) then
               if (header) then
                  header = .false.
                  write (iout,20)
   20             format (/,' Additional van der Waals Parameters :',
     &                    //,5x,'Atom Class',9x,'Radius',5x,'Epsilon',
     &                       5x,'Reduction',/)
               end if
               if (ep .eq. 0.0d0)  ep = eps(k)
               if (rdn .eq. 0.0d0)  rdn = reduct(k)
               rad(k) = rd
               eps(k) = ep
               reduct(k) = rdn
               write (iout,30)  k,rd,ep,rdn
   30          format (4x,i6,8x,2f12.4,f12.3)
            else if (k .gt. maxclass) then
               write (iout,40)  maxclass
   40          format (/,' KVDW  --  Only Atom Classes through',i4,
     &                    ' are Allowed')
               abort = .true.
            end if
         end if
      end do
c
c     process keywords containing 1-4 van der Waals parameters
c
      header = .true.
      do i = 1, nkey
         next = 1
         record = keyline(i)
         call gettext (record,keyword,next)
         call upcase (keyword)
         if (keyword(1:6) .eq. 'VDW14 ') then
            k = 0
            rd = 0.0d0
            ep = 0.0d0
            string = record(next:120)
            read (string,*,err=50,end=50)  k,rd,ep
   50       continue
            if (k.ge.1 .and. k.le.maxclass) then
               if (header) then
                  header = .false.
                  write (iout,60)
   60             format (/,' Additional 1-4 van der Waals',
     &                       ' Parameters :',
     &                    //,5x,'Atom Class',9x,'Radius',5x,'Epsilon',/)
               end if
               if (ep .eq. 0.0d0)  ep = eps4(k)
               rad4(k) = rd
               eps4(k) = ep
               write (iout,70)  k,rd,ep
   70          format (4x,i6,8x,2f12.4)
            else if (k .gt. maxclass) then
               write (iout,80)  maxclass
   80          format (/,' KVDW  --  Only Atom Classes through',i4,
     &                    ' are Allowed')
               abort = .true.
            end if
         end if
      end do
c
c     process keywords containing specific pair vdw parameters
c
      header = .true.
      do i = 1, nkey
         next = 1
         record = keyline(i)
         call gettext (record,keyword,next)
         call upcase (keyword)
         if (keyword(1:6) .eq. 'VDWPR ') then
            ia = 0
            ib = 0
            rd = 0.0d0
            ep = 0.0d0
            string = record(next:120)
            read (string,*,err=120,end=120)  ia,ib,rd,ep
            if (header) then
               header = .false.
               write (iout,90)
   90          format (/,' Additional van der Waals Parameters',
     &                    ' for Specific Pairs :',
     &                 //,5x,'Atom Classes',6x,'Radii Sum',
     &                    3x,'Epsilon',/)
            end if
            write (iout,100)  ia,ib,rd,ep
  100       format (6x,2i4,4x,2f12.4)
            size = 4
            call numeral (ia,pa,size)
            call numeral (ib,pb,size)
            if (ia .le. ib) then
               pt = pa//pb
            else
               pt = pb//pa
            end if
            do k = 1, maxnvp
               if (kvpr(k).eq.blank .or. kvpr(k).eq.pt) then
                  kvpr(k) = pt
                  radpr(k) = rd
                  epspr(k) = ep
                  goto 120
               end if
            end do
            write (iout,110)
  110       format (/,' KVDW  --  Too many Special VDW Pair',
     &                 ' Parameters')
            abort = .true.
  120       continue
         end if
      end do
c
c     process keywords containing hydrogen bonding vdw parameters
c
      header = .true.
      do i = 1, nkey
         next = 1
         record = keyline(i)
         call gettext (record,keyword,next)
         call upcase (keyword)
         if (keyword(1:6) .eq. 'HBOND ') then
            ia = 0
            ib = 0
            rd = 0.0d0
            ep = 0.0d0
            string = record(next:120)
            read (string,*,err=160,end=160)  ia,ib,rd,ep
            if (header) then
               header = .false.
               write (iout,130)
  130          format (/,' Additional van der Waals Hydrogen',
     &                    ' Bonding Parameters :',
     &                 //,5x,'Atom Classes',6x,'Radii Sum',
     &                    3x,'Epsilon',/)
            end if
            write (iout,140)  ia,ib,rd,ep
  140       format (6x,2i4,4x,2f12.4)
            size = 4
            call numeral (ia,pa,size)
            call numeral (ib,pb,size)
            if (ia .le. ib) then
               pt = pa//pb
            else
               pt = pb//pa
            end if
            do k = 1, maxnvp
               if (khb(k).eq.blank .or. khb(k).eq.pt) then
                  khb(k) = pt
                  radhb(k) = rd
                  epshb(k) = ep
                  goto 160
               end if
            end do
            write (iout,150)
  150       format (/,' KVDW  --  Too many Hydrogen Bonding Pair',
     &                 ' Parameters')
            abort = .true.
  160       continue
         end if
      end do
c
c     get the vdw radii and well depths for each atom class
c
      do i = 1, maxclass
         if (rad4(i) .eq. 0.0d0)  rad4(i) = rad(i)
         if (eps4(i) .eq. 0.0d0)  eps4(i) = eps(i)
         if (radtyp .eq. 'SIGMA') then
            rad(i) = twosix * rad(i)
            rad4(i) = twosix * rad4(i)
         end if
         if (radsiz .eq. 'DIAMETER') then
            rad(i) = 0.5d0 * rad(i)
            rad4(i) = 0.5d0 * rad4(i)
         end if
         srad(i) = sqrt(rad(i))
         eps(i) = abs(eps(i))
         seps(i) = sqrt(eps(i))
         srad4(i) = sqrt(rad4(i))
         eps4(i) = abs(eps4(i))
         seps4(i) = sqrt(eps4(i))
      end do
c
c     use combination rules to set pairwise vdw radii sums
c
      do i = 1, maxclass
         do k = i, maxclass
            if (rad(i).eq.0.0d0 .and. rad(k).eq.0.0d0) then
               rd = 0.0d0
            else if (radrule(1:10) .eq. 'ARITHMETIC') then
               rd = rad(i) + rad(k)
            else if (radrule(1:9) .eq. 'GEOMETRIC') then
               rd = 2.0d0 * (srad(i) * srad(k))
            else if (radrule(1:10) .eq. 'CUBIC-MEAN') then
               rd = 2.0d0 * (rad(i)**3+rad(k)**3)/(rad(i)**2+rad(k)**2)
            else
               rd = rad(i) + rad(k)
            end if
            radmin(i,k) = rd
            radmin(k,i) = rd
         end do
      end do
c
c     use combination rules to set pairwise well depths
c
      do i = 1, maxclass
         do k = i, maxclass
            if (eps(i).eq.0.0d0 .and. eps(k).eq.0.0d0) then
               ep = 0.0d0
            else if (epsrule(1:10) .eq. 'ARITHMETIC') then
               ep = 0.5d0 * (eps(i) + eps(k))
            else if (epsrule(1:9) .eq. 'GEOMETRIC') then
               ep = seps(i) * seps(k)
            else if (epsrule(1:8) .eq. 'HARMONIC') then
               ep = 2.0d0 * (eps(i)*eps(k)) / (eps(i)+eps(k))
            else if (epsrule(1:3) .eq. 'HHG') then
               ep = 4.0d0 * (eps(i)*eps(k)) / (seps(i)+seps(k))**2
            else
               ep = seps(i) * seps(k)
            end if
            epsilon(i,k) = ep
            epsilon(k,i) = ep
         end do
      end do
c
c     use combination rules to set pairwise 1-4 vdw radii sums
c
      do i = 1, maxclass
         do k = i, maxclass
            if (rad4(i).eq.0.0d0 .and. rad4(k).eq.0.0d0) then
               rd = 0.0d0
            else if (radrule(1:10) .eq. 'ARITHMETIC') then
               rd = rad4(i) + rad4(k)
            else if (radrule(1:9) .eq. 'GEOMETRIC') then
               rd = 2.0d0 * (srad4(i) * srad4(k))
            else if (radrule(1:10) .eq. 'CUBIC-MEAN') then
               rd = 2.0d0 * (rad4(i)**3+rad4(k)**3)
     &                         / (rad4(i)**2+rad4(k)**2)
            else
               rd = rad4(i) + rad4(k)
            end if
            radmin4(i,k) = rd
            radmin4(k,i) = rd
         end do
      end do
c
c     use combination rules to set pairwise 1-4 well depths
c
      do i = 1, maxclass
         do k = i, maxclass
            if (eps4(i).eq.0.0d0 .and. eps4(k).eq.0.0d0) then
               ep = 0.0d0
            else if (epsrule(1:10) .eq. 'ARITHMETIC') then
               ep = 0.5d0 * (eps4(i) + eps4(k))
            else if (epsrule(1:9) .eq. 'GEOMETRIC') then
               ep = seps4(i) * seps4(k)
            else if (epsrule(1:8) .eq. 'HARMONIC') then
               ep = 2.0d0 * (eps4(i)*eps4(k)) / (eps4(i)+eps4(k))
            else if (epsrule(1:3) .eq. 'HHG') then
               ep = 4.0d0 * (eps4(i)*eps4(k)) / (seps4(i)+seps4(k))**2
            else
               ep = seps4(i) * seps4(k)
            end if
            epsilon4(i,k) = ep
            epsilon4(k,i) = ep
         end do
      end do
c
c     vdw reduction factor information for each individual atom
c
      do i = 1, n
         kred(i) = reduct(class(i))
         if (n12(i).ne.1 .or. kred(i).eq.0.0d0) then
            ired(i) = i
         else
            ired(i) = i12(1,i)
         end if
      end do
c
c     radii and well depths for special atom class pairs
c
      do i = 1, maxnvp
         if (kvpr(i) .eq. blank)  goto 170
         ia = number(kvpr(i)(1:4))
         ib = number(kvpr(i)(5:8))
         if (rad(ia) .eq. 0.0d0)  rad(ia) = 0.001d0
         if (rad(ib) .eq. 0.0d0)  rad(ib) = 0.001d0
         if (radtyp .eq. 'SIGMA')  radpr(i) = twosix * radpr(i)
         radmin(ia,ib) = radpr(i)
         radmin(ib,ia) = radpr(i)
         epsilon(ia,ib) = abs(epspr(i))
         epsilon(ib,ia) = abs(epspr(i))
         radmin4(ia,ib) = radpr(i)
         radmin4(ib,ia) = radpr(i)
         epsilon4(ia,ib) = abs(epspr(i))
         epsilon4(ib,ia) = abs(epspr(i))
      end do
  170 continue
c
c     radii and well depths for hydrogen bonding pairs
c
      if (vdwtyp .eq. 'MM3-HBOND') then
         do i = 1, maxclass
            do k = 1, maxclass
               radhbnd(k,i) = 0.0d0
               epshbnd(k,i) = 0.0d0
            end do
         end do
         do i = 1, maxnhb
            if (khb(i) .eq. blank)  goto 180
            ia = number(khb(i)(1:4))
            ib = number(khb(i)(5:8))
            if (rad(ia) .eq. 0.0d0)  rad(ia) = 0.001d0
            if (rad(ib) .eq. 0.0d0)  rad(ib) = 0.001d0
            if (radtyp .eq. 'SIGMA')  radhb(i) = twosix * radhb(i)
            radhbnd(ia,ib) = radhb(i)
            radhbnd(ib,ia) = radhb(i)
            epshbnd(ia,ib) = abs(epshb(i))
            epshbnd(ib,ia) = abs(epshb(i))
         end do
  180    continue
      end if
c
c     set coefficients for Gaussian fit to eps=1 and radmin=1
c
      if (vdwtyp .eq. 'GAUSSIAN') then
         if (gausstyp .eq. 'LJ-4') then
            ngauss = 4
            igauss(1,1) = 846706.7d0
            igauss(2,1) = 15.464405d0 * twosix**2
            igauss(1,2) = 2713.651d0
            igauss(2,2) = 7.346875d0 * twosix**2
            igauss(1,3) = -9.699172d0
            igauss(2,3) = 1.8503725d0 * twosix**2
            igauss(1,4) = -0.7154420d0
            igauss(2,4) = 0.639621d0 * twosix**2
         else if (gausstyp .eq. 'LJ-2') then
            ngauss = 2
            igauss(1,1) = 14487.1d0
            igauss(2,1) = 9.05148d0 * twosix**2
            igauss(1,2) = -5.55338d0
            igauss(2,2) = 1.22536d0 * twosix**2
         else if (gausstyp .eq. 'MM3-2') then
            ngauss = 2
            igauss(1,1) = 2438.886d0
            igauss(2,1) = 9.342616d0
            igauss(1,2) = -6.197368d0
            igauss(2,2) = 1.564486d0
         else if (gausstyp .eq. 'MM2-2') then
            ngauss = 2
            igauss(1,1) = 3423.562d0
            igauss(2,1) = 9.692821d0
            igauss(1,2) = -6.503760d0
            igauss(2,2) = 1.585344d0
         else if (gausstyp .eq. 'IN-PLACE') then
            ngauss = 2
            igauss(1,1) = 500.0d0
            igauss(2,1) = 6.143d0
            igauss(1,2) = -18.831d0
            igauss(2,2) = 2.209d0
         end if
      end if
c
c     remove zero-sized atoms from the list of vdw sites
c
      nvdw = 0
      do i = 1, n
         if (rad(class(i)) .ne. 0.0d0) then
            nvdw = nvdw + 1
            ivdw(nvdw) = i
         end if
      end do
c
c     turn off the van der Waals potential if it is not used
c
      if (nvdw .eq. 0)  use_vdw = .false.
      return
      end
