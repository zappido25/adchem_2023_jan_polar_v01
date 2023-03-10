module ClusterIn_plugin

USE second_Precision,  ONLY : dp    ! KPP Numerical type
USE acdc_datatypes
include 'cluster_chem_use.inc'

implicit none
PRIVATE
public:: clustering_subroutine

contains

Subroutine clustering_subroutine(chem_1, chem_2, clust_firstcall, n_clustering_vapors, nr_bins, cH2SO4, cDMA, cNH3, Jnucl_N_out, Jnucl_D_out, &
     dia_n, dia_dma, CS_H2SO4,T,press, ipr,dt, d, d_p, m_p, N_bins_in, Mx, qX,n_evap, comp_evap, clustering_systems, c_clusters1, c_clusters2, layer,l_cond_evap, l_coag_loss )
   
    IMPLICIT NONE

    type(clustering_mod), intent(inout) ::chem_1, chem_2
    REAL(DP) :: c_dma , C_ACID, C_BASE, sa_old, dm_old, am_old, nconc_evap1, nconc_evap2
    logical, intent(inout) :: clust_firstcall
    integer, intent(in) :: n_clustering_vapors, nr_bins, clustering_systems, layer
    REAL(DP), intent(inout) :: cH2SO4,cDMA, cNH3
    REAL(DP), intent(out) :: Jnucl_N_out, Jnucl_D_out,dia_n, dia_dma
    REAL(DP), intent(in) :: CS_H2SO4,T,press,ipr,dt, d_p(:),d(nr_bins+1), N_bins_in(:), m_p(nr_bins)
    REAL(dp), INTENT(in) :: MX(NSPEC_P),qX(NSPEC_P)
    REAL(DP), intent(in):: n_evap, comp_evap(:)
    REAL(dp), intent(inout) ::  c_clusters1(:),c_clusters2(:)
    integer:: i, kk    
    logical, intent(in):: l_cond_evap,l_coag_loss
    

    if (clust_firstcall) then


        chem_1%Nconc_evap=0D0
        chem_2%Nconc_evap=0D0
        
        
        ALLOCATE(chem_1%conc_coag_molec(nr_bins,n_clustering_vapors))
        ALLOCATE(chem_2%conc_coag_molec(nr_bins,n_clustering_vapors))
        
        ! do kk=1, clustering_systems
        !     if (kk .eq. 1) then
                
        call get_system_size_1(neq_syst=chem_1%neq_syst,nclust_syst=chem_1%nclust_syst,nclust_out=chem_1%nclust_out)
      
        allocate(chem_1%clust_molec(chem_1%nclust_syst, n_clustering_vapors))
        ALLOCATE(chem_1%conc_coag_clust(nr_bins, chem_1%nclust_syst))
        allocate(chem_1%c_p_clust(NSPEC_P, chem_1%nclust_syst))
        allocate(chem_1%v_clust(chem_1%nclust_syst))      
        ALLOCATE(chem_1%conc_out_all(chem_1%nclust_out))
        ALLOCATE(chem_1%clust_out_molec(chem_1%nclust_out,n_clustering_vapors))
        ALLOCATE(chem_1%comp_out_all(chem_1%nclust_out,n_clustering_vapors))
        ALLOCATE(chem_1%ind_out_bin(chem_1%nclust_out))

        chem_1%clust_molec=0D0
        chem_1%c_p_clust = 0.D0
        chem_1%v_clust = 0.D0
        chem_1%conc_coag_molec=0d0
        chem_1%clust_out_molec=0.
        chem_1%conc_out_all=0d0
        chem_1%comp_out_all=0d0
        chem_1%ind_out_bin=0d0
        
    ! else
        call get_system_size_2(neq_syst=chem_2%neq_syst,nclust_syst=chem_2%nclust_syst,nclust_out=chem_2%nclust_out)

        ALLOCATE(chem_2%conc_coag_clust(nr_bins,chem_2%nclust_syst))
        allocate(chem_2%clust_molec(chem_2%nclust_syst,n_clustering_vapors))
        allocate(chem_2%c_p_clust(NSPEC_P,chem_2%nclust_syst))
        allocate(chem_2%v_clust(chem_2%nclust_syst))
        ALLOCATE(chem_2%conc_out_all(chem_2%nclust_out))
        ALLOCATE(chem_2%clust_out_molec(chem_2%nclust_out,n_clustering_vapors))
        ALLOCATE(chem_2%comp_out_all(chem_2%nclust_out,n_clustering_vapors))
        ALLOCATE(chem_2%ind_out_bin(chem_2%nclust_out))
      

        chem_2%clust_molec=0D0
        chem_2%c_p_clust = 0.D0
        chem_2%v_clust = 0.D0
        chem_2%conc_coag_molec=0d0
        chem_2%clust_out_molec=0.
        chem_2%conc_out_all=0d0
        chem_2%comp_out_all=0d0
        chem_2%ind_out_bin=0d0
       
        
        allocate(chem_1%conc_out_bin(nr_bins))
        allocate(chem_2%conc_out_bin(nr_bins))
        allocate(chem_1%comp_out_bin(nr_bins,n_clustering_vapors))
        allocate(chem_2%comp_out_bin(nr_bins,n_clustering_vapors))
        
        clust_firstcall=.false.      
        write(*,*) 'nceq_syst', chem_1%neq_syst, '', chem_2%neq_syst
        write(*,*) 'nclust_syst', chem_1%nclust_syst, '', chem_2%nclust_syst
        write(*,*) 'nclust_out', chem_1%nclust_out, '', chem_2%nclust_out

    end if

    ! nconc_evap1=chem_1%Nconc_evap(layer)
    ! nconc_evap2=chem_2%Nconc_evap(layer)

    c_acid=cH2SO4*1D6 ! from molec/cm3  -> molec/m3 
    c_base=cNH3*1D6 
    c_DMA=cDMA*1D6

    cH2SO4 = cH2SO4 + comp_evap(1)
    cNH3   = cNH3 + comp_evap(4)
    cDMA   = cDMA + comp_evap(11)
 
    ! write(*,*) 'in clusterin module nconc_evap1 and 2' , nconc_evap1, nconc_evap2,layer
 
    if (n_evap > 0D0) then 
        ! write(*,*) 'goes in here'
        chem_1%nmols_evap(1) = comp_evap(1)*1.D6/n_evap ! H2SO4
        chem_1%nmols_evap(2) = comp_evap(4)*1.D6/n_evap ! NH3
        chem_2%nmols_evap(2) = comp_evap(11)*1.D6/n_evap ! NH3
        chem_2%nmols_evap(1)= chem_1%nmols_evap(1)
    end if

  !!!!!!!!! AN system !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 
    chem_1%conc_vapor=(/c_acid ,c_base/)

    if (l_cond_evap) then
       
        CALL cluster_dynamics_1(chem_1%names_vapor,chem_1%conc_vapor,CS_H2SO4,T,ipr,dt,0.d0,&
        &    Jnucl_N_out,dia_n,c_inout=c_clusters1,naero=nr_bins,dp_aero_lim=d ,mp_aero=m_p,c_aero=N_bins_in,dp_aero=d_p,pres=Press, &
        c_evap=n_evap,nmols_evap=chem_1%nmols_evap,&
        c_coag_molec=chem_1%conc_coag_molec,c_coag_clust=chem_1%conc_coag_clust,clust_molec=chem_1%clust_molec, &
        c_out_bin=chem_1%conc_out_bin,comp_out_bin=chem_1%comp_out_bin,&
        c_out_all=chem_1%conc_out_all,clust_out_molec=chem_1%clust_out_molec)

    elseif (l_coag_loss) then
        
        CALL cluster_dynamics_1(chem_1%names_vapor,chem_1%conc_vapor,CS_H2SO4,T,ipr,dt,0.d0,&
        &    Jnucl_N_out,dia_n,c_inout=c_clusters1, naero=nr_bins,dp_aero_lim=d ,dp_aero=d_p,mp_aero=m_p,c_aero=N_bins_in,pres=Press,&
        c_evap=n_evap,nmols_evap=chem_1%nmols_evap,&
        c_coag_clust=chem_1%conc_coag_clust,clust_molec=chem_1%clust_molec,&
        c_out_bin=chem_1%conc_out_bin,comp_out_bin=chem_1%comp_out_bin,&
        c_out_all=chem_1%conc_out_all,clust_out_molec=chem_1%clust_out_molec) 
        
    else
        write(*,*) 'No aerosol-cluster feedback selected'
    end if    
    
    
    cH2SO4=chem_1%conc_vapor(1)*1d-6
    cNH3=chem_1%conc_vapor(2)*1d-6
    
    !! update c_acid for AD system
    c_acid=cH2SO4*1D6 ! from molec/cm3  -> molec/m3 
    
    !!!!!!!!!!!!!!!!!!!! end AN system!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    !!!!!!!!!!!!!! AD system !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    chem_2%conc_vapor=(/c_acid ,c_dma/)
    
    
    if (l_cond_evap) then
       
        CALL cluster_dynamics_2(chem_2%names_vapor,chem_2%conc_vapor,CS_H2SO4,T,ipr,dt,0.d0,&
        &    Jnucl_D_out,dia_dma,c_inout=c_clusters2,naero=nr_bins,mp_aero=m_p,c_aero=N_bins_in,dp_aero_lim=d ,dp_aero=d_p,pres=Press, &
        c_evap=n_evap,nmols_evap=chem_2%nmols_evap, &
        c_coag_molec=chem_2%conc_coag_molec,c_coag_clust=chem_2%conc_coag_clust,clust_molec=chem_2%clust_molec,&
        c_out_bin=chem_2%conc_out_bin,comp_out_bin=chem_2%comp_out_bin,&
        c_out_all=chem_2%conc_out_all,clust_out_molec=chem_2%clust_out_molec)
        
    elseif (l_coag_loss) then
       
        CALL cluster_dynamics_2(chem_2%names_vapor,chem_2%conc_vapor,CS_H2SO4,T,ipr,dt,0.d0,&
        &    Jnucl_D_out,dia_dma,c_inout=c_clusters2,naero=nr_bins,mp_aero=m_p,c_aero=N_bins_in,dp_aero_lim=d ,dp_aero=d_p,pres=Press, &
        c_evap=n_evap,nmols_evap=chem_2%nmols_evap, &
        c_coag_molec=chem_2%conc_coag_molec,c_coag_clust=chem_2%conc_coag_clust,clust_molec=chem_2%clust_molec,&
        c_out_bin=chem_2%conc_out_bin,comp_out_bin=chem_2%comp_out_bin,&
        c_out_all=chem_2%conc_out_all,clust_out_molec=chem_2%clust_out_molec)
        
        !     CALL cluster_dynamics_2(chem_2%names_vapor,chem_2%conc_vapor,CS_H2SO4,T,ipr,dt,0.d0,&
        ! &    Jnucl_D_out,dia_dma,c_inout=c_clusters2,naero=nr_bins,mp_aero=m_p,c_aero=N_bins_in,dp_aero_lim=d ,dp_aero=d_p,pres=Press, &
        ! c_evap=n_evap,nmols_evap=chem_2%nmols_evap,&
        ! c_coag_clust=chem_2%conc_coag_clust,clust_molec=chem_2%clust_molec,&
        ! c_out_bin=chem_2%conc_out_bin,comp_out_bin=chem_2%comp_out_bin,&
        ! c_out_all=chem_2%conc_out_all,clust_out_molec=chem_2%clust_out_molec)

    else
        write(*,*) 'No aerosol-cluster feedback selected'
    end if

   
    
    !!! update acid and DMA!!!!
    cH2SO4=chem_2%conc_vapor(1)*1d-6
    cDMA=chem_2%conc_vapor(2)*1d-6

 

end subroutine clustering_subroutine


end module ClusterIn_plugin