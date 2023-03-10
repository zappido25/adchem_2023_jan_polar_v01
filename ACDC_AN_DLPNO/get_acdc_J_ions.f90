subroutine get_acdc_J(c_acid,c_base,c_org,cs_ref,temp,ipr,t_sim,solve_ss,j_acdc,diameter_acdc, Nuc_by_charge,c)
use acdc_system, only : nclust, neq					! number of clusters and equations
use acdc_system, only : cluster_names				! names of the clusters and fluxes
use acdc_system, only : n1A							! cluster numbers of acid and base monomers
!use acdc_system, only : n1base => n1N
!use acdc_system, only : n1B, n1N1P
!use acdc_system, only : nneg, npos					! cluster numbers of charger ions
use acdc_system, only : nmols_out_neutral, nmolA	! criteria for "nucleation"
use acdc_system, only : diameter_max				! max. mass diameter (nm)
use driver, only : acdc_driver						! driver


	implicit none

	! Input: ambient conditions and simulation time
	real(kind(1.d0)), intent(inout) :: c_acid, c_base, c_org	! vapor concentrations (1/m^3)
	real(kind(1.d0)), intent(in) :: cs_ref				! reference coagulation sink (1/s)
	real(kind(1.d0)), intent(in) :: temp				! temperature (K)
	real(kind(1.d0)), intent(in) :: ipr					! ion production rate (1/s/m^3)
	real(kind(1.d0)), intent(in) :: t_sim				! simulation time (s)
	logical, intent(in) :: solve_ss						! solve the steady state or run only for the given time
	! Output: formed particles/time and their acid content
	real(kind(1.d0)), intent(out) :: j_acdc				! simulated formation rate (1/s/m^3)
  	real(kind(1.d0)), intent(out) :: Nuc_by_charge(3)
	real(kind(1.d0)), intent(out) :: diameter_acdc		! mass diameter of the formed particles (m)
	!real(kind(1.d0)), intent(out) :: nacid_acdc		! number of acid molecules at the "formation size"
														! NB: nacid_acdc is type real (dp), as it is like this in UHMA

	!real(kind(1.d0)), save :: c(neq)					! cluster concentrations
	real(kind(1.d0)), intent(inout) :: c(neq) 
	character(len=11), dimension(neq) :: c_names		! cluster and flux names
	integer, save :: n1base = 0, n1org = 0				! cluster numbers of base and organic molecules
	integer, save :: nacid_out							! smallest number of acid molecules in the outgrown clusters
	real(kind(1.d0)) :: j_out(3) 		! formation rate vector (for neu, neg and pos)
	real(kind(1.d0)) :: t_in							! input time for the driver (s)
	logical :: use_solver = .true.						! use the solver or the simple Euler method
	logical :: int_ok = .true.							! .false. if integration fails
	real(kind(1.d0)), save :: t_iter = 1.d-10			! iteration time step (s) for the Euler method
	integer, save :: ipar(4)							! parameters for re-calling the monomer settings and rate constants
	logical, save :: firstcall = .true.
	integer :: n

	! Initialize the rate constants etc. at every call
	! because of the varying ambient conditions
	ipar(1:3) = 0

	if (firstcall) then
		firstcall = .false.
		! Initialize the concentrations
		c = 0.d0
		! See which compounds there are
		call cluster_names(c_names)
		do n = 1, nclust
			if ((trim(c_names(n)(:)).eq.'1N') .or. (trim(c_names(n)(:)).eq.'1D')) then
				if (n1base .ne. 0) then
					write (*,*) 'Found more than one base molecule'
					stop
				end if
				n1base = n
			else if (trim(c_names(n)(:)) .eq. '1O') then
				n1org = n
			end if
		end do
		! Get the acid content of the outgrown clusters
		! (use the smallest number of acids)
		!nacid_out = minval(nmols_out_neutral(1:size(nmols_out_neutral,1),nmolA))
	end if

	if (solve_ss) then
		! Override the input time with a maximum time that
		! the driver is allowed to try to get to the steady state
		t_in = 5.d6
	else
		t_in = t_sim
	end if

	! Set the vapor concentrations
	c(n1A) = c_acid
	c(n1base) = c_base
	if (n1org .ne. 0) then
		c(n1org) = c_org
	end if

	! Run ACDC to the steady state / for the given time
	call acdc_driver(c,cs_ref,temp,ipr,t_in,t_iter,solve_ss,use_solver,ipar,int_ok,j_out)
	j_acdc = sum(j_out)
  Nuc_by_charge = j_out
!  write(*,*) 'Neutral, neg. and pos. J: ',j_out*1.d-6,' cm^-3 s^-1'
	if (j_acdc .lt. 0.d0) then
		if (j_acdc .lt. -1.d-12 .and. int_ok) then
			write(*,*) 'Warning: negative J = ',j_acdc*1.d-6,' cm^-3 s^-1, something wrong?'
		end if
		j_acdc = 0.d0
	end if
	! The first outgrown size is ~equal to the largest simulated size
	diameter_acdc = diameter_max*1.d-9

	!nacid_acdc = real(nacid_out,kind=kind(1.d0))


end subroutine get_acdc_J
