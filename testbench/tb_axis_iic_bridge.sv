`timescale 1ps / 1ps

module tb_axis_iic_bridge ();


    parameter CLK_PERIOD     = 100000000;
    parameter CLK_I2C_PERIOD = 400000   ;
    parameter N_BYTES        = 1        ;
    parameter WRITE_CONTROL  = "COUNTER";
    parameter DEPTH          = 32       ;


    logic                     clk                         ;
    logic                     reset                       ;
    logic [((N_BYTES*8)-1):0] s_axis_tdata  = '{default:0};
    logic [              7:0] s_axis_tuser  = '{default:0}; // tuser or tdest for addressation data
    logic [      N_BYTES-1:0] s_axis_tkeep  = '{default:0};
    logic                     s_axis_tvalid = 1'b0        ;
    logic                     s_axis_tready               ;
    logic                     s_axis_tlast  = 1'b0        ;
    logic [((N_BYTES*8)-1):0] m_axis_tdata                ;
    logic [      N_BYTES-1:0] m_axis_tkeep                ;
    logic [              7:0] m_axis_tuser                ;
    logic                     m_axis_tvalid               ;
    logic                     m_axis_tready = 1'b0        ;
    logic                     m_axis_tlast                ;
    logic                     scl_i                       ;
    logic                     sda_i                       ;
    logic                     scl_t                       ;
    logic                     sda_t                       ;

    integer index = 0;

    initial begin 
        clk = 1'b1;
        forever 
            #5000 clk = ~clk;
    end 

    always_ff @(posedge clk) begin 
        index <= index + 1;
    end 

    always_ff @(posedge clk) begin : reset_processing 
        if (index < 100) begin 
            reset <= 1'b1;
        end else begin 
            reset <= 1'b0;
        end 
    end 

    always_ff @(posedge clk) begin : s_axis_processing 

        case (index) 

                200 : begin s_axis_tdata <= 8'h02; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b0; end 
                201 : begin s_axis_tdata <= 8'h00; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b0; end 
                // 202 : begin s_axis_tdata <= 8'h00; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

              20000 : begin s_axis_tdata <= 8'h08; s_axis_tuser <= 8'hA7; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 
            
            default: begin s_axis_tdata <= s_axis_tdata; s_axis_tuser <= s_axis_tuser; s_axis_tkeep <= s_axis_tkeep; s_axis_tvalid <= 1'b0; s_axis_tlast <= s_axis_tlast; end 

        endcase // index

    end 

    axis_iic_bridge #(
        .CLK_PERIOD    (CLK_PERIOD    ),
        .CLK_I2C_PERIOD(CLK_I2C_PERIOD),
        .N_BYTES       (N_BYTES       ),
        .WRITE_CONTROL (WRITE_CONTROL ),
        .DEPTH         (DEPTH         )
    ) axis_iic_bridge_inst (
        .clk          (clk          ),
        .reset        (reset        ),
        .s_axis_tdata (s_axis_tdata ),
        .s_axis_tuser (s_axis_tuser ),   // tuser or tdest for addressation data
        .s_axis_tkeep (s_axis_tkeep ),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast (s_axis_tlast ),
        .m_axis_tdata (m_axis_tdata ),
        .m_axis_tkeep (m_axis_tkeep ),
        .m_axis_tuser (m_axis_tuser ),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast (m_axis_tlast ),
        .scl_i        (scl_i        ),
        .sda_i        (sda_i        ),
        .scl_t        (scl_t        ),
        .sda_t        (sda_t        )
    );


    always_comb m_axis_tready = 1'b1;

    tb_slave_device_model tb_slave_device_model_inst (
        .IIC_SCL_I(scl_t),
        .IIC_SDA_I(sda_t),
        .IIC_SCL_O(scl_i),
        .IIC_SDA_O(sda_i)
    );
    
    // wire scl;
    // wire sda;

    // IOBUF #(
    //     .DRIVE       (24       ),   // Specify the output drive strength
    //     .IBUF_LOW_PWR("TRUE"   ),   // Low Power - "TRUE", High Performance = "FALSE"
    //     .IOSTANDARD  ("DEFAULT"),   // Specify the I/O standard
    //     .SLEW        ("SLOW"   )    // Specify the output slew rate
    // ) iobuf_bridge_scl_inst (
    //     .O (scl_i),   // Buffer output
    //     .IO(scl  ),   // Buffer inout port (connect directly to top-level port)
    //     .I (1'b0 ),   // Buffer input
    //     .T (scl_t)    // 3-state enable input, high=input, low=output
    // );


    // IOBUF #(
    //     .DRIVE       (12       ),   // Specify the output drive strength
    //     .IBUF_LOW_PWR("TRUE"   ),   // Low Power - "TRUE", High Performance = "FALSE"
    //     .IOSTANDARD  ("DEFAULT"),   // Specify the I/O standard
    //     .SLEW        ("SLOW"   )    // Specify the output slew rate
    // ) iobuf_bridge_sda_inst (
    //     .O (sda_i),   // Buffer output
    //     .IO(sda  ),   // Buffer inout port (connect directly to top-level port)
    //     .I (1'b0 ),   // Buffer input
    //     .T (sda_t)    // 3-state enable input, high=input, low=output
    // );

endmodule