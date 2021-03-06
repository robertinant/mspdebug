# MSPDebug - debugging tool for the eZ430
# Copyright (C) 2009, 2010 Daniel Beer
# Copyright (C) 2010 Andrew Armenia
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

CC ?= gcc
INSTALL = /usr/bin/install
PREFIX ?= /usr/local
LDFLAGS ?= -s

BINDIR = ${PREFIX}/bin/
MANDIR = ${PREFIX}/share/man/man1
LIBDIR = ${PREFIX}/lib/


ifdef WITHOUT_READLINE
	READLINE_CFLAGS =
	READLINE_LIBS =
else
	READLINE_CFLAGS = -DUSE_READLINE
	READLINE_LIBS = -lreadline
endif

UNAME_S := $(shell sh -c 'uname -s')
UNAME_O := $(shell sh -c 'uname -o 2> /dev/null')

ifeq ($(UNAME_S),Darwin) # Mac OS X/MacPorts stuff
	PORTS_CFLAGS := -I/opt/local/include
	PORTS_LDFLAGS := -L/opt/local/lib
else
  ifneq ($(filter $(UNAME_S),OpenBSD NetBSD DragonFly),)
	PORTS_CFLAGS := $(shell pkg-config --cflags libusb)
	PORTS_LDFLAGS := $(shell pkg-config --libs libusb) -ltermcap -pthread
  else
	PORTS_CFLAGS :=
	PORTS_LDFLAGS :=
  endif
endif

ifeq ($(OS),Windows_NT)
    MSPDEBUG_CC = gcc
    BINARY = mspdebug.exe

    ifneq ($(UNAME_O),Cygwin)
	OS_LIBS = -lws2_32 -lregex
	OS_CFLAGS = -D__Windows__ -DNO_SHELLCMD
    endif
else
    MSPDEBUG_CC = $(CC)
    BINARY = mspdebug

    ifneq ($(filter $(UNAME_S),OpenBSD NetBSD),)
	OS_LIBS =
    else ifneq ($(filter $(UNAME_S),FreeBSD DragonFly),)
	OS_CFLAGS = -pthread
	OS_LIBS = -lpthread
    else ifneq ($(filter $(UNAME_S),SunOS),)
	OS_LIBS = -lpthread -ldl -lresolv -lsocket -lnsl
    else
	OS_LIBS = -lpthread -ldl
    endif
endif

INCLUDES = -I. -Isimio -Iformats -Itransport -Idrivers -Iutil -Iui
GCC_CFLAGS = -O1 -Wall -Wno-char-subscripts -ggdb
CONFIG_CFLAGS = -DLIB_DIR=\"$(LIBDIR)\"

MSPDEBUG_LDFLAGS = $(LDFLAGS) $(PORTS_LDFLAGS)
MSPDEBUG_LIBS = -lusb $(READLINE_LIBS) $(OS_LIBS)
MSPDEBUG_CFLAGS = $(CFLAGS) $(READLINE_CFLAGS) $(PORTS_CFLAGS)\
 $(GCC_CFLAGS) $(INCLUDES) $(CONFIG_CFLAGS) $(OS_CFLAGS)

all: $(BINARY)

clean:
	rm -f */*.o
	rm -f $(BINARY)

install: $(BINARY) mspdebug.man
	mkdir -p $(DESTDIR)$(BINDIR)
	$(INSTALL) -m 0755 $(BINARY) $(DESTDIR)$(BINDIR)
	mkdir -p $(DESTDIR)$(MANDIR)
	$(INSTALL) -m 0644 mspdebug.man $(DESTDIR)$(MANDIR)/mspdebug.1
	mkdir -p $(DESTDIR)$(LIBDIR)/mspdebug
	$(INSTALL) -m 0644 ti_3410.fw.ihex \
		$(DESTDIR)$(LIBDIR)/mspdebug/ti_3410.fw.ihex

.SUFFIXES: .c .o

OBJ=\
    util/btree.o \
    util/expr.o \
    util/list.o \
    util/sockets.o \
    util/sport.o \
    util/usbutil.o \
    util/util.o \
    util/vector.o \
    util/output.o \
    util/output_util.o \
    util/opdb.o \
    util/prog.o \
    util/stab.o \
    util/dis.o \
    util/gdb_proto.o \
    util/dynload.o \
    util/demangle.o \
    util/powerbuf.o \
    util/ctrlc.o \
    util/chipinfo.o \
    transport/cp210x.o \
    transport/cdc_acm.o \
    transport/ftdi.o \
    transport/rf2500.o \
    transport/ti3410.o \
    transport/comport.o \
    transport/bslhid.o \
    drivers/device.o \
    drivers/bsl.o \
    drivers/fet.o \
    drivers/fet_core.o \
    drivers/fet_proto.o \
    drivers/fet_error.o \
    drivers/fet_db.o \
    drivers/flash_bsl.o \
    drivers/gdbc.o \
    drivers/sim.o \
    drivers/tilib.o \
    drivers/goodfet.o \
    drivers/obl.o \
    drivers/devicelist.o \
    drivers/fet_olimex_db.o \
    drivers/jtdev.o \
    drivers/jtaglib.o \
    drivers/pif.o \
    drivers/loadbsl.o \
    drivers/loadbsl_fw.o \
    drivers/hal_proto.o \
    drivers/v3hil.o \
    drivers/fet3.o \
    drivers/bsllib.o \
    drivers/rom_bsl.o \
    formats/binfile.o \
    formats/coff.o \
    formats/elf32.o \
    formats/ihex.o \
    formats/symmap.o \
    formats/srec.o \
    formats/titext.o \
    simio/simio.o \
    simio/simio_tracer.o \
    simio/simio_timer.o \
    simio/simio_wdt.o \
    simio/simio_hwmult.o \
    simio/simio_gpio.o \
    simio/simio_console.o \
    ui/gdb.o \
    ui/rtools.o \
    ui/sym.o \
    ui/devcmd.o \
    ui/flatfile.o \
    ui/reader.o \
    ui/cmddb.o \
    ui/stdcmd.o \
    ui/aliasdb.o \
    ui/power.o \
    ui/input.o \
    ui/input_console.o \
    ui/input_async.o \
    ui/main.o

$(BINARY): $(OBJ)
	$(MSPDEBUG_CC) $(MSPDEBUG_LDFLAGS) -o $@ $^ $(MSPDEBUG_LIBS)

util/chipinfo.o:	chipinfo.db

.c.o:
	$(MSPDEBUG_CC) $(MSPDEBUG_CFLAGS) -o $@ -c $*.c
