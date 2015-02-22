# lua-gpio-bcm2708
An extension for lua-periphery GPIO, especially for the RaspberryPi.

Requires lua-periphery: https://github.com/vsergeev/lua-periphery
and adds the option to activate pull-up or pull-down resistors when opening GPIO as inputs.

Example:

    local GPIO=require"gpio_bcm2708"
    
    local gpio17=GPIO(17, "in", "down")
    local gpio7=GPIO(7, "in", "up")
    local gpio23=GPIO(23, "in", "off")
    local gpio3=GPIO(3, "out")

