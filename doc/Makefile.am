# hoxsl manual Makefile
#
# Responsible for building the project documentation.
#
#  Copyright (C) 2015 LoVullo Assoicates, Inc.
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

path_src := ../src
path_aux := ../build-aux

stylesheets := $(shell find "$(path_src)" \
                         -name '*.xsl' )
stexi       := $(stylesheets:.xsl=.texi)

info_TEXINFOS  = liza-proguic.texi
liza_proguic_TEXINFOS = license.texi $(stexi) compilation.texi util.texi

MAKEINFOHTML = $(MAKEINFO) --html --css-include liza.css

.DELETE_ON_ERROR:

xsltexis: $(stexi)
%.texi: %.xsl
	$(JAVA) -jar "$(SAXON_CP)" \
	    -xsl:"$(path_aux)/literate-xsl/src/texinfo.xsl" \
	    "$<" > "$@"

html-local: xsltexis liza.css

clean-local:
	-rm -f $(stexi)

