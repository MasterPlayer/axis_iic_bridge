# axis_iic_bridge
 FPGA implementation I2C bridge with support AXI-Stream protocol. There are proprietary protocol of data structure. Component might be used as submodule for provide IIC interface. 

## Catalog Structure
```
    axis_iic_interface      This repo 
    |-->prj                 Files for create Vivado Project
    |   |-->ips             IP cores for project
    |   |-->rtl             RTL sources required for project
    |   |-->sdk             
    |   |-->tcl             TCL sources for assembling or debug project
    |   |-->xdc             XDC constraints for project
    |
    |-->src_hw              RTL files of this repo
    |-->src_sw              software files for processor application
    |-->submodules          Directory for submodules for source files
    |-->testbench           Testbench sources, models etc.
```

## Project Assembling 
This project hardware-tested on MyIR Z-Turn Board with FPGA xc7z020-2clg400. 
### Assembling
for Vivado:
```
cd axis_iic_bridge/prj/tcl/
source axis_iic_bridge.tcl
```
Project assembling will be started, but runs is not started for this stage. Synthesis/Implementation runs from user action. 

### Debug in hardware
There are script for testing reading operation from IIC Device ADXL345 accelerometer. Reads will be fine. DEVICE_ID read correctly. 
For debug in hardware run this script: 
```
cd axis_iic_bridge/prj/tcl
source jtag_cmd_reading.tcl
```
There are ILA included in project. For reading data script automatically starting configuration one of ILA, create trigger in basic mode, perform transaction of AXI for reading data from ADXL345 device, and stop trigger after reading all register map in device with demonstration results on ILA. 

### Testbench
Testbench top-file : `tb_axis_iic_bridge`. this testbench perform writing and reading operations in slave imitation of device, named as `tb_slave_device_model`. 

## RTL description
Component works as master IIC with support AXI-Stream protocol for logic, IIC protocol for external connection. IOBUFs not involved and not presented in RTL-sources, you must insert this buffers manually on top-level. 

### Parameters 
There are some parameters for configuration
| Parameter name |   Default | Description |
|----------------|-----------|-------------|
| CLK_PERIOD     | 100000000 | input clock period, value in Hz. required for calculation internal counters |
| CLK_I2C_PERIOD | 400000    | I2C clock period, value in Hz. required for calculation internal counters and define IIC interface clocking
| DATA_WIDTH     | 8         | Width of AXI-Stream data in bits |
| WRITE_COUNTROL | "COUNTER" | Reserved parameter for future using |
| DEPTH          | 32        | Input and output fifo's depth |

### Input & Output
Component works on AXI-Stream interface, single clocked, with support TUSER and TKEEP, TLAST. 

| Signal group name | Width | Description  | 
|-------------------|-------|--------------|
| i_clk             | 1     | Clock signal |
| i_reset           | 1     | Syncronous reset signal |
| i_s_axis_*        | DATA_WIDTH | input AXI-Stream interface for perform sending data to IIC device. Reading and Writing operations on IIC interface determines on this bus. TUSER used for IIC addressation devices |
| o_m_axis_*        | DATA_WIDTH | output AXI-Stream interface for readed from IIC device data |
| o_scl_t           | 1 | signal used for direction of tri-state buffer, must be connected on T input of IOBUF. For iic this is clocking signal |
| o_sda_t           | 1 | signal used for direction of tri-state buffer, must be connected on T input of IOBUF. For IIC protocol this signal is DATA signal from master to slave | 
| i_scl_i           | 1 | signal from O output of IOBUF, for IIC protocol it is a clocking signal | 
| i_sda_i           | 1 | signal from O output of IOBUF, for IIC protocol it is a data signal from from device |

### Data protocol 
for DATA_WIDTH = 8 bytes first word on S_AXIS_ bus determines how must words will be sended(for write operation) or readed(for read operation) with slave device. In this case, first word is not transmit on IIC bus and used ONLY internally for data word counting. 

TODO : add pictures

### Limitations 
