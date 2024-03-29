 
C     $Id$
c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1990  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     ###########################################################
c     ##                                                       ##
c     ##  subroutine attach  --  setup of connectivity arrays  ##
c     ##                                                       ##
c     ###########################################################
c
c
c     "attach" generates lists of 1-3, 1-4 and 1-5 connectivities
c     starting from the previously determined list of attached
c     atoms (ie, 1-2 connectivity)
c
c
      subroutine attach
      implicit none
      include 'sizes.i'
      include 'atoms.i'
      include 'couple.i'
      include 'iounit.i'
      integer i,j,k,m
      integer jj,kk
c
c
c     loop over all atoms finding all the 1-3 relationships;
c     note "n12" and "i12" have already been setup elsewhere
c
      do i = 1, n
         n13(i) = 0
         do j = 1, n12(i)
            jj = i12(j,i)
            do k = 1, n12(jj)
               kk = i12(k,jj)
               if (kk .eq. i)  goto 10
               do m = 1, n12(i)
                  if (kk .eq. i12(m,i))  goto 10
               end do
               n13(i) = n13(i) + 1
               i13(n13(i),i) = kk
   10          continue
            end do
         end do
         if (n13(i) .gt. maxn13) then
            write (iout,20)  i
   20       format (/,' ATTACH  --  Too many 1-3 Connected Atoms',
     &                 ' Attached to Atom',i6)
            call fatal
         end if
         call sort (n13(i),i13(1,i))
      end do
c
c     loop over all atoms finding all the 1-4 relationships
c
      do i = 1, n
         n14(i) = 0
         do j = 1, n13(i)
            jj = i13(j,i)
            do k = 1, n12(jj)
               kk = i12(k,jj)
               if (kk .eq. i)  goto 30
               do m = 1, n12(i)
                  if (kk .eq. i12(m,i))  goto 30
               end do
               do m = 1, n13(i)
                  if (kk .eq. i13(m,i))  goto 30
               end do
               n14(i) = n14(i) + 1
               i14(n14(i),i) = kk
   30          continue
            end do
         end do
         if (n14(i) .gt. maxn14) then
            write (iout,40)  i
   40       format (/,' ATTACH  --  Too many 1-4 Connected Atoms',
     &                 ' Attached to Atom',i6)
            call fatal
         end if
         call sort (n14(i),i14(1,i))
      end do
c
c     loop over all atoms finding all the 1-5 relationships
c
      do i = 1, n
         n15(i) = 0
         do j = 1, n14(i)
            jj = i14(j,i)
            do k = 1, n12(jj)
               kk = i12(k,jj)
               if (kk .eq. i)  goto 50
               do m = 1, n12(i)
                  if (kk .eq. i12(m,i))  goto 50
               end do
               do m = 1, n13(i)
                  if (kk .eq. i13(m,i))  goto 50
               end do
               do m = 1, n14(i)
                  if (kk .eq. i14(m,i))  goto 50
               end do
               n15(i) = n15(i) + 1
               i15(n15(i),i) = kk
   50          continue
            end do
         end do
         if (n15(i) .gt. maxn15) then
            write (iout,60)  i
   60       format (/,' ATTACH  --  Too many 1-5 Connected Atoms',
     &                 ' Attached to Atom',i6)
            call fatal
         end if
         call sort (n15(i),i15(1,i))
      end do
      return
      end
