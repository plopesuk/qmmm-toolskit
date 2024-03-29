 
C     $Id$
c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1992  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     ###########################################################
c     ##                                                       ##
c     ##  subroutine getpdb  --  get a Protein Data Bank file  ##
c     ##                                                       ##
c     ###########################################################
c
c
c     "getpdb" asks for a Protein Data Bank file name,
c     then reads in the coordinates file
c
c
      subroutine getpdb
      implicit none
      include 'iounit.i'
      integer ipdb
      integer freeunit
      logical exist
      character*120 pdbfile
c
c
c     try to get a filename from the command line arguments
c
      call nextarg (pdbfile,exist)
      if (exist) then
         call basefile (pdbfile)
         call suffix (pdbfile,'pdb')
         call version (pdbfile,'old')
         inquire (file=pdbfile,exist=exist)
      end if
c
c     ask for the user specified input structure filename
c
      dowhile (.not. exist)
         write (iout,10)
   10    format (/,' Enter Protein Data Bank File Name :  ',$)
         read (input,20)  pdbfile
   20    format (a120)
         call basefile (pdbfile)
         call suffix (pdbfile,'pdb')
         call version (pdbfile,'old')
         inquire (file=pdbfile,exist=exist)
      end do
c
c     first open and then read the PDB coordinates file
c
      ipdb = freeunit ()
      open (unit=ipdb,file=pdbfile,status='old')
      rewind (unit=ipdb)
      call readpdb (ipdb)
      close (unit=ipdb)
      return
      end
