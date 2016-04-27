# Packages
# --------------------------------------------------------------------
pkg_packages := dbus-glib-1 saftlib glibmm-2.4 giomm-2.4
PKG_CFLAGS   := $(shell pkg-config --cflags $(pkg_packages))
PKG_LDFLAGS  := $(shell pkg-config --libs $(pkg_packages))

# Flags, Includes, ...
# --------------------------------------------------------------------
INC          :=-I/usr/include/saftlib
ADD_CFLAGS   := -g -Wall
CFLAGS       := $(PKG_CFLAGS) $(ADD_CFLAGS) $(CFLAGS) $(INC)
LDFLAGS      := $(PKG_LDFLAGS) $(LDFLAGS)
CC           := g++

# Targets
# --------------------------------------------------------------------
targets = main

.PHONY: all clean
all: $(targets)

main: main.cpp
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS)

clean:
	$(RM) $(targets)
