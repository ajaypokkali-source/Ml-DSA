# Recreate a Vivado project from this repo (sources stay in rtl/ and tb/).
#
#   vivado -mode batch -source sim/create_vivado_project.tcl
#   (or in the Vivado Tcl console:  source sim/create_vivado_project.tcl)
#
# Then pick a testbench as the simulation top, e.g.
#   set_property top tb_poly_reduce [get_filesets sim_1]
#   launch_simulation
#
# NOTE: not run by its author yet; the original work was done in a hand-made project.
# The file tb/l4_modular/tb_montgomery_reduce__mult.v declares the module name
# "tb_montgomery" (not the file name) - use that name as the simulation top.

set root [file normalize [file join [file dirname [info script]] ..]]

create_project ML_DSA [file join $root vivado] -force

add_files -fileset sources_1 [glob -nocomplain [file join $root rtl * *.v]]
add_files -fileset sources_1 [file join $root rtl l3_memory rom_init.mem]
add_files -fileset sim_1     [glob -nocomplain [file join $root tb * *.v]]

set_property top tb_poly_reduce [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
