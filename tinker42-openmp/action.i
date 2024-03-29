 
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
c     ##  action.i  --  total number of each energy term computed  ##
c     ##                                                           ##
c     ###############################################################
c
c
c     neb     number of bond stretch energy terms computed
c     nea     number of angle bend energy terms computed
c     neba    number of stretch-bend energy terms computed
c     neub    number of Urey-Bradley energy terms computed
c     neaa    number of angle-angle energy terms computed
c     neopb   number of out-of-plane bend energy terms computed
c     neopd   number of out-of-plane distance energy terms computed
c     neid    number of improper dihedral energy terms computed
c     neit    number of improper torsion energy terms computed
c     net     number of torsional energy terms computed
c     nept    number of pi-orbital torsion energy terms computed
c     nebt    number of stretch-torsion energy terms computed
c     nett    number of torsion-torsion energy terms computed
c     nev     number of van der Waals energy terms computed
c     nec     number of charge-charge energy terms computed
c     necd    number of charge-dipole energy terms computed
c     ned     number of dipole-dipole energy terms computed
c     nem     number of multipole energy terms computed
c     nep     number of polarization energy terms computed
c     new     number of Ewald summation energy terms computed
c     ner     number of reaction field energy terms computed
c     nes     number of solvation energy terms computed
c     nelf    number of metal ligand field energy terms computed
c     neg     number of geometric restraint energy terms computed
c     nex     number of extra energy terms computed
c
c
      integer neb,nea,neba,neub
      integer neaa,neopb,neopd
      integer neid,neit,net,nept
      integer nebt,nett,nev,nec
      integer necd,ned,nem,nep,new
      integer ner,nes,nelf,neg,nex
      common /action/ neb,nea,neba,neub,neaa,neopb,neopd,neid,neit,
     &                net,nept,nebt,nett,nev,nec,necd,ned,nem,nep,new,
     &                ner,nes,nelf,neg,nex
