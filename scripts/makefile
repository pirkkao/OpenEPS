# Requires:
# EVALUATE   - command to generate OUTPUTS from OLD_INPUTS
# GENERATE   - command to generate NEW_INPUTS from OUTPUTS
# INFILE     - name of the input file for EVALUATE command, must exist
# OUTFILE    - name of the output file for EVALUATE command
# OUTPUTS    - list of OUTFILEs 
# NEW_INPUTS - INFILEs for the next step, the goal of this make step

.PHONY : all

all : $(NEW_INPUTS)

# All OUTPUTS need to be ready before any of the NEW_INPUTS are made
$(NEW_INPUTS) : $(OUTPUTS)
	mkdir -p $(dir $@)
	$(GENPARS) $^ > $@

#
%/$(POSTPRO) : %/$(OUTFILE)
	cd $(dir $@); $(EVALUATE) $^

# Only INFILE corresponding to the specific OUTFILE need to exist before
# making OUTFILE 
%/$(OUTFILE) : %/$(INFILE)
	cd $(dir $@) ; $(RUNEPS)

#%/$(LINKFILE): %/$(INFILE)
#	$(GENLINK) $^ > $@


