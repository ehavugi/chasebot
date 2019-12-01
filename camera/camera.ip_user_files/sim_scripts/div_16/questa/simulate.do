onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib div_16_opt

do {wave.do}

view wave
view structure
view signals

do {div_16.udo}

run -all

quit -force
