# Liza Program UI Compiler Makefile
#
#  Copyright (C) 2017 R-T Specialty, LLC.
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##

SUBDIRS = doc

path_src = src
path_test = test
#
# all source files will be run through hoxsl; see `applies' target
apply_src := $(path_src)/meta.xsl $(path_test)/util/serialize.xsl
apply_dest := $(apply_src:%.xsl=%.xsl.apply)

.DELETE_ON_ERROR:
.PHONY: nodoc test check applies

all: nodoc

nodoc: applies

test: check
check: | applies
	$(path_test)/runner

# the "applies" are hoxsl-generated stylesheets containing definitions to
# permit partial function application
applies: $(apply_dest)
%.apply: %
	$(JAVA) -jar "$(SAXON_CP)" \
	    -xsl:"$(HOXSL)/src/transform/apply-gen.xsl" \
	    "$<" > "$@"

clean-local:
	$(RM) $(apply_dest)

