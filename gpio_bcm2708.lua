-- gpio_bmc for the Raspberry Pi
-- Feb. 2015 Helmut Gruber
-- Principles taken from WiringPi C Code
-- https://github.com/WiringPi/WiringPi/blob/master/wiringPi/wiringPi.c
--
-- to be included with GPIO=require"gpio_bmc"

local periphery = require('periphery')
local GPIO = require('periphery').GPIO
local MMIO = require('periphery').MMIO

local PUD_OFF 		=	0
local PUD_DOWN	=	1
local PUD_UP			=	2

local function get_dt_ranges(filename, offset)
	local address
	local fp = io.open(filename, "rb")
	if  fp then
		fp:read(offset)	-- skip
		local buf=fp:read(4)
		fp:close()
		address = 	string.byte(buf,1)*256*256*256 +
							string.byte(buf,2)*256*256 +
							string.byte(buf,3)*256 +
							string.byte(buf,4)
	end
	return address
end

local function bcm_host_get_peripheral_address()
	local address = get_dt_ranges("/proc/device-tree/soc/ranges", 4)
	return address or 0x20000000 
end

local function bcm_host_get_peripheral_size()
	address = get_dt_ranges("/proc/device-tree/soc/ranges", 8)
	return address or 0x01000000 
end

local function bcm_host_get_sdram_address()
	address = get_dt_ranges("/proc/device-tree/axi/vc_mem/reg", 8)
	return address or 0x40000000 
end

-- Set Pull-Up or Pull-Down for a single pin or a table of pins
local gpio_pud=function(pin, pud)
	if pud:find("down") then 
		pud=PUD_DOWN 
	elseif pud:find("up") then
		pud=PUD_UP
	else
		pud=PUD_OFF
	end
	local bmcaddr=bcm_host_get_peripheral_address()
	local bmcsize=bcm_host_get_peripheral_size()
	local gpio_base = MMIO(bmcaddr+0x00200000, 4096)
		
	local clk={0,0}
	
	if type(pin)~="table" then
		pin={pin}
	end
	
	for i,p in ipairs(pin) do
		local offs=1
		if p>=32 then
			p=p-32
			offs=2
		end
		clk[offs]=clk[offs]+2^p
	end
	
	gpio_base:write32(37*4, pud)
	periphery.sleep_us(150)
	gpio_base:write32(38*4, clk[1] )
	gpio_base:write32(39*4, clk[2] )
	periphery.sleep_us(150)
	gpio_base:write32(37*4, 0)
	gpio_base:write32(38*4, 0)
	gpio_base:write32(39*4, 0)
	periphery.sleep_us(150)		
	
	gpio_base:close()
end

-- Extends periphery.GPIO
local gpio_bmc=function(pin,dir,pud)
	if type(pin)=="table" then	-- Special case: a table with PIN numbers
		gpio_pud(pin, pud)
		return nil
	else -- the default: configure a single PIN
		if pud then	
			gpio_pud(pin,pud)   		
		end
		return GPIO(pin,dir)
	end
end

return gpio_bmc
