OBJDIR = build/obj
PROJECTROOT = $(shell pwd)

TARGET = pong
TARGETFPGA = xc3s1200e-fg320-4

BOARD = nexys2
FLASHTOOL= nexys2prog 

CONSTRAINTS = $(TARGET)_$(BOARD)_constraints.ucf
XSTSCRIPT = build/scripts/$(TARGET).scr
UTFILE = build/scripts/$(TARGET).ut

#--------------------------------------------------------------------

#root of your xilinx binaries
XILINXROOT = /opt/Xilinx/11.1/ISE/bin/lin
#XILINXROOT = /home/david/Data/devel/apps/Xilinx/11.1/ISE/bin/lin

XST = $(XILINXROOT)/xst
NGDBUILD = $(XILINXROOT)/ngdbuild
MAP = $(XILINXROOT)/map
PAR = $(XILINXROOT)/par
TRCE = $(XILINXROOT)/trce
BITGEN = $(XILINXROOT)/bitgen

#--------------------------------------------------------------------

# main rule
all: $(TARGET).bit


prepare:
	cat $(PROJECTROOT)/$(XSTSCRIPT).tpl | sed -e "s/TARGETFPGA/$(TARGETFPGA)/" -e  "s/TARGET/$(TARGET)/" > $(PROJECTROOT)/$(XSTSCRIPT) 

synthesize: prepare
	cd $(OBJDIR); $(XST) -ifn $(PROJECTROOT)/$(XSTSCRIPT) -ofn $(TARGET).srp 
	cd $(OBJDIR); $(NGDBUILD) -nt on -uc $(PROJECTROOT)/$(CONSTRAINTS) $(TARGET).ngc $(TARGET).ngd

map:
	cd $(OBJDIR); $(MAP) -pr b $(TARGET).ngd -o $(TARGET).ncd $(TARGET).pcf

placeandroute:
	cd $(OBJDIR); $(PAR) -w -ol high $(TARGET).ncd $(TARGET).ncd $(TARGET).pcf

trace:
	cd $(OBJDIR); $(TRCE) -v 10 -o $(TARGET).twr $(TARGET).ncd $(TARGET).pcf

$(TARGET).bit: synthesize map placeandroute trace
	cd $(OBJDIR); $(BITGEN) -w $(TARGET).ncd $@ -f $ $(PROJECTROOT)/$(UTFILE)
	mv $(OBJDIR)/$@ $(PROJECTROOT)

upload: 
	$(FLASHTOOL) -v $(TARGET).bit  
clean:
	rm -rf $(OBJDIR)/*
	rm -rf $(TARGET).bit
	rm -rf $(TARGET).svf
	rm -rf _impact*
.PHONY: all clean

