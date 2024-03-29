 
C     $Id$
c
c
c     #############################################################
c     ##  COPYRIGHT (C) 2003 by Pengyu Ren & Jay William Ponder  ##
c     ##                   All Rights Reserved                   ##
c     #############################################################
c
c     ##############################################################
c     ##                                                          ##
c     ##  subroutine ktortor  --  tors-tors parameter assignment  ##
c     ##                                                          ##
c     ##############################################################
c
c
c     "ktortor" assigns torsion-torsion parameters to adjacent
c     torsion pairs and processes any new or changed values
c
c
      subroutine ktortor
      implicit none
      include 'sizes.i'
      include 'atmtyp.i'
      include 'atoms.i'
      include 'bitor.i'
      include 'inform.i'
      include 'iounit.i'
      include 'keys.i'
      include 'ktrtor.i'
      include 'potent.i'
      include 'tortor.i'
      integer i,j,k,m
      integer ia,ib,ic,id,ie
      integer ita,itb,itc,itd,ite
      integer size,next,ntt
      integer nx,ny,nxy
      real*8 tx(maxtgrd2)
      real*8 ty(maxtgrd2)
      real*8 tf(maxtgrd2)
      real*8 bs(0:maxtgrd)
      real*8 cs(0:maxtgrd)
      real*8 ds(0:maxtgrd)
      real*8 tmp1(0:maxtgrd)
      real*8 tmp2(0:maxtgrd)
      real*8 tmp3(5*maxtgrd+1)
      logical header
      character*4 pa,pb,pc,pd,pe
      character*20 blank,pt
      character*20 pt1,pt2
      character*20 keyword
      character*120 record
      character*120 string
c
c
c     process keywords containing torsion-torsion parameters
c
      blank = '                    '
      header = .true.
      do i = 1, nkey
         next = 1
         record = keyline(i)
         call gettext (record,keyword,next)
         call upcase (keyword)
         if (keyword(1:8) .eq. 'TORTORS ') then
            ia = 0
            ib = 0
            ic = 0
            id = 0
            ie = 0
            nx = 0
            ny = 0
            nxy = 0
            do j = 1, maxtgrd2
               tx(j) = 0.0d0
               ty(j) = 0.0d0
               tf(j) = 0.0d0
            end do
            string = record(next:120)
            read (string,*,err=10,end=10)  ia,ib,ic,id,ie,nx,ny
            nxy = nx * ny
            do j = 1, nxy
               record = keyline(i+j)
               read (record,*,err=10,end=10)  tx(j),ty(j),tf(j)
            end do
   10       continue
            if (header) then
               header = .false.
               write (iout,20)
   20          format (/,' Additional Torsion-Torsion Parameters :',
     &                 //,5x,'Atom Classes',12x,'GridSize1',
     &                    5x,'GridSize2',/)
            end if
            write (iout,30)  ia,ib,ic,id,ie,nx,ny
   30       format (1x,5i4,6x,i8,6x,i8)
            size = 4
            call numeral (ia,pa,size)
            call numeral (ib,pb,size)
            call numeral (ic,pc,size)
            call numeral (id,pd,size)
            call numeral (ie,pe,size)
            pt = pa//pb//pc//pd//pe
            do j = 1, maxntt
               if (ktt(j).eq.blank .or. ktt(j).eq.pt) then
                  ktt(j) = pt
                  nx = nxy
                  call sort9 (nx,tx)
                  ny = nxy
                  call sort9 (ny,ty)
                  tnx(j) = nx
                  tny(j) = ny
                  do k = 1, nx
                     ttx(k,j) = tx(k)
                  end do
                  do k = 1, ny
                     tty(k,j) = ty(k)
                  end do
                  do k = 1, nxy
                     tbf(k,j) = tf(k)
                  end do
                  goto 50
               end if
            end do
            write (iout,40)
   40       format (/,' KTORTOR  --  Too many Torsion-Torsion',
     &                 ' Parameters')
            abort = .true.
   50       continue
         end if
      end do
c
c     determine the total number of forcefield parameters
c
      ntt = maxntt
      do i = maxntt, 1, -1
         if (ktt(i) .eq. blank)  ntt = i - 1
      end do
c
c     spline fit each row first, store values at grid points;
c     assumes the "tbf" array is sorted with both indices in
c     increasing order and the first index changing most rapidly
c
      do i = 1, ntt
         m = 0
         nx = tnx(i) - 1
         ny = tny(i) - 1
         do k = 1, tnx(i)
            tmp1(k-1) = ttx(k,i)
         end do
         do j = 1, tny(i)
            do k = 1, tnx(i)
               tmp2(k-1) = tbf(m+k,i)
            end do
            call isplpe (nx,tmp1,tmp2,1,bs,cs,ds,tmp3(1),tmp3(nx+2),
     &                   tmp3(2*nx+2),tmp3(3*nx+2),tmp3(4*nx+2))
            do k = 1, tnx(i)
               tbx(m+k,i) = bs(k-1)
            end do
            m = m + tnx(i)
         end do
         do k = 1, tny(i)
            tmp1(k-1) = tty(k,i)
         end do
         m = 1
         do j = 1, tnx(i)
            do k = 1, tny(i)
               tmp2(k-1) = tbf(m+(k-1)*tnx(i),i)
            end do
            call isplpe (ny,tmp1,tmp2,1,bs,cs,ds,tmp3(1),tmp3(ny+2),
     &                   tmp3(2*ny+2),tmp3(3*ny+2),tmp3(4*ny+2))
            do k = 1, tny(i)
               tby(m+(k-1)*tnx(i),i) = bs(k-1)
            end do
            m = m + 1
         end do
         m = 1
         do j = 1, tnx(i)
            do k = 1, tny(i)
               tmp2(k-1) = tbx(m+(k-1)*tnx(i),i)
            end do
            call isplpe (ny,tmp1,tmp2,1,bs,cs,ds,tmp3(1),tmp3(ny+2),
     &                   tmp3(2*ny+2),tmp3(3*ny+2),tmp3(4*ny+2))
            do k = 1, tny(i)
               tbxy(m+(k-1)*tnx(i),i) = bs(k-1)
            end do
            m = m + 1
         end do
      end do
c
c     assign torsion-torsion parameters for each bitorsion
c
      ntortor = 0
      do i = 1, nbitor
         ia = ibitor(1,i)
         ib = ibitor(2,i)
         ic = ibitor(3,i)
         id = ibitor(4,i)
         ie = ibitor(5,i)
         ita = class(ia)
         itb = class(ib)
         itc = class(ic)
         itd = class(id)
         ite = class(ie)
         size = 4
         call numeral (ita,pa,size)
         call numeral (itb,pb,size)
         call numeral (itc,pc,size)
         call numeral (itd,pd,size)
         call numeral (ite,pe,size)
         pt1 = pa//pb//pc//pd//pe
         pt2 = pe//pd//pc//pb//pa
c
c     find parameters for this torsion-torsion interaction
c
         do j = 1, ntt
            if (ktt(j) .eq. pt1) then
               ntortor = ntortor + 1
               itt(1,ntortor) = i
               itt(2,ntortor) = j
               itt(3,ntortor) = 1
               goto 60
            else if (ktt(j) .eq. pt2) then
               ntortor = ntortor + 1
               itt(1,ntortor) = i
               itt(2,ntortor) = j
               itt(3,ntortor) = -1
               goto 60
            end if
         end do
   60    continue
      end do
c
c     turn off the torsion-torsion potential if it is not used
c
      if (ntortor .eq. 0)  use_tortor = .false.
      return
      end
