# compiler
F90 = /usr/local/bin/gfortran

# Put .o and .mod files here:
OBJDIR = build

ACDC_DIR=Clusterin_multiple_chem_RICC2
NAC := $(shell find ${ACDC_DIR}/cluster_chem_* -maxdepth 0 -type d |wc -l|sed 's/ //g')

CLUSTER_CHEM_NUM := $(shell seq $(NAC))
# Directories to search files in (in addition to the current one)

# VPATH = $(OBJDIR):chemistry_DMS_HM_20201222:$(ACDC_DIR):$(foreach n,$(CLUSTER_CHEM_NUM),$(ACDC_DIR)/cluster_chem_$(n):)
VPATH = $(OBJDIR):mcm_PRAMv1_DMS_I2O5:megan:$(foreach n,$(CLUSTER_CHEM_NUM),$(ACDC_DIR)/cluster_chem_$(n):)

# When compiling, search for files in these directories:
# VPATH = $(OBJDIR): mcm_PRAMv1_DMS megan ACDC_module_ions_2018_08_31 ACDC_module_2016_09_23
# VPATH = $(OBJDIR):chemistry_biogenic megan
NETCDF=/opt/local
# Options reminders:
# -w suppresses warning messages

# For programming (faster compiling):
# OPTS1 = -ffree-line-length-none -cpp -J$(OBJDIR) -I$(OBJDIR) -fcheck=all -ffpe-trap=invalid,zero,overflow
# #-Wall -Wextra -Wsurprising -Warray-temporaries -Wtabs -Wno-character-truncation

# #for debugging:
# #OPTS1 = -ffree-line-length-none -cpp -J$(OBJDIR) -I$(OBJDIR) -fcheck=all -Wall -Wextra -g -O0 -ffpe-trap=invalid,zero,overflow -fbounds-check

# #this runs 2x faster, but slower compilation
# OPTS = -ffree-line-length-none -cpp -J$(OBJDIR) -I$(OBJDIR) -fcheck=all -ffpe-trap=invalid,zero,overflow -Os 
#OPTS = -ffree-line-length-none -cpp -J$(OBJDIR) -I$(OBJDIR) -fcheck=all -Wall -Wextra -g -O0 -ffpe-trap=invalid,zero,overflow -fbounds-check
# For programming (faster compiling):
OPTS1 = -ffree-line-length-none -cpp -I$(NETCDF)/include -J$(OBJDIR) -I$(OBJDIR) -fcheck=all -ffpe-trap=invalid,zero,overflow 

#this runs 2x faster, but slower compilation
# OPTS = -ffree-line-length-none -cpp -I$(NETCDF)/include -J$(OBJDIR) -I$(OBJDIR) -fcheck=all -ffpe-trap=invalid,zero,overflow -Os 
OPTS = -ffree-line-length-none -cpp -I$(NETCDF)/include -J$(OBJDIR) -I$(OBJDIR) -fcheck=all -ffpe-trap=invalid,zero,overflow -Os	
# OPT = -ffpe-trap=invalid,zero,overflow

CHEM_OPTS = $(OPTS1)

# MAIN_OBJECTS = reaction_rates.o thermodynamics.o acidity.o dynamics.o diffusivity.o constants.o output.o opkdmain.o opkda1.o opkda2.o
MAIN_OBJECTS = reaction_rates.o thermodynamics.o acidity.o dynamics.o diffusivity.o cluster_plugin.o acdc_datatypes.o constants.o output.o 

CHEM_OBJECTS = second_Precision.o second_Parameters.o second_Initialize.o second_Util.o second_Monitor.o second_JacobianSP.o \
               second_LinearAlgebra.o second_Jacobian.o second_Global.o second_Rates.o second_Integrator.o second_Function.o \
               second_Model.o second_Main.o
MEGAN_OBJECTS = Megan_version_2.o M2_canopy.o M2_SPC_MGN.o M2_LD_FCT.o M2_RHO_SPC.o M2_TEMPD_PRM.o M2_REL_EM_ACT.o M2_gamma_etc.o \
                LAI_Hyy_month.o          
# ACDC_OBJECTS = get_acdc_J.o driver.o acdc_system.o acdc_equations.o monomer_settings.o solution_settings.o \
#                vode.o vodea.o        
# ACDC_OBJECTS_DMA = get_acdc_D.o driver_acdc_D.o acdc_system_AD_new.o acdc_equations_AD_new.o monomer_settings_acdc_DMA.o		   
ACDC_OBJECTS = \
	$(addprefix $(OBJDIR)/, $(foreach n, $(CLUSTER_CHEM_NUM),clusterin_$(n).o driver_$(n).o acdc_system_$(n).o \
	acdc_equations_$(n).o acdc_simulation_setup_$(n).o) acdc_aerosol_parameters.o solution_settings.o dvode.o)
# ACDC_OBJECTS = \
# 	$(addprefix $(OBJDIR)/, $(foreach n, $(CLUSTER_CHEM_NUM),clusterin_$(n).o driver_$(n).o acdc_system_$(n).o \
# 	acdc_equations_$(n).o acdc_simulation_setup_$(n).o) acdc_aerosol_parameters.o solution_settings.o vode.o vodea.o)

# Make automatic variables reminder:
#   $@   target
#   $<   first prerequisite
#   $^   all dependencies, duplicates removed

all: adchem1D.exe

# Here is the link step:

adchem1D.exe: adchem1D.o $(MAIN_OBJECTS) $(CHEM_OBJECTS) $(MEGAN_OBJECTS) $(ACDC_OBJECTS) 
	 $(F90) $(OPTS1) $^ -o $@

# Here are the compile steps:

# Main program



$(OBJDIR)/adchem1D.o: adchem1D_clustering.f90 $(MAIN_OBJECTS) $(CHEM_OBJECTS) $(MEGAN_OBJECTS) $(ACDC_OBJECTS) 
	 $(F90) $(OPTS1) -c $< -o $@


$(OBJDIR)/reaction_rates.o: reaction_rates_20220118.f90 constants.o $(CHEM_OBJECTS) 
	 $(F90) $(OPTS) -c $< -o $@

$(OBJDIR)/thermodynamics.o: thermodynamicsDMS.f90 constants.o acidity.o $(CHEM_OBJECTS)
	 $(F90) $(OPTS) -c $< -o $@	 
	 
$(OBJDIR)/dynamics.o: dynamicsDMS_atm_clusterin.f90 constants.o acdc_datatypes.o $(CHEM_OBJECTS)
	 $(F90) $(OPTS) -c $< -o $@	 

$(OBJDIR)/diffusivity.o: diffusivity.f90 constants.o $(CHEM_OBJECTS)
	 $(F90) $(OPTS) -c $< -o $@	 	 

$(OBJDIR)/constants.o: constants.f90 $(CHEM_OBJECTS)
	 $(F90) $(OPTS) -c $< -o $@

$(OBJDIR)/acidity.o: acidityDMS.f90 $(CHEM_OBJECTS)
	 $(F90) $(OPTS) -c $< -o $@

$(OBJDIR)/output.o: output.f90 constants.o $(CHEM_OBJECTS)
	 $(F90) $(OPTS) -c $< -o $@

$(OBJDIR)/cluster_plugin.o: clustering_module.f90 acdc_datatypes.o $(ACDC_OBJECTS)
	 $(F90) $(OPTS) -c $< -o $@	 

$(OBJDIR)/acdc_datatypes.o: acdc_datatypes.f90 $(CHEM_OBJECTS)
	 $(F90) $(OPTS) -c $< -o $@	 
	 	 
#$(OBJDIR)/cloud_chem.o: cloud_chem.f90 constants.o vode.o vodea.o $(CHEM_OBJECTS) 
#	 $(F90) $(OPTS) -c $< -o $@	 

#$(OBJDIR)/multilayer.o: multilayer.f90 constants.o opkdmain.o opkda1.o opkda2.o $(CHEM_OBJECTS) 
#	 $(F90) $(OPTS) -c $< -o $@
	

# ODEPACK is Fortran 77, hence -std=legacy.
# -w turns off warnings; we are not going to modify ODEPACK code even
# if it gives some warnings.

$(OBJDIR)/opkda1.o: opkda1.f
	$(F90) $(OPTS) -std=legacy -w -c opkda1.f
$(OBJDIR)/opkda2.o: opkda2.f# 	
	$(F90) $(OPTS) -std=legacy -c opkda2.f
$(OBJDIR)/opkdmain.o: opkdmain.f
	$(F90) $(OPTS) -std=legacy -c opkdmain.f

# Download ODEPACK code, if not present:
opkdmain.f:
	wget http://www.netlib.org/odepack/opkdmain.f
opkda1.f:
	wget http://www.netlib.org/odepack/opkda1.f
opkda2.f:
	wget http://www.netlib.org/odepack/opkda2.f
	
# Chemistry

$(OBJDIR)/second_Precision.o: second_Precision.f90
	 $(F90) $(CHEM_OPTS) -c $< -o $@
$(OBJDIR)/second_Parameters.o: second_Parameters.f90 second_Precision.o
	 $(F90) $(CHEM_OPTS) -c $< -o $@
$(OBJDIR)/second_Global.o: second_Global.f90 second_Parameters.o
	 $(F90) $(CHEM_OPTS) -c $< -o $@
$(OBJDIR)/second_Initialize.o: second_Initialize.f90 second_Parameters.o second_Global.o
	 $(F90) $(CHEM_OPTS) -c $< -o $@
$(OBJDIR)/second_Util.o: second_Util.f90 second_Parameters.o second_Monitor.o
	 $(F90) $(CHEM_OPTS) -c $< -o $@
$(OBJDIR)/second_Monitor.o: second_Monitor.f90
	 $(F90) $(CHEM_OPTS) -c $< -o $@
$(OBJDIR)/second_JacobianSP.o: second_JacobianSP.f90
	 $(F90) $(CHEM_OPTS) -c $< -o $@
$(OBJDIR)/second_LinearAlgebra.o: second_LinearAlgebra.f90 second_Parameters.o second_JacobianSP.o
	 $(F90) $(CHEM_OPTS) -c $< -o $@
$(OBJDIR)/second_Jacobian.o: second_Jacobian.f90 second_Parameters.o second_JacobianSP.o
	 $(F90) $(CHEM_OPTS) -c $< -o $@
$(OBJDIR)/second_Rates.o: second_Rates.f90 second_Parameters.o second_Global.o
	 $(F90) $(CHEM_OPTS) -c $< -o $@
$(OBJDIR)/second_Integrator.o: second_Integrator.f90 second_Precision.o second_Global.o second_Parameters.o second_JacobianSP.o \
second_LinearAlgebra.o second_Function.o
	 $(F90) $(CHEM_OPTS) -c $< -o $@
$(OBJDIR)/second_Function.o: second_Function.f90 second_Parameters.o
	 $(F90) $(CHEM_OPTS) -c $< -o $@
$(OBJDIR)/second_Model.o: second_Model.f90 second_Precision.o second_Parameters.o second_Global.o second_Function.o \
second_Integrator.o second_Rates.o second_Jacobian.o second_LinearAlgebra.o second_Monitor.o second_Util.o
	 $(F90) $(CHEM_OPTS) -c $< -o $@
$(OBJDIR)/second_Main.o: second_Main.f90 second_Model.o second_Initialize.o
	 $(F90) $(CHEM_OPTS) -c $< -o $@

# MEGAN

$(OBJDIR)/LAI_Hyy_month.o: LAI_Hyy_month.f90
	 $(F90) $(OPTS) -c $< -o $@	 	 
	
$(OBJDIR)/M2_canopy.o: megan/M2_canopy.F90
	 $(F90) $(OPTS) -c $< -o $@	 	 
   
$(OBJDIR)/M2_LD_FCT.o: M2_LD_FCT.f90
	 $(F90) $(OPTS) -c $< -o $@	 	 
	
$(OBJDIR)/M2_RHO_SPC.o: M2_RHO_SPC.f90
	 $(F90) $(OPTS) -c $< -o $@	 	 
	
$(OBJDIR)/M2_TEMPD_PRM.o: M2_TEMPD_PRM.f90
	 $(F90) $(OPTS) -c $< -o $@	 	 
	
$(OBJDIR)/M2_REL_EM_ACT.o: M2_REL_EM_ACT.f90
	 $(F90) $(OPTS) -c $< -o $@	 	 
	
$(OBJDIR)/M2_SPC_MGN.o: M2_SPC_MGN.f90
	 $(F90) $(OPTS) -c $< -o $@	 	 

$(OBJDIR)/M2_gamma_etc.o: M2_gamma_etc.f90 M2_TEMPD_PRM.o M2_REL_EM_ACT.o
	 $(F90) $(OPTS) -c $< -o $@	 	 
	
$(OBJDIR)/Megan_version_2.o: Megan_version_2.f90 M2_canopy.o M2_gamma_etc.o \
                   M2_LD_FCT.o M2_RHO_SPC.o M2_SPC_MGN.o 
	 $(F90) $(OPTS) -c $< -o $@
	 
# ACDC
# ACDC



$(OBJDIR)/clusterin_%.o: clusterin_%.f90 driver_%.o acdc_system_%.o acdc_simulation_setup_%.o
	$(F90) $(OPTS) -c $< -o $@

$(OBJDIR)/driver_%.o: driver_acdc_J_%.f90 acdc_system_%.o acdc_simulation_setup_%.o solution_settings.o
	$(F90) $(OPTS) -c $< -o $@

$(OBJDIR)/acdc_equations_%.o: acdc_equations_%.f90 acdc_simulation_setup_%.o
	$(F90) $(OPTS) -c $< -o $@

$(OBJDIR)/acdc_system_%.o: acdc_system_%.f90
	$(F90) $(OPTS) -c $< -o $@

$(OBJDIR)/acdc_simulation_setup_%.o: acdc_simulation_setup_%.f90 acdc_system_%.o acdc_aerosol_parameters.o
	$(F90) $(OPTS) -c $< -o $@

# Common files for all cluster systems
$(OBJDIR)/acdc_aerosol_parameters.o: $(ACDC_DIR)/acdc_aerosol_parameters.f90
	$(F90) $(OPTS) -c $< -o $@

$(OBJDIR)/solution_settings.o: $(ACDC_DIR)//solvers/solution_settings.f90
	$(F90) $(OPTS) -c $< -o $@
    
$(OBJDIR)/dvode.o: $(ACDC_DIR)/solvers/dvode.f
	$(F90) $(OPTS) -std=legacy -c $< -o $@

# $(OBJDIR)/vode.o: $(ACDC_DIR)/solvers/vode.f
# 	$(F90) $(OPTS) -std=legacy -c $< -o $@

# $(OBJDIR)/vodea.o: $(ACDC_DIR)/solvers/vodea.f 	
# 	$(F90) $(OPTS) -std=legacy -c $< -o $@

CHEM_MODS = $(CHEM_OBJECTS:.o=.mod)
MAIN_MODS = $(MAIN_OBJECTS:.o=.mod)
ACDC_MODS = $(ACDC_OBJECTS:.o=.mod)
MEGAN_MODS = $(MEGAN_OBJECTS:.o=.mod)

show:
	echo $(MAIN_MODS)
	
# This entry allows you to type 'make clean' to get rid of all object and module files 
clean:
	-@rm $(ACDC_OBJECTS)  $(ACDC_MODS)         2>/dev/null || true
	-@cd $(OBJDIR) ; rm adchem1D.o  $(MAIN_OBJECTS) $(MEGAN_OBJECTS) $(MAIN_MODS) $(MEGAN_MODS) 2>/dev/null || true
	-@cd $(OBJDIR) ; rm aciditydms* driver_acdc_j* clusterin_plugin* dynamicsdms_atm* reaction_rates* thermodynamics*  2>/dev/null || true
	-@rm adchem1D.exe                                                 2>/dev/null || true

# With 'clean', don't remove chemistry object files, since it takes very long (minutes, or tens of minutes if big chemistry)
# to compile them, and there usually is no need to recompile them

	
# If you really want to remove chemistry objects too, use this
cleanall:
	-@cd $(OBJDIR) ; rm $(MAIN_OBJECTS) $(CHEM_OBJECTS) $(CHEM_MODS) $(MEGAN_OBJECTS) $(ACDC_OBJECTS)    2>/dev/null || true
	-@cd $(OBJDIR) ; rm adchem1D.o                                    2>/dev/null || true
	-@rm adchem1D.exe                                                 2>/dev/null || true
	-@rm $(OBJDIR)/*                                                  2>/dev/null || true

# Some explanation for the clean commands:
#-@cd $(OBJDIR) ; rm $(MAIN_OBJECTS) $(MAIN_MODS) $(ACDC_MODS) $(MEGAN_OBJECTS) $(MEGAN_MODS) $(ACDC_OBJECTS)    2>/dev/null || true
# -            lets make continue when a command gives an error
# @            suppresses echoing the command
# 2>/dev/null  hides the error messages from e.g. rm command, if files don't exist
# || true      hides the message that there was an error in the command
#
# ref. http://stackoverflow.com/questions/3148492/makefile-silent-remove

