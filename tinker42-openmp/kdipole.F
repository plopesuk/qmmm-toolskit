 
C     $Id$
c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1990  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     #############################################################
c     ##                                                         ##
c     ##  subroutine kdipole  --  assign bond dipole parameters  ##
c     ##                                                         ##
c     #############################################################
c
c
c     "kdipole" assigns bond dipoles to the bonds within
c     the structure and processes any new or changed values
c
c
      subroutine kdipole
      implicit none
      include 'sizes.i'
      include 'atmlst.i'
      include 'atoms.i'
      include 'bond.i'
      include 'couple.i'
      include 'dipole.i'
      include 'inform.i'
      include 'iounit.i'
      include 'kdipol.i'
      include 'keys.i'
      include 'potent.i'
      include 'ring.i'
      integer i,j,k,m
      integer ia,ib,ic,id
      integer ita,itb
      integer nd,nd5,nd4,nd3
      integer iring,size,next
      real*8 dp,ps
      logical header
      logical use_ring3
      logical use_ring4
      logical use_ring5
      character*4 pa,pb
      character*6 label
      character*8 blank,pt
      character*20 keyword
      character*120 record
      character*120 string
c
c
c     process keywords containing bond dipole parameters
c
      blank = '        '
      header = .true.
      do i = 1, nkey
         next = 1
         record = keyline(i)
         call gettext (record,keyword,next)
         call upcase (keyword)
         iring = -1
         if (keyword(1:7) .eq. 'DIPOLE ')  iring = 0
         if (keyword(1:8) .eq. 'DIPOLE5 ')  iring = 5
         if (keyword(1:8) .eq. 'DIPOLE4 ')  iring = 4
         if (keyword(1:8) .eq. 'DIPOLE3 ')  iring = 3
         if (iring .ge. 0) then
            ia = 0
            ib = 0
            dp = 0.0d0
            ps = 0.5d0
            string = record(next:120)
            read (string,*,err=10,end=10)  ia,ib,dp,ps
   10       continue
            if (ia.gt.0 .and. ib.gt.0) then
               if (header) then
                  header = .false.
                  write (iout,20)
   20             format (/,' Additional Bond Dipole Moment ',
     &                       'Parameters :',
     &                    //,5x,'Atom Types',9x,'Moment',
     &                       5x,'Position',/)
               end if
               if (iring .eq. 0) then
                  write (iout,30)  ia,ib,dp,ps
   30             format (6x,2i4,4x,2f12.3)
               else
                  if (iring .eq. 5)  label = '5-Ring'
                  if (iring .eq. 4)  label = '4-Ring'
                  if (iring .eq. 3)  label = '3-Ring'
                  write (iout,40)  ia,ib,dp,ps,label
   40             format (6x,2i4,4x,2f12.3,3x,a6)
               end if
               size = 4
               call numeral (ia,pa,size)
               call numeral (ib,pb,size)
               if (ia .le. ib) then
                  pt = pa//pb
               else
                  pt = pb//pa
               end if
               if (iring .eq. 0) then
                  do j = 1, maxnd
                     if (kd(j).eq.blank .or. kd(j).eq.pt) then
                        kd(j) = pt
                        if (ia .le. ib) then
                           dpl(j) = dp
                           pos(j) = ps
                        else
                           dpl(j) = -dp
                           pos(j) = 1.0d0 - ps
                        end if
                        goto 90
                     end if
                  end do
                  write (iout,50)
   50             format (/,' KDIPOLE  --  Too many Bond Dipole',
     &                       ' Moment Parameters')
                  abort = .true.
               else if (iring .eq. 5) then
                  do j = 1, maxnd5
                     if (kd5(j).eq.blank .or. kd5(j).eq.pt) then
                        kd5(j) = pt
                        if (ia .le. ib) then
                           dpl5(j) = dp
                           pos5(j) = ps
                        else
                           dpl5(j) = -dp
                           pos5(j) = 1.0d0 - ps
                        end if
                        goto 90
                     end if
                  end do
                  write (iout,60)
   60             format (/,' KDIPOLE  --  Too many 5-Ring Bond',
     &                       ' Dipole Parameters')
                  abort = .true.
               else if (iring .eq. 4) then
                  do j = 1, maxnd4
                     if (kd4(j).eq.blank .or. kd4(j).eq.pt) then
                        kd4(j) = pt
                        if (ia .le. ib) then
                           dpl4(j) = dp
                           pos4(j) = ps
                        else
                           dpl4(j) = -dp
                           pos4(j) = 1.0d0 - ps
                        end if
                        goto 90
                     end if
                  end do
                  write (iout,70)
   70             format (/,' KDIPOLE  --  Too many 4-Ring Bond',
     &                       ' Dipole Parameters')
                  abort = .true.
               else if (iring .eq. 3) then
                  do j = 1, maxnd3
                     if (kd3(j).eq.blank .or. kd3(j).eq.pt) then
                        kd3(j) = pt
                        if (ia .le. ib) then
                           dpl3(j) = dp
                           pos3(j) = ps
                        else
                           dpl3(j) = -dp
                           pos3(j) = 1.0d0 - ps
                        end if
                        goto 90
                     end if
                  end do
                  write (iout,80)
   80             format (/,' KDIPOLE  --  Too many 3-Ring Bond',
     &                       ' Dipole Parameters')
                  abort = .true.
               end if
            end if
   90       continue
         end if
      end do
c
c     determine the total number of forcefield parameters
c
      nd = maxnd
      nd5 = maxnd5
      nd4 = maxnd4
      nd3 = maxnd3
      do i = maxnd, 1, -1
         if (kd(i) .eq. blank)  nd = i - 1
      end do
      do i = maxnd5, 1, -1
         if (kd5(i) .eq. blank)  nd5 = i - 1
      end do
      do i = maxnd4, 1, -1
         if (kd4(i) .eq. blank)  nd4 = i - 1
      end do
      do i = maxnd3, 1, -1
         if (kd3(i) .eq. blank)  nd3 = i - 1
      end do
c
c     use small rings if present and parameters are available
c
      use_ring5 = .true.
      use_ring4 = .true.
      use_ring3 = .true.
      if (nring5.eq.0 .or. nd5.eq.0)  use_ring5 = .false.
      if (nring4.eq.0 .or. nd4.eq.0)  use_ring4 = .false.
      if (nring3.eq.0 .or. nd3.eq.0)  use_ring3 = .false.
c
c     find and store all the bond dipole moments
c
      do i = 1, nbond
         ia = ibnd(1,i)
         ib = ibnd(2,i)
         ita = type(ia)
         itb = type(ib)
         size = 4
         call numeral (ita,pa,size)
         call numeral (itb,pb,size)
         if (ita .le. itb) then
            pt = pa//pb
         else
            pt = pb//pa
         end if
         bdpl(i) = 0.0d0
c
c     make a check for bonds inside small rings
c
         iring = 0
         if (n12(ia).eq.1 .or. n12(ib).eq.1)  goto 100
         if (use_ring3) then
            do j = 1, n12(ia)
               ic = i12(j,ia)
               do k = 1, n12(ib)
                  if (ic .eq. i12(k,ib)) then
                     iring = 3
                     goto 100
                  end if
               end do
            end do
         end if
         if (use_ring4) then
            do j = 1, n12(ia)
               ic = i12(j,ia)
               if (ic .ne. ib) then
                  do k = 1, n12(ib)
                     id = i12(k,ib)
                     if (id .ne. ia) then
                        do m = 1, n12(ic)
                           if (id .eq. i12(m,ic)) then
                              iring = 4
                              goto 100
                           end if
                        end do
                     end if
                  end do
               end if
            end do
         end if
         if (use_ring5) then
            do j = 1, n13(ia)
               ic = i13(j,ia)
               do k = 1, n13(ib)
                  if (ic .eq. i13(k,ib)) then
                     iring = 5
                     goto 100
                  end if
               end do
            end do
         end if
  100    continue
c
c     try to assign bond dipole parameters for the bond
c
         if (iring .eq. 0) then
            do j = 1, nd
               if (kd(j) .eq. pt) then
                  if (ita .le. itb) then
                     idpl(1,i) = ia
                     idpl(2,i) = ib
                  else
                     idpl(1,i) = ib
                     idpl(2,i) = ia
                  end if
                  bdpl(i) = dpl(j)
                  sdpl(i) = pos(j)
                  goto 110
               end if
            end do
         else if (iring .eq. 5) then
            do j = 1, nd5
               if (kd5(j) .eq. pt) then
                  if (ita .le. itb) then
                     idpl(1,i) = ia
                     idpl(2,i) = ib
                  else
                     idpl(1,i) = ib
                     idpl(2,i) = ia
                  end if
                  bdpl(i) = dpl5(j)
                  sdpl(i) = pos5(j)
                  goto 110
               end if
            end do
         else if (iring .eq. 4) then
            do j = 1, nd4
               if (kd4(j) .eq. pt) then
                  if (ita .le. itb) then
                     idpl(1,i) = ia
                     idpl(2,i) = ib
                  else
                     idpl(1,i) = ib
                     idpl(2,i) = ia
                  end if
                  bdpl(i) = dpl4(j)
                  sdpl(i) = pos4(j)
                  goto 110
               end if
            end do
         else if (iring .eq. 3) then
            do j = 1, nd3
               if (kd3(j) .eq. pt) then
                  if (ita .le. itb) then
                     idpl(1,i) = ia
                     idpl(2,i) = ib
                  else
                     idpl(1,i) = ib
                     idpl(2,i) = ia
                  end if
                  bdpl(i) = dpl3(j)
                  sdpl(i) = pos3(j)
                  goto 110
               end if
            end do
         end if
  110    continue
      end do
c
c     process keywords containing bond specific bond dipoles
c
      header = .true.
      do i = 1, nkey
         next = 1
         record = keyline(i)
         call gettext (record,keyword,next)
         call upcase (keyword)
         if (keyword(1:7) .eq. 'DIPOLE ') then
            ia = 0
            ib = 0
            dp = 0.0d0
            ps = 0.0d0
            string = record(next:120)
            read (string,*,err=120,end=120)  ia,ib,dp,ps
  120       continue
            if (ia.lt.0 .and. ib.lt.0) then
               ia = -ia
               ib = -ib
               if (header) then
                  header = .false.
                  write (iout,130)
  130             format (/,' Additional Bond Dipoles for',
     &                       ' Specific Bonds :',
     &                    //,5x,'Bonded Atoms',7x,'Moment',
     &                          5x,'Position',/)
               end if
               do j = 1, n12(ia)
                  if (i12(j,ia) .eq. ib) then
                     k = bndlist(j,ia)
                     if (ps .eq. 0.0d0)  ps = 0.5d0
                     if (idpl(1,k) .eq. ib) then
                        bdpl(k) = dp
                        sdpl(k) = ps
                     else
                        bdpl(k) = -dp
                        sdpl(k) = 1.0d0 - ps
                     end if
                     write (iout,140)  ia,ib,dp,ps
  140                format (4x,i5,' -',i5,2x,2f12.3)
                     goto 150
                  end if
               end do
            end if
  150       continue
         end if
      end do
c
c     remove zero bond dipoles from the list of dipoles
c
      ndipole = 0
      do i = 1, nbond
         if (bdpl(i) .ne. 0.0d0) then
            ndipole = ndipole + 1
            idpl(1,ndipole) = idpl(1,i)
            idpl(2,ndipole) = idpl(2,i)
            bdpl(ndipole) = bdpl(i)
            sdpl(ndipole) = sdpl(i)
         end if
      end do
c
c     turn off dipole-dipole and charge-dipole terms if not used
c
      if (ndipole .eq. 0) then
         use_dipole = .false.
         use_chgdpl = .false.
      end if
      return
      end
