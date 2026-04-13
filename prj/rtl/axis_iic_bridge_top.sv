`timescale 1ns / 1ps


module axis_iic_bridge_top (
    inout logic [14:0] DDR_ADDR         ,
    inout logic [ 2:0] DDR_BA           ,
    inout logic        DDR_CAS_N        ,
    inout logic        DDR_CK_N         ,
    inout logic        DDR_CK_P         ,
    inout logic        DDR_CKE          ,
    inout logic        DDR_CS_N         ,
    inout logic [ 3:0] DDR_DM           ,
    inout logic [31:0] DDR_DQ           ,
    inout logic [ 3:0] DDR_DQS_N        ,
    inout logic [ 3:0] DDR_DQS_P        ,
    inout logic        DDR_ODT          ,
    inout logic        DDR_RAS_N        ,
    inout logic        DDR_RESET_N      ,
    inout logic        DDR_WE_N         ,
    inout logic        FIXED_IO_DDR_VRN ,
    inout logic        FIXED_IO_DDR_VRP ,
    inout logic [53:0] FIXED_IO_MIO     ,
    inout logic        FIXED_IO_PS_CLK  ,
    inout logic        FIXED_IO_PS_PORB ,
    inout logic        FIXED_IO_PS_SRSTB,
    inout logic        IIC_SDA          ,
    inout logic        IIC_SCL
);

    logic clk_100;

    logic reset;

    logic [7:0] s_axis_tdata ;
    logic [7:0] s_axis_tuser ; // tuser or tdest for addressation data
    logic       s_axis_tlast ;
    logic       s_axis_tvalid;
    logic       s_axis_tready;

    //
    logic [7:0] i_s_axis_tdata ;
    logic [7:0] i_s_axis_tuser ; // tuser or tdest for addressation data
    logic [0:0] i_s_axis_tkeep ;
    logic       i_s_axis_tlast ;
    logic       i_s_axis_tvalid;
    logic       o_s_axis_tready;
    //
    logic [7:0] o_m_axis_tdata ;
    logic [0:0] o_m_axis_tkeep ;
    logic [7:0] o_m_axis_tuser ;
    logic       o_m_axis_tlast ;
    logic       o_m_axis_tvalid;
    logic       i_m_axis_tready;
    //
    logic sda_i;
    logic scl_i;
    logic sda_t;
    logic scl_t;

    IOBUF #(
        .DRIVE       (12       ),   // Specify the output drive strength
        .IBUF_LOW_PWR("TRUE"   ),   // Low Power - "TRUE", High Performance = "FALSE"
        .IOSTANDARD  ("DEFAULT"),   // Specify the I/O standard
        .SLEW        ("SLOW"   )    // Specify the output slew rate
    ) iobuf_iic_sda_inst (
        .O (sda_i  ),   // Buffer output
        .IO(IIC_SDA),   // Buffer inout port (connect directly to top-level port)
        .I (1'b0   ),   // Buffer input
        .T (sda_t  )    // 3-state enable input, high=input, low=output
    );

    IOBUF #(
        .DRIVE       (12       ),   // Specify the output drive strength
        .IBUF_LOW_PWR("TRUE"   ),   // Low Power - "TRUE", High Performance = "FALSE"
        .IOSTANDARD  ("DEFAULT"),   // Specify the I/O standard
        .SLEW        ("SLOW"   )    // Specify the output slew rate
    ) iobuf_iic_scl_inst (
        .O (scl_i  ),   // Buffer output
        .IO(IIC_SCL),   // Buffer inout port (connect directly to top-level port)
        .I (1'b0   ),   // Buffer input
        .T (scl_t  )    // 3-state enable input, high=input, low=output
    );

    zynq_bd_wrapper zynq_bd_wrapper_inst (
        .DDR_addr         (DDR_ADDR         ),
        .DDR_ba           (DDR_BA           ),
        .DDR_cas_n        (DDR_CAS_N        ),
        .DDR_ck_n         (DDR_CK_N         ),
        .DDR_ck_p         (DDR_CK_P         ),
        .DDR_cke          (DDR_CKE          ),
        .DDR_cs_n         (DDR_CS_N         ),
        .DDR_dm           (DDR_DM           ),
        .DDR_dq           (DDR_DQ           ),
        .DDR_dqs_n        (DDR_DQS_N        ),
        .DDR_dqs_p        (DDR_DQS_P        ),
        .DDR_odt          (DDR_ODT          ),
        .DDR_ras_n        (DDR_RAS_N        ),
        .DDR_reset_n      (DDR_RESET_N      ),
        .DDR_we_n         (DDR_WE_N         ),
        .FIXED_IO_ddr_vrn (FIXED_IO_DDR_VRN ),
        .FIXED_IO_ddr_vrp (FIXED_IO_DDR_VRP ),
        .FIXED_IO_mio     (FIXED_IO_MIO     ),
        .FIXED_IO_ps_clk  (FIXED_IO_PS_CLK  ),
        .FIXED_IO_ps_porb (FIXED_IO_PS_PORB ),
        .FIXED_IO_ps_srstb(FIXED_IO_PS_SRSTB),
        .clk_100          (clk_100          )
    );

    logic d_s_axis_tvalid;
    logic s_axis_tvalid_event;

    vio_axis_iic_bridge vio_axis_iic_bridge_inst (
        .clk       (clk_100      ),   // input wire clk
        .probe_out0(reset        ),   // output wire [0 : 0] probe_out0
        .probe_out1(s_axis_tdata ),   // output wire [7 : 0] probe_out1
        .probe_out2(s_axis_tuser ),   // output wire [7 : 0] probe_out2
        .probe_out3(s_axis_tlast ),   // output wire [0 : 0] probe_out3
        .probe_out4(s_axis_tvalid)    // output wire [0 : 0] probe_out4
    );

    always_ff @(posedge clk_100) begin : d_s_axis_tvalid_processing 
        d_s_axis_tvalid <= s_axis_tvalid;
    end 

    always_comb s_axis_tvalid_event = s_axis_tvalid & ~d_s_axis_tvalid;

    axis_fifo_pkt axis_fifo_pkt_inst (
        .wr_rst_busy  (                   ),   // output wire wr_rst_busy
        .rd_rst_busy  (                   ),   // output wire rd_rst_busy
        .s_aclk       (clk_100            ),   // input wire s_aclk
        .s_aresetn    (~reset             ),   // input wire s_aresetn
        .s_axis_tdata (s_axis_tdata       ),   // input wire [7 : 0] s_axis_tdata
        .s_axis_tkeep (1'b1               ),   // input wire [0 : 0] s_axis_tkeep
        .s_axis_tuser (s_axis_tuser       ),   // input wire [7 : 0] s_axis_tuser
        .s_axis_tlast (s_axis_tlast       ),   // input wire s_axis_tlast
        .s_axis_tvalid(s_axis_tvalid_event),   // input wire s_axis_tvalid
        .s_axis_tready(s_axis_tready      ),   // output wire s_axis_tready
        .m_axis_tdata (i_s_axis_tdata     ),   // output wire [7 : 0] m_axis_tdata
        .m_axis_tuser (i_s_axis_tuser     ),   // output wire [7 : 0] m_axis_tuser
        .m_axis_tkeep (i_s_axis_tkeep     ),   // output wire [0 : 0] m_axis_tkeep
        .m_axis_tlast (i_s_axis_tlast     ),   // output wire m_axis_tlast
        .m_axis_tvalid(i_s_axis_tvalid    ),   // output wire m_axis_tvalid
        .m_axis_tready(o_s_axis_tready    )
    );

    axis_iic_bridge #(
        .CLK_PERIOD    (100000000),
        .CLK_I2C_PERIOD(400000   ),
        .DATA_WIDTH    (8        ),
        .WRITE_CONTROL ("COUNTER"),
        .DEPTH         (32       )
    ) axis_iic_bridge_inst (
        .i_clk          (clk_100        ),
        .i_reset        (reset          ),
        //
        .i_s_axis_tdata (i_s_axis_tdata ),
        .i_s_axis_tuser (i_s_axis_tuser ),
        .i_s_axis_tkeep (i_s_axis_tkeep ),
        .i_s_axis_tlast (i_s_axis_tlast ),
        .i_s_axis_tvalid(i_s_axis_tvalid),
        .o_s_axis_tready(o_s_axis_tready),
        //
        .o_m_axis_tdata (o_m_axis_tdata ),
        .o_m_axis_tkeep (               ),
        .o_m_axis_tuser (o_m_axis_tuser ),
        .o_m_axis_tlast (o_m_axis_tlast ),
        .o_m_axis_tvalid(o_m_axis_tvalid),
        .i_m_axis_tready(1'b1           ),
        //
        .i_scl_i        (scl_i          ),
        .i_sda_i        (sda_i          ),
        .o_scl_t        (scl_t          ),
        .o_sda_t        (sda_t          )
    );

    ila_axis ila_axis_to_iic (
        .clk   (clk_100        ),   // input wire clk
        .probe0(i_s_axis_tdata ),   // input wire [7:0]  probe0
        .probe1(i_s_axis_tuser ),   // input wire [7:0]  probe1
        .probe2(i_s_axis_tlast ),   // input wire [0:0]  probe2
        .probe3(i_s_axis_tvalid)    // input wire [0:0]  probe3
    );


    ila_axis ila_axis_from_iic (
        .clk   (clk_100        ),   // input wire clk
        .probe0(o_m_axis_tdata ),   // input wire [7:0]  probe0
        .probe1(o_m_axis_tuser ),   // input wire [7:0]  probe1
        .probe2(o_m_axis_tlast ),   // input wire [0:0]  probe2
        .probe3(o_m_axis_tvalid)    // input wire [0:0]  probe3
    );


endmodule
