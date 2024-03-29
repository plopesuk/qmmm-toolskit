 
C     $Id$
c
c
c     ############################################################
c     ##  COPYRIGHT (C) 1996 by Yong Kong & Jay William Ponder  ##
c     ##                  All Rights Reserved                   ##
c     ############################################################
c
c     #################################################################
c     ##                                                             ##
c     ##  subroutine erxnfld3  --  reaction field energy & analysis  ##
c     ##                                                             ##
c     #################################################################
c
c
c     "erxnfld3" calculates the macroscopic reaction field energy,
c     and also partitions the energy among the atoms
c
c     literature reference:
c
c     Y. Kong and J. W. Ponder, "Reaction Field Methods for Off-Center
c     Multipoles", Journal of Chemical Physics, 107, 481-492 (1997)
c
c
      subroutine erxnfld3
      implicit none
      include 'sizes.i'
      include 'action.i'
      include 'analyz.i'
      include 'atmtyp.i'
      include 'atoms.i'
      include 'chgpot.i'
      include 'energi.i'
      include 'inform.i'
      include 'iounit.i'
      include 'mpole.i'
      include 'shunt.i'
      include 'usage.i'
      integer i,j,k
      integer ii,iz,ix
      integer kk,kz,kx
      real*8 eik,r2
      real*8 xr,yr,zr
      real*8 r,di,dk
      real*8 rpi(13)
      real*8 rpk(13)
      logical iuse,kuse
      logical header,huge
c
c
c     zero out the reaction field energy and partitioning
c
      ner = 0
      er = 0.0d0
      do i = 1, n
         aer(i) = 0.0d0
      end do
      header = .true.
c
c     set the switching function coefficients
c
      call switch ('MPOLE')
c
c     check the sign of multipole components at chiral sites
c
      call chkpole
c
c     rotate the multipole components into the global frame
c
      call rotpole
c
c     compute the indices used in reaction field calculations
c
      call ijkpts
c
c     calculate the reaction field interaction energy term
c
      do ii = 1, npole
         i = ipole(ii)
         iz = zaxis(ii)
         ix = xaxis(ii)
         iuse = (use(i) .or. use(iz) .or. use(ix))
         do j = 1, polsiz(ii)
            rpi(j) = rpole(j,ii)
         end do
         do kk = ii, npole
            k = ipole(kk)
            kz = zaxis(kk)
            kx = xaxis(kk)
            kuse = (use(k) .or. use(kz) .or. use(kx))
            if (iuse .or. kuse) then
               xr = x(k) - x(i)
               yr = y(k) - y(i)
               zr = z(k) - z(i)
               r2 = xr*xr + yr*yr + zr*zr
               if (r2 .le. off2) then
                  do j = 1, polsiz(kk)
                     rpk(j) = rpole(j,kk)
                  end do
                  call erfik (ii,kk,i,k,rpi,rpk,eik)
                  ner = ner + 1
                  er = er + eik
                  aer(i) = aer(i) + 0.5d0*eik
                  aer(k) = aer(k) + 0.5d0*eik
c
c     print a message if the energy of this interaction is large
c
                  huge = (eik .gt. 10.0d0)
                  if (debug .or. (verbose.and.huge)) then
                     if (header) then
                        header = .false.
                        write (iout,10)
   10                   format (/,' Individual Reaction Field',
     &                             ' Interactions :',
     &                          //,' Type',13x,'Atom Names',
     &                             9x,'Dist from Origin',4x,'R(1-2)',
     &                             6x,'Energy',/)
                     end if
                     r = sqrt(r2)
                     di = sqrt(x(i)**2 + y(i)**2 + z(i)**2)
                     dk = sqrt(x(k)**2 + y(k)**2 + z(k)**2)
                     write (iout,20)  i,name(i),k,name(k),di,dk,r,eik
   20                format (' RxnFld',5x,i5,'-',a3,1x,i5,'-',a3,
     &                          2x,3f10.4,f12.4)
                  end if
               end if
            end if
         end do
      end do
      return
      end
