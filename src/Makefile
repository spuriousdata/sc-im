# Makefile $Revision: 0.1.2


# Specify the name of the program.
# All documentation and installation keys on this value.
name=scim
NAME=SC-IM
SNAME := -DSNAME=\"$(name)\"

# Compiler
CC=gcc

# The base directory where everything should be installed.  If you're
# packaging this with an O/S, for example, you'll probably want to change
# this to /usr.  Otherwise, /usr/local is probably more appropriate, unless
# you're replacing the vendor-supplied version.
prefix=/usr

# This is where the install step puts it.
EXDIR=$(prefix)/bin

# Help dir
HELPDIR := $(prefix)/share/$(name)
HELP_PATH := -DHELP_PATH=\"$(HELPDIR)\"

# This is where the man page goes.
MANDIR=$(prefix)/man/man1
MANEXT=1
MANMODE=644

# This is where the library file (tutorial) goes.
#LIBDIR=/usr/local/share/$(name) # reno
LIBDIR=$(prefix)/share/doc/$(name)
LIBRARY=-DLIBDIR=\"$(LIBDIR)\"

# For Building SC-IM in LINUX, set LINUX variable below
LINUX := -DLINUX
#LINUX :=

# For Building SC-IM in FREEBSD, set FREEBSD variable below
#FREEBSD := -DFREEBSD
FREEBSD :=

# For Building SC-IM in NETBSD, set NETBSD variable below
#NETBSD := -DNETBSD
NETBSD :=

# For Building SC-IM in MACOSX, set MACOSX variable below
#MACOSX := -DMACOSX
MACOSX :=

# Set SIMPLE for lex.c if you don't want arrow keys or lex.c blows up
#SIMPLE := -DSIMPLE

# Set USELOCALE to use your local d_fmt for converting dates with C-d shortcut.
# (See DATES INPUT in help for more details).
# You also should set this flag if you use extended ascii chars.
USELOCALE := -DUSELOCALE

# Set this if you want SC-IM to have color support
USECOLORS := -DUSECOLORS

# Set SIGVOID if signal routines are type void.
# use: SIGVOID=-DSIGVOID for:
# System 5.3, SunOS 4.X, VMS, BSD4.4 (reno), and ANSI C Compliant systems
# use: SIGVOID= for:
#  BSD systems (excluding reno, BSD4.4), and the UNIXPC 'cc'
SIGVOID := -DSIGVOID

# Set IEEE_MATH if you need setsticky() calls in your signal handlers
#IEEE_MATH := -DIEEE_MATH

# The -ffloat-store compiler option is necessary for compiling interp.c to
# prevent spurious "Still changing after x iterations" errors, intermittent
# problems with the @round function, comparisons failing when they shouldn't,
# and potentially other similar problems due to FPU registers having greater
# precision than doubles in memory.  This is known to be necessary for GCC
# on x86 processors/FPUs, and probably others.
FLOAT_STORE := -ffloat-store

# Set RINT=-DRINT if you do not have rint() in math.h
# Set RINT= on/with (they have rint):
# SunOS 4.0.3c compiler
# BSD4.4 (reno)
#RINT := -DRINT

# If your system supports POSIX.2 regular expressions, REGEX should be
# set to -DREGCOMP.  Otherwise, set REGEX to -DREGCMP if you have the
# regcmp/regex regular expression routines (most System V based systems
# do) or to -DRE_COMP if you have the re_comp/re_exec regular expression
# routines (most BSD based systems do).  If your system has no support for
# regular expressions, leave REGEX unset.
#REGEX := -DREGCMP
#REGEX := -DRE_COMP
REGEX := -DREGCOMP

# This is the name of a pager like "more".
#DFLT_PAGER := -DDFLT_PAGER=\"more\"
DFLT_PAGER := -DDFLT_PAGER=\"less\"

# This is the name of the history file that is looked in your HOME directory
# If undefined, no history will be saved
HISTORY_FILE := -DHISTORY_FILE=\".$(name)info\"

# If your system doesn't have notimeout() in curses, define NONOTIMEOUT
#NO_NOTIMEOUT := -DNONOTIMEOUT

# MS-DOS (and perhaps Windows) needs y_tab instead of the normal y.tab
#YTAB := y_tab
YTAB := y.tab

#YACC := bison -y
SED := sed

# Uncomment below if you want basic XLS import support.
# Requires libxlsreader.
# Add -lxlsreader in LDLIBS as well.
XLS := 
#XLS := -DXLS

# Uncomment below if you want basic XLSX import support.
# Requires libzip-dev and libxml2-dev
# Add -lzip -xml2 to LDLIBS as well.
# and -I/usr/include/libxml2 or the acording path to the libxml headers, in CFLAGS
XLSX :=
#XLSX := -DXLSX

# Set UNDO variable to enable this feature
#UNDO :=
UNDO := -DUNDO

# Set the maximum number of rows in sheet
# Can be set up to 1048576.
MAXROWS := 65536

#CFLAGS := -O2 -Wall -pipe -g
CFLAGS := $(LINUX) $(FREEBSD) $(NETBSD) $(MACOSX) -O2 -Wall -pipe -g -I/usr/include/libxml2
CFLAGS := $(CFLAGS) $(USECOLORS) $(USELOCALE) $(UNDO) $(SIGVOID) $(DFLT_PAGER)
CFLAGS := $(CFLAGS) $(IEEE_MATH) $(RINT) $(REGEX) $(LIBRARY) -DMAXROWS=$(MAXROWS)
CFLAGS := $(CFLAGS) $(HELP_PATH) $(SNAME) $(NO_NOTIMEOUT) $(SIMPLE) $(XLS) $(XLSX) $(HISTORY_FILE)

# NOTE: ncursesw library should be used.
# Not the ncurses library.
LDLIBS := -lm -lncursesw
#LDLIBS := -lm -lncurses -lxlsreader
#LDLIBS := -lm -lncurses -lxlsreader -lzip -lxml2

OBJS := $(patsubst %.c, %.o, $(wildcard *.c) $(wildcard utils/*.c)) gram.o

# The documents in the Archive
#DOCS := README torev

.PHONY : all clean install

all : $(name)

install :
	install -d $(DESTDIR)$(prefix)/bin
	install $(name) $(DESTDIR)$(prefix)/bin/$(name)
	install -d $(DESTDIR)$(HELPDIR)
	install doc $(DESTDIR)$(HELPDIR)/$(name)_help
	install -d $(DESTDIR)$(prefix)/share/man/man1
	install -m 644 sc-im.1 $(DESTDIR)$(prefix)/share/man/man1/$(name).1


uninstall :
	-rm $(DESTDIR)$(prefix)/bin/$(name)
	-rm $(DESTDIR)$(HELPDIR)/$(name)_help
	-rm $(DESTDIR)$(prefix)/share/man/man1/$(name).1

$(name) : $(OBJS)
	$(CC) $(LDFLAGS) $^ -o $@ $(LDLIBS) 

$(name)qref: sc.h
	$(CC) $(CFLAGS) $(LDFLAGS) -DQREF $(QREF_FMT) -DSCNAME=\"$(NAME)\" -o $(name)qref help.c $(LDLIBS)

$(OBJS) : $(YTAB).h experres.h statres.h

$(YTAB).h : gram.y gram.c
	test -f $(YTAB).c && mv $(YTAB).c gram.c

gram.c : gram.y
	$(YACC) -d $<

pvmtbl.o: sc.h pvmtbl.c
	$(CC) ${CFLAGS} -c -DPSC pvmtbl.c

experres.h : gram.y
	sed -f eres.sed < gram.y > experres.h

statres.h : gram.y
	sed -f sres.sed < gram.y > statres.h

interp.o : interp.c
	$(CC) $(CFLAGS) $(FLOAT_STORE) -c $< -o $@

clean:
	rm -f $(OBJS)
	rm -f *res.h $(YTAB).h
	rm -f debug core gram.c y.output pxmalloc.c pvmtbl.c tags $(name)qref
	rm -f qhelp.c $(name)
