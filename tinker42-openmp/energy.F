 
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
c     ##  function energy  --  evaluates energy terms and total  ##
c     ##                                                         ##
c     #############################################################
c
c
c     "energy" calls the subroutines to calculate the potential
c     energy terms and sums up to form the total energy
c
c
      function energy ()
      implicit none
      include 'sizes.i'
      include 'bound.i'
      include 'energi.i'
      include 'potent.i'
      include 'rigid.i'
      include 'vdwpot.i'
      real*8 energy
      real*8 cutoff
c
c
c     zero out each of the potential energy components
c
      eb = 0.0d0
      ea = 0.0d0
      eba = 0.0d0
      eub = 0.0d0
      eaa = 0.0d0
      eopb = 0.0d0
      eopd = 0.0d0
      eid = 0.0d0
      eit = 0.0d0
      et = 0.0d0
      ept = 0.0d0
      ebt = 0.0d0
      ett = 0.0d0
      ev = 0.0d0
      ec = 0.0d0
      ecd = 0.0d0
      ed = 0.0d0
      em = 0.0d0
      ep = 0.0d0
      er = 0.0d0
      es = 0.0d0
      elf = 0.0d0
      eg = 0.0d0
      ex = 0.0d0
c
c     maintain any periodic boundary conditions
c
      if (use_bounds .and. .not.use_rigid)  call bounds
c
c     remove any previous use of the replicates method
c
      cutoff = 0.0d0
      if (use_image)  call replica (cutoff)
c
c     alter bond and torsion constants for pisystem
c
      if (use_orbit)  call piscf
c
c     call the local geometry energy component routines
c
      if (use_bond)  call ebond
      if (use_angle)  call eangle
      if (use_strbnd)  call estrbnd
      if (use_urey)  call eurey
      if (use_angang)  call eangang
      if (use_opbend)  call eopbend
      if (use_opdist)  call eopdist
      if (use_improp)  call eimprop
      if (use_imptor)  call eimptor
      if (use_tors)  call etors
      if (use_pitors)  call epitors
      if (use_strtor)  call estrtor
      if (use_tortor)  call etortor
c
c     call the van der Waals energy component routines
c
      if (use_vdw) then
         if (vdwtyp .eq. 'LENNARD-JONES')  call elj
         if (vdwtyp .eq. 'BUCKINGHAM')  call ebuck
         if (vdwtyp .eq. 'MM3-HBOND')  call emm3hb
         if (vdwtyp .eq. 'BUFFERED-14-7')  call ehal
         if (vdwtyp .eq. 'GAUSSIAN')  call egauss
      end if
c
c     call the electrostatic energy component routines
c
      if (use_charge)  call echarge
      if (use_chgdpl)  call echgdpl
      if (use_dipole)  call edipole
      if (use_mpole .or. use_polar)  call empole
      if (use_rxnfld)  call erxnfld
c
c     call any miscellaneous energy component routines
c
      if (use_solv)  call esolv
      if (use_geom)  call egeom
      if (use_metal)  call emetal
      if (use_extra)  call extra
c
c     sum up to give the total potential energy
c
      esum = eb + ea + eba + eub + eaa + eopb + eopd + eid + eit
     &          + et + ept + ebt + ett + ev + ec + ecd + ed + em
     &          + ep + er + es + elf + eg + ex
      energy = esum
      return
      end
