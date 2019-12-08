onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib divider32_opt

do {wave.do}

view wave
view structure
view signals

do {divider32.udo}

run -all

quit -force
