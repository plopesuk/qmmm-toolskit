 
C     $Id$
c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1992  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     ###############################################################
c     ##                                                           ##
c     ##  kbonds.i  --  forcefield parameters for bond stretching  ##
c     ##                                                           ##
c     ###############################################################
c
c
c     maxnb   maximum number of bond stretch parameter entries
c     maxnb5  maximum number of 5-membered ring bond stretch entries
c     maxnb4  maximum number of 4-membered ring bond stretch entries
c     maxnb3  maximum number of 3-membered ring bond stretch entries
c     maxnel  maximum number of electronegativity bond corrections
c
c     bcon    force constant parameters for harmonic bond stretch
c     bcon5   force constant parameters for 5-ring bond stretch
c     bcon4   force constant parameters for 4-ring bond stretch
c     bcon3   force constant parameters for 3-ring bond stretch
c     blen    bond length parameters for harmonic bond stretch
c     blen5   bond length parameters for 5-ring bond stretch
c     blen4   bond length parameters for 4-ring bond stretch
c     blen3   bond length parameters for 3-ring bond stretch
c     dlen    electronegativity bond length correction parameters
c     kb      string of atom classes for harmonic bond stretch
c     kb5     string of atom classes for 5-ring bond stretch
c     kb4     string of atom classes for 4-ring bond stretch
c     kb3     string of atom classes for 3-ring bond stretch
c     kel     string of atom classes for electronegativity corrections
c
c
      integer maxnb,maxnb5,maxnb4
      integer maxnb3,maxnel
      parameter (maxnb=500)
      parameter (maxnb5=100)
      parameter (maxnb4=100)
      parameter (maxnb3=100)
      parameter (maxnel=500)
      real*8 bcon,bcon5,bcon4,bcon3
      real*8 blen,blen5,blen4,blen3,dlen
      character*8 kb,kb5,kb4,kb3
      character*12 kel
      common /kbonds/ bcon(maxnb),bcon5(maxnb5),bcon4(maxnb4),
     &                bcon3(maxnb3),blen(maxnb),blen5(maxnb5),
     &                blen4(maxnb4),blen3(maxnb3),dlen(maxnel),
     &                kb(maxnb),kb5(maxnb5),kb4(maxnb4),kb3(maxnb3),
     &                kel(maxnel)
