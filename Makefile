
ifndef MSEDIR
MSEDIR := mseide-msegui/
# git clone https://github.com/mse-org/mseide-msegui.git --single-branch --depth 1
endif
MSELIBDIR := $(MSEDIR)lib/common/

ifeq ($(OS),Windows_NT)
OS := windows
else
OS := linux
endif

PC = fpc

PFLAGS := -Mobjfpc -Sh
PFLAGS += -Fu$(MSELIBDIR)*
PFLAGS += -Fu$(MSELIBDIR)kernel/$(OS)
PFLAGS += -CX -Xs -XX -O2

SOURCES := $(wildcard *.pas) tables.inc
PROGRAM := marelles

$(PROGRAM): $(PROGRAM).pas $(SOURCES)
	@$(PC) $(PFLAGS) $<

tables:
	@$(PC) -Mobjfpc -Sh -FEfactory factory/factory.pas
	@factory/factory > tables.inc

marelles.desktop:
	@printf '%s\n' '[Desktop Entry]' 'Type=Application' 'Name=Marelles' \
	  'Comment=Jeu du moulin (mérelles)' 'Exec=$(CURDIR)/$(PROGRAM)' \
	  'Path=$(CURDIR)' 'Icon=$(CURDIR)/images/icone128.png' \
	  'Terminal=false' 'Categories=Game;BoardGame;' > $@

install-desktop: marelles.desktop
	@mkdir -p ~/.local/share/applications
	@cp -v $< ~/.local/share/applications/

clean:
	@rm -fv *.bak *.bak? *.log *.o *.ppu
	@rm -rfv units
	@rm -fv factory/*.o

distclean: clean
	@rm -fv $(PROGRAM) $(PROGRAM).dbg $(PROGRAM).exe
	@rm -fv factory/factory factory/factory.exe
