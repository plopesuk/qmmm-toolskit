 
C     $Id$
c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1990  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     ################################################################
c     ##                                                            ##
c     ##  subroutine numgrad  --  numerical gradient of a function  ##
c     ##                                                            ##
c     ################################################################
c
c
c     "numgrad" computes the gradient of the objective function
c     "fvalue" with respect to Cartesian coordinates of the atoms
c     via a two-sided numerical differentiation
c
c
      subroutine numgrad (fvalue,g,eps)
      implicit none
      include 'sizes.i'
      include 'atoms.i'
      integer i
      real*8 fvalue,eps
      real*8 f,f0,old
      real*8 g(3,maxatm)
      external fvalue
c
c
c     compute two-sided numerical gradient from function values
c
      do i = 1, n
         old = x(i)
         x(i) = x(i) - 0.5d0*eps
         f0 = fvalue ()
         x(i) = x(i) + eps
         f = fvalue ()
         x(i) = old
         g(1,i) = (f - f0) / eps
         old = y(i)
         y(i) = y(i) - 0.5d0*eps
         f0 = fvalue ()
         y(i) = y(i) + eps
         f = fvalue ()
         y(i) = old
         g(2,i) = (f - f0) / eps
         old = z(i)
         z(i) = z(i) - 0.5d0*eps
         f0 = fvalue ()
         z(i) = z(i) + eps
         f = fvalue ()
         z(i) = old
         g(3,i) = (f - f0) / eps
      end do
      return
      end
