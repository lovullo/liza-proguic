# For use by automake and autoconf
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

# version string is dynamically generated
m4_define([ver], m4_esyscmd(build-aux/vergen))
m4_if(ver, [], [m4_exit(1)])

AC_INIT([liza-proguic], [ver], [dev@lovullo.com])
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE([foreign])

# provide more granular version numbers based on the version string, using
# the format MAJOR.MINOR.REV[-SUFFIX], where SUFFIX can itself contain
# dashes (and often will)
m4_define([ver_split],
  m4_split(
    patsubst(AC_PACKAGE_VERSION, [^\([^-]+\)-], [\1.]),
    [\.]))
AC_SUBST(MAJOR, m4_argn(1, ver_split))
AC_SUBST(MINOR, m4_argn(2, ver_split))
AC_SUBST(REV, m4_argn(3, ver_split))
AC_SUBST(SUFFIX, m4_argn(4, ver_split))

AC_ARG_VAR([JAVA], [The Java executable])
AC_CHECK_PROGS(JAVA, [java])

AC_ARG_VAR([SAXON_CP], [Saxon class path])

set_devnotes='@set DEVNOTES'
AC_ARG_ENABLE(
  [devnotes],
  [AS_HELP_STRING([--enable-devnotes],
                  [include note for developers (enabled by default)])],
  [test "x$enableval" != xno || set_devnotes="@c $set_devnotes"])

AC_SUBST([SET_DEVNOTES], [$set_devnotes])

set_srcuri='@c @set SRCURI <source code uri>'
AC_ARG_WITH(
  [srcuri],
  [AS_HELP_STRING([--with-srcuri],
                  [root URI for source code cross-references
                   (disabled by default)])],
  [test "x$withval" = x || set_srcuri="@set SRCURI $withval"])

AC_SUBST([SET_SRCURI], [$set_srcuri])

AC_CONFIG_FILES([Makefile doc/Makefile doc/config.texi src/init.xsl VERSION])

AC_OUTPUT

