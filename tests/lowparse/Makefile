all: verify-all extract-all

LOWPARSE_HOME ?= ../../src/lowparse

FSTAR_OUT_DIR?=.fstar-out

ifndef FSTAR_HOME
  FSTAR_EXE=$(shell which fstar.exe)
  ifneq ($(.SHELLSTATUS),0)
    FSTAR_HOME=../../../FStar
  endif
endif
ifdef FSTAR_HOME
  FSTAR_EXE=$(FSTAR_HOME)/bin/fstar.exe
endif

ifndef KREMLIN_HOME
  KREMLIB=$(shell ocamlfind query kremlin)
  ifneq ($(.SHELLSTATUS),0)
    KREMLIN_HOME=../../../kremlin
  endif
endif
ifdef KREMLIN_HOME
  KREMLIB=$(KREMLIN_HOME)/kremlib
  KREMLIN_EXE=$(KREMLIN_HOME)/krml
else
  KREMLIN_EXE=krml
endif

INCLUDE_KREMLIN=--include $(KREMLIB) --include $(KREMLIB)/obj

FSTAR_OPTIONS += --use_hints --trivial_pre_for_unannotated_effectful_fns false --include $(LOWPARSE_HOME) --already_cached +Prims,+FStar,+LowStar,+C,+Spec.Loops,+LowParse --cache_checked_modules --cache_dir $(FSTAR_OUT_DIR) --odir $(FSTAR_OUT_DIR) $(addprefix --include , $(INCLUDE_PATHS)) $(INCLUDE_KREMLIN) --cmi

# NOTE: the cache dir and out dir for F* MUST be the same, because the
# .krml files should be generated only once.

INTERMEDIATE_LEVEL=$(LOWPARSE_HOME)/LowParse_TestLib_SLow_c.c -ccopt -Wno-error-tautological-compare

LOW_LEVEL=$(LOWPARSE_HOME)/LowParse_TestLib_Low_c.c

MY_KREMLIN=$(KREMLIN_EXE) -bundle 'LowParse.\*'  -add-include '"kremlin/internal/compat.h"'

EXAMPLES=Example Example2 Example3 Example5 Example6 Example7 Example8 Example9 Example10 Example11 Example12 ExampleMono ExamplePair ExampleDepLen ExampleConstInt32le ExampleWriters

NOEXTRACT_EXAMPLES=ExamplePair
ROOT_FILES=$(addprefix LowParse, $(addsuffix .fst, $(EXAMPLES)))

EXCLUDE_KRML_FILES=$(FSTAR_OUT_DIR)/prims.krml

EXAMPLE_DEPEND_FILES=$(addsuffix .depend,$(EXAMPLES))

$(EXAMPLE_DEPEND_FILES): %.depend: *.fst *.fsti
	$(FSTAR_EXE) $(FSTAR_OPTIONS) $(OTHERFLAGS) --dep full LowParse$(basename $@).fst > $@

clean:
	rm -rf $(FSTAR_OUT_DIR) $(EXAMPLES) $(addsuffix .depend, $(EXAMPLES)) .depend

.depend: $(EXAMPLE_DEPEND_FILES)
	$(FSTAR_EXE) $(FSTAR_OPTIONS) $(OTHERFLAGS) --dep full $(ROOT_FILES) > $@
	for f in $(EXAMPLES) ; do \
	 $(MAKE) EXCLUDE_KRML_FILES='$(EXCLUDE_KRML_FILES)' EXAMPLE=$$f -f Makefile.example ; \
	done

include .depend

verify-all: $(ALL_CHECKED_FILES)

$(FSTAR_OUT_DIR)/%.checked:
	$(FSTAR_EXE) $(FSTAR_OPTIONS) $(OTHERFLAGS) $<
	touch $@

# No need to specify the path to the .fst file, since it will be
# recovered by the --include path
#
# NOTE: I use --extract_module because
# '--extract LowParse.SLow' would actually extract the whole
# namespace, not only the module.
$(FSTAR_OUT_DIR)/%.krml:
	$(FSTAR_EXE) $(FSTAR_OPTIONS) $(OTHERFLAGS) --codegen Kremlin $(notdir $(basename $<)) --extract_module $(notdir $(basename $(basename $<))) --warn_error '@241'
	touch $@

$(EXAMPLES): %: %/a.out

%/a.out:
	$(MY_KREMLIN) $(KREMLIN_ARGS) -tmpdir $(EXAMPLE) -bundle LowParse$(EXAMPLE)'.Aux' -warn-error '@2' -no-prefix LowParse$(EXAMPLE) $(EXAMPLE_KRML_FILES) -o $@
	$@

extract-all: $(filter-out $(NOEXTRACT_EXAMPLES), $(EXAMPLES))

Example: KREMLIN_ARGS=$(INTERMEDIATE_LEVEL)
Example2: KREMLIN_ARGS=$(INTERMEDIATE_LEVEL)
Example3: KREMLIN_ARGS=$(LOW_LEVEL)
Example5: KREMLIN_ARGS=
Example6: KREMLIN_ARGS=
Example7: KREMLIN_ARGS=
Example8: KREMLIN_ARGS=$(LOW_LEVEL)
Example9: KREMLIN_ARGS=$(LOW_LEVEL)
Example10: KREMLIN_ARGS=
Example11: KREMLIN_ARGS=
Example12: KREMLIN_ARGS=
ExampleMono: KREMLIN_ARGS=
ExamplePair: KREMLIN_ARGS=
ExampleDepLen: KREMLIN_ARGS=
ExampleConstInt32le: KREMLIN_ARGS=
ExampleWriters: KREMLIN_ARGS=$(LOW_LEVEL)

.PHONY: all verify-all clean extract-all $(EXAMPLES) %.fst-in %.fsti-in

%.fst-in:
	@echo $(FSTAR_OPTIONS) $(OTHERFLAGS)

%.fsti-in:
	@echo $(FSTAR_OPTIONS) $(OTHERFLAGS)
