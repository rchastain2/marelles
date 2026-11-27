PC = fpc

PFLAGS := -Mobjfpc -Sh
PFLAGS += -Fu..
PFLAGS += -Fu../morris-engine

PROGRAM := logtest

all: $(PROGRAM).log

$(PROGRAM): $(PROGRAM).pas ../game.pas ../computer.pas ../logfile.pas ../morris-engine/morrisengine.pas
	@$(PC) $(PFLAGS) $< > /dev/null

$(PROGRAM).log: $(PROGRAM)
	@./$(PROGRAM)

clean:
	@rm -fv *.bak *.bak? *.o *.ppu

distclean: clean
	@rm -fv $(PROGRAM) $(PROGRAM).exe $(PROGRAM).log

.PHONY: all clean distclean
