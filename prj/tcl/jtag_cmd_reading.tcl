# Set Number of bytes for reading operation 0x39 bytes from device
set_property OUTPUT_VALUE 39 [get_hw_probes s_axis_tdata -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"vio_axis_iic_bridge_inst"}]]
commit_hw_vio [get_hw_probes {s_axis_tdata} -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"vio_axis_iic_bridge_inst"}]]
# Set Address 0xA7 for reading from ADXL345
set_property OUTPUT_VALUE A7 [get_hw_probes s_axis_tuser -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"vio_axis_iic_bridge_inst"}]]
commit_hw_vio [get_hw_probes {s_axis_tuser} -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"vio_axis_iic_bridge_inst"}]]
# Pefrorm reset component
startgroup
set_property OUTPUT_VALUE 1 [get_hw_probes reset -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"vio_axis_iic_bridge_inst"}]]
commit_hw_vio [get_hw_probes {reset} -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"vio_axis_iic_bridge_inst"}]]
endgroup
# Release reset
startgroup
set_property OUTPUT_VALUE 0 [get_hw_probes reset -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"vio_axis_iic_bridge_inst"}]]
commit_hw_vio [get_hw_probes {reset} -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"vio_axis_iic_bridge_inst"}]]
endgroup

#set TLAST for first byte
startgroup
set_property OUTPUT_VALUE 1 [get_hw_probes s_axis_tlast -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"vio_axis_iic_bridge_inst"}]]
commit_hw_vio [get_hw_probes {s_axis_tlast} -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"vio_axis_iic_bridge_inst"}]]
endgroup

# Trigger tuning for capturing data
set_property TRIGGER_COMPARE_VALUE eq1'b1 [get_hw_probes o_m_axis_tvalid -of_objects [get_hw_ilas -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"ila_axis_from_iic"}]]
set_property CONTROL.CAPTURE_MODE BASIC [get_hw_ilas -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"ila_axis_from_iic"}]
set_property CONTROL.TRIGGER_POSITION 0 [get_hw_ilas -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"ila_axis_from_iic"}]
set_property CAPTURE_COMPARE_VALUE eq1'b1 [get_hw_probes o_m_axis_tvalid -of_objects [get_hw_ilas -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"ila_axis_from_iic"}]]

run_hw_ila [get_hw_ilas -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"ila_axis_from_iic"}]
# create pulse for 1 clock period on S_AXIS_ bus for write 1 byte packet to FIFO
startgroup
set_property OUTPUT_VALUE 1 [get_hw_probes s_axis_tvalid -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"vio_axis_iic_bridge_inst"}]]
commit_hw_vio [get_hw_probes {s_axis_tvalid} -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"vio_axis_iic_bridge_inst"}]]
endgroup
# 
wait_on_hw_ila -timeout 0 [get_hw_ilas -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"ila_axis_from_iic"}]
# stop trigger
display_hw_ila_data [upload_hw_ila_data [get_hw_ilas -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"ila_axis_from_iic"}]]
# release valid signal 
set_property OUTPUT_VALUE 0 [get_hw_probes s_axis_tvalid -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"vio_axis_iic_bridge_inst"}]]
commit_hw_vio [get_hw_probes {s_axis_tvalid} -of_objects [get_hw_vios -of_objects [get_hw_devices xc7z020_1] -filter {CELL_NAME=~"vio_axis_iic_bridge_inst"}]]
endgroup
