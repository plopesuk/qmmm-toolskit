 
C     $Id$
c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1993  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     #############################################################
c     ##                                                         ##
c     ##  subroutine esolv2  --  atom-by-atom solvation Hessian  ##
c     ##                                                         ##
c     #############################################################
c
c
c     "esolv2" calculates second derivatives of the continuum
c     solvation energy using either the Eisenberg-McLachlan ASP,
c     Ooi-Scheraga SASA or various GB/SA solvation models
c
c     note this version does not contain the chain rule terms
c     for derivatives of Born radii with respect to coordinates
c
c
      subroutine esolv2 (i)
      implicit none
      include 'sizes.i'
      include 'potent.i'
      include 'solute.i'
      include 'warp.i'
      integer i
      real*8 probe
c     real*8 aes(maxatm)
c     real*8 des(3,maxatm)
c
c
c     set a value for the solvent molecule probe radius
c
      probe = 1.4d0
c
c     compute the surface area-based solvation energy term
c
c     call surface (es,aes,des,rsolv,asolv,probe)
c
c     get the generalized Born term for GB/SA solvation
c
      if (use_gbsa) then
         if (use_smooth) then
            call egbsa2b (i)
         else
            call egbsa2a (i)
         end if
      end if
      return
      end
c
c
c     ################################################################
c     ##                                                            ##
c     ##  subroutine egbsa2a  --  atomwise GB/SA solvation Hessian  ##
c     ##                                                            ##
c     ################################################################
c
c
c     "egbsa2a" calculates second derivatives of the generalized
c     Born energy term for the GB/SA solvation models
c
c
      subroutine egbsa2a (i)
      implicit none
      include 'sizes.i'
      include 'atoms.i'
      include 'charge.i'
      include 'hessn.i'
      include 'shunt.i'
      include 'solute.i'
      include 'units.i'
      integer i,j,k,kk
      real*8 e,de,d2e
      real*8 fi,fik
      real*8 xi,yi,zi
      real*8 xr,yr,zr
      real*8 r,r2,r3,r4
      real*8 r5,r6,r7
      real*8 dwater,rb2,rm2
      real*8 expterm,shift
      real*8 d2edx,d2edy,d2edz
      real*8 taper,dtaper,d2taper
      real*8 trans,dtrans,d2trans
      real*8 fgb,fgb2,dfgb
      real*8 dfgb2,d2fgb
      real*8 term(3,3)
c
c
c     first see if the atom of interest carries a charge
c
      do k = 1, nion
         if (iion(k) .eq. i) then
            fi = pchg(k)
            goto 10
         end if
      end do
      return
   10 continue
c
c     store the coordinates of the atom of interest
c
      xi = x(i)
      yi = y(i)
      zi = z(i)
c
c     set the solvent dielectric and energy conversion factor
c
      dwater = 78.3d0
      fi = -electric * (1.0d0 - 1.0d0/dwater) * fi
c
c     set cutoff distances and switching function coefficients
c
      call switch ('CHARGE')
c
c     calculate GB/SA polarization energy Hessian elements
c
      do kk = 1, nion
         k = iion(kk)
         if (i .ne. k) then
            xr = xi - x(k)
            yr = yi - y(k)
            zr = zi - z(k)
            r2 = xr*xr + yr*yr + zr*zr
            if (r2 .le. off2) then
               r = sqrt(r2)
               fik = fi * pchg(kk)
c
c     compute chain rule terms for Hessian matrix elements
c
               rb2 = rborn(i) * rborn(k)
               expterm = exp(-0.25d0*r2/rb2)
               fgb2 = r2 + rb2*expterm
               fgb = sqrt(fgb2)
               dfgb = (1.0d0-0.25d0*expterm) * r / fgb
               dfgb2 = dfgb * dfgb
               d2fgb = -dfgb2/fgb + dfgb/r
     &                    + 0.125d0*(r2/rb2)*expterm/fgb
               de = -fik * dfgb / fgb2
               d2e = -fik * (d2fgb-2.0d0*dfgb2/fgb) / fgb2
c
c     use energy switching if near the cutoff distance
c
               if (r2 .gt. cut2) then
                  e = fik / fgb
                  rm2 = (0.5d0 * (off+cut))**2
                  shift = fik / sqrt(rm2 + rb2*exp(-0.25d0*rm2/rb2))
                  e = e - shift
                  r3 = r2 * r
                  r4 = r2 * r2
                  r5 = r2 * r3
                  r6 = r3 * r3
                  r7 = r3 * r4
                  taper = c5*r5 + c4*r4 + c3*r3 + c2*r2 + c1*r + c0
                  dtaper = 5.0d0*c5*r4 + 4.0d0*c4*r3
     &                        + 3.0d0*c3*r2 + 2.0d0*c2*r + c1
                  d2taper = 20.0d0*c5*r3 + 12.0d0*c4*r2
     &                         + 6.0d0*c3*r + 2.0d0*c2
                  trans = fik * (f7*r7 + f6*r6 + f5*r5 + f4*r4
     &                            + f3*r3 + f2*r2 + f1*r + f0)
                  dtrans = fik * (7.0d0*f7*r6 + 6.0d0*f6*r5
     &                            + 5.0d0*f5*r4 + 4.0d0*f4*r3
     &                            + 3.0d0*f3*r2 + 2.0d0*f2*r + f1)
                  d2trans = fik * (42.0d0*f7*r5 + 30.0d0*f6*r4
     &                             + 20.0d0*f5*r3 + 12.0d0*f4*r2
     &                             + 6.0d0*f3*r + 2.0d0*f2)
                  d2e = e*d2taper + 2.0d0*de*dtaper
     &                     + d2e*taper + d2trans
                  de = e*dtaper + de*taper + dtrans
               end if
c
c     form the individual Hessian element components
c
               de = de / r
               d2e = (d2e-de) / r2
               d2edx = d2e * xr
               d2edy = d2e * yr
               d2edz = d2e * zr
               term(1,1) = d2edx*xr + de
               term(1,2) = d2edx*yr
               term(1,3) = d2edx*zr
               term(2,1) = term(1,2)
               term(2,2) = d2edy*yr + de
               term(2,3) = d2edy*zr
               term(3,1) = term(1,3)
               term(3,2) = term(2,3)
               term(3,3) = d2edz*zr + de
c
c     increment diagonal and non-diagonal Hessian elements
c
               do j = 1, 3
                  hessx(j,i) = hessx(j,i) + term(1,j)
                  hessy(j,i) = hessy(j,i) + term(2,j)
                  hessz(j,i) = hessz(j,i) + term(3,j)
                  hessx(j,k) = hessx(j,k) - term(1,j)
                  hessy(j,k) = hessy(j,k) - term(2,j)
                  hessz(j,k) = hessz(j,k) - term(3,j)
               end do
            end if
         end if
      end do
      return
      end
c
c
c     #################################################################
c     ##                                                             ##
c     ##  subroutine egbsa2b  --  smoothing GB/SA solvation Hessian  ##
c     ##                                                             ##
c     #################################################################
c
c
c     "egbsa2b" calculates second derivatives of the generalized
c     Born energy term for the GB/SA solvation models for use with
c     potential smoothing methods
c
c
      subroutine egbsa2b (i)
      implicit none
      include 'sizes.i'
      include 'atoms.i'
      include 'charge.i'
      include 'hessn.i'
      include 'math.i'
      include 'solute.i'
      include 'units.i'
      include 'warp.i'
      integer i,j,k,kk
      real*8 fi,fik,de,d2e
      real*8 xi,yi,zi
      real*8 xr,yr,zr
      real*8 dwater,width
      real*8 r,r2,rb2
      real*8 fgb,fgb2
      real*8 dfgb,dfgb2,d2fgb
      real*8 d2edx,d2edy,d2edz
      real*8 sterm,expterm
      real*8 erf,erfterm
      real*8 term(3,3)
      external erf
c
c
c     first see if the atom of interest carries a charge
c
      do k = 1, nion
         if (iion(k) .eq. i) then
            fi = pchg(k)
            goto 10
         end if
      end do
      return
   10 continue
c
c     store the coordinates of the atom of interest
c
      xi = x(i)
      yi = y(i)
      zi = z(i)
c
c     set the solvent dielectric and energy conversion factor
c
      dwater = 78.3d0
      fi = -electric * (1.0d0 - 1.0d0/dwater) * fi
c
c     set the extent of smoothing to be performed
c
      sterm = 0.5d0 / sqrt(diffc)
c
c     calculate GB/SA polarization energy Hessian elements
c
      do kk = 1, nion
         k = iion(kk)
         if (i .ne. k) then
            xr = xi - x(k)
            yr = yi - y(k)
            zr = zi - z(k)
            r2 = xr*xr + yr*yr + zr*zr
            r = sqrt(r2)
            fik = fi * pchg(kk)
c
c     compute chain rule terms for Hessian matrix elements
c
            rb2 = rborn(i) * rborn(k)
            expterm = exp(-0.25d0*r2/rb2)
            fgb2 = r2 + rb2*expterm
            fgb = sqrt(fgb2)
            dfgb = (1.0d0-0.25d0*expterm) * r / fgb
            dfgb2 = dfgb * dfgb
            d2fgb = -dfgb2/fgb + dfgb/r
     &                 + 0.125d0*(r2/rb2)*expterm/fgb
            de = -fik * dfgb / fgb2
            d2e = -fik * (d2fgb-2.0d0*dfgb2/fgb) / fgb2
c
c     use a smoothable GB/SA analogous to the Coulomb solution
c
            if (deform .gt. 0.0d0) then
               width = deform + 0.15d0*rb2*exp(-0.006d0*rb2/deform)
               width = sterm / sqrt(width)
               erfterm = erf(width*fgb)
               expterm = width * exp(-(width*fgb)**2) / sqrtpi
               de = de * (erfterm-2.0d0*expterm*fgb)
               d2e = d2e*erfterm + 2.0d0*fik*expterm
     &                  * (d2fgb/fgb-2.0d0*dfgb2*(1.0d0/fgb2+width**2))
            end if
c
c     form the individual Hessian element components
c
            de = de / r
            d2e = (d2e-de) / r2
            d2edx = d2e * xr
            d2edy = d2e * yr
            d2edz = d2e * zr
            term(1,1) = d2edx*xr + de
            term(1,2) = d2edx*yr
            term(1,3) = d2edx*zr
            term(2,1) = term(1,2)
            term(2,2) = d2edy*yr + de
            term(2,3) = d2edy*zr
            term(3,1) = term(1,3)
            term(3,2) = term(2,3)
            term(3,3) = d2edz*zr + de
c
c     increment diagonal and non-diagonal Hessian elements
c
            do j = 1, 3
               hessx(j,i) = hessx(j,i) + term(1,j)
               hessy(j,i) = hessy(j,i) + term(2,j)
               hessz(j,i) = hessz(j,i) + term(3,j)
               hessx(j,k) = hessx(j,k) - term(1,j)
               hessy(j,k) = hessy(j,k) - term(2,j)
               hessz(j,k) = hessz(j,k) - term(3,j)
            end do
         end if
      end do
      return
      end
