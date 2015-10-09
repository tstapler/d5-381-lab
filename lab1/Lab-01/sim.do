# Start up the simulation
vsim -novopt work.quadratic 

# Set binary strings to be hex values (not needed for now)
set binopt {-logic}
set hexopt {-literal -hex}

# Divide up the wave window so signals are well labelled
eval add wave -noupdate -divider {"Quadratic"}
eval add wave sim:/quadratic/*

eval add wave -noupdate -divider {"g_mult1"}
eval add wave sim:/quadratic/g_mult1/*

eval add wave -noupdate -divider {"g_mult2"}
eval add wave sim:/quadratic/g_mult2/*

eval add wave -noupdate -divider {"g_mult3"}
eval add wave sim:/quadratic/g_mult3/*

eval add wave -noupdate -divider {"g_add1"}
eval add wave sim:/quadratic/g_add1/*

eval add wave -noupdate -divider {"g_add2"}
eval add wave sim:/quadratic/g_add2/*



# Force the clock value (default clock)
force -freeze sim:/quadratic/iclk 1 0, 0 {50 ns} -r 100



# 1. Force some input on iX
force -freeze sim:/quadratic/ix 5 0

# 2. Run (repeat steps 1-2)
run 400ns