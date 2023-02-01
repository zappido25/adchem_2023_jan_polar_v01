! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
! 
! Initialization File
! 
! Generated by KPP-2.2.3 symbolic chemistry Kinetics PreProcessor
!       (http://www.cs.vt.edu/~asandu/Software/KPP)
! KPP is distributed under GPL, the general public licence
!       (http://www.gnu.org/copyleft/gpl.html)
! (C) 1995-1997, V. Damian & A. Sandu, CGRER, Univ. Iowa
! (C) 1997-2005, A. Sandu, Michigan Tech, Virginia Tech
!     With important contributions from:
!        M. Damian, Villanova University, USA
!        R. Sander, Max-Planck Institute for Chemistry, Mainz, Germany
! 
! File                 : second_Initialize.f90
! Time                 : Tue Nov 15 23:16:20 2022
! Working directory    : /Users/roldin/mcm_kpp/mcm_PRAMv1_DMS_I2O5
! Equation file        : second.kpp
! Output root filename : second
! 
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



MODULE second_Initialize

  USE second_Parameters, ONLY: dp, NVAR, NFIX
  IMPLICIT NONE

CONTAINS


! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
! 
! Initialize - function to initialize concentrations
!   Arguments :
! 
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SUBROUTINE Initialize ( )


  USE second_Global

  INTEGER :: i
  REAL(kind=dp) :: x

  CFACTOR = 1.000000e+00_dp

  x = (0.)*CFACTOR
  DO i = 1, NVAR
    VAR(i) = x
  END DO

  x = (0.)*CFACTOR
  DO i = 1, NFIX
    FIX(i) = x
  END DO

! constant rate coefficients
  RCONST(45) = 0
  RCONST(7447) = 9.258e-11
  RCONST(9223) = 1.867e-11
  RCONST(9224) = 1.513e-11
  RCONST(9226) = 1.865e-11
! END constant rate coefficients

! INLINED initializations

! End INLINED initializations

      
END SUBROUTINE Initialize

! End of Initialize function
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



END MODULE second_Initialize

