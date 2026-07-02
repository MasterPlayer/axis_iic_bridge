set_property PACKAGE_PIN P15 [get_ports IIC_SDA]
set_property PACKAGE_PIN P16 [get_ports IIC_SCL]

set_property IOSTANDARD LVCMOS33 [get_ports IIC_SCL]
set_property IOSTANDARD LVCMOS33 [get_ports IIC_SDA]

create_pblock AXIS_IIC_BRIDGE_PBLOCK
resize_pblock AXIS_IIC_BRIDGE_PBLOCK -add {SLICE_X102Y50:SLICE_X113Y59 RAMB18_X5Y20:RAMB18_X5Y23 RAMB36_X5Y10:RAMB36_X5Y11}
add_cells_to_pblock AXIS_IIC_BRIDGE_PBLOCK [get_cells [list axis_iic_bridge_inst]]

set_property IOB TRUE [get_cells axis_iic_bridge_inst/o_scl_t_reg]
set_property IOB TRUE [get_cells axis_iic_bridge_inst/o_sda_t_reg]
set_property IOB TRUE [get_cells axis_iic_bridge_inst/scl_i_registered_reg]
set_property IOB TRUE [get_cells axis_iic_bridge_inst/sda_i_registered_reg]

