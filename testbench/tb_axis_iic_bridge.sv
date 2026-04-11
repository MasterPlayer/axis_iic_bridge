`timescale 1ps / 1ps

module tb_axis_iic_bridge ();


    parameter CLK_PERIOD     = 100000000 ;
    parameter CLK_I2C_PERIOD = 400000   ;
    parameter N_BYTES        = 1        ;
    parameter WRITE_CONTROL  = "COUNTER";
    parameter DEPTH          = 32       ;


    logic                     clk                         ;
    logic                     reset                       ;
    //
    logic [((N_BYTES*8)-1):0] s_axis_tdata  = '{default:0};
    logic [              7:0] s_axis_tuser  = '{default:0}; // tuser or tdest for addressation data
    logic [      N_BYTES-1:0] s_axis_tkeep  = '{default:0};
    logic                     s_axis_tvalid = 1'b0        ;
    logic                     s_axis_tready               ;
    logic                     s_axis_tlast  = 1'b0        ;
    //
    logic [((N_BYTES*8)-1):0] m_axis_tdata                ;
    logic [      N_BYTES-1:0] m_axis_tkeep                ;
    logic [              7:0] m_axis_tuser                ;
    logic                     m_axis_tvalid               ;
    logic                     m_axis_tready = 1'b0        ;
    logic                     m_axis_tlast                ;
    //
    logic                     i_scl_i                     ;
    logic                     i_sda_i                     ;
    logic                     o_scl_t                       ;
    logic                     o_sda_t                     ;

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

               2000 : begin s_axis_tdata <= 8'h01; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b0; end 
               2001 : begin s_axis_tdata <= 8'h81; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 
                // 202 : begin s_axis_tdata <= 8'h00; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

              20000 : begin s_axis_tdata <= 8'h38; s_axis_tuser <= 8'hA7; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

              200000 : begin s_axis_tdata <= 8'h01; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b0; end 
              200001 : begin s_axis_tdata <= 8'hAA; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

              210000 : begin s_axis_tdata <= 8'h08; s_axis_tuser <= 8'hA7; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

              250000 : begin s_axis_tdata <= 8'h01; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b0; end 
              250001 : begin s_axis_tdata <= 8'h55; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

              260000 : begin s_axis_tdata <= 8'h08; s_axis_tuser <= 8'hA7; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

            
            default: begin s_axis_tdata <= s_axis_tdata; s_axis_tuser <= s_axis_tuser; s_axis_tkeep <= s_axis_tkeep; s_axis_tvalid <= 1'b0; s_axis_tlast <= s_axis_tlast; end 

        endcase // index

    end 

    axis_iic_bridge #(
        .CLK_PERIOD    (CLK_PERIOD    ),
        .CLK_I2C_PERIOD(CLK_I2C_PERIOD),
        .DATA_WIDTH    ((N_BYTES*8)   ),
        .WRITE_CONTROL (WRITE_CONTROL ),
        .DEPTH         (DEPTH         )
    ) axis_iic_bridge_inst (
        .i_clk          (clk          ),
        .i_reset        (reset        ),
        .i_s_axis_tdata (s_axis_tdata ),
        .i_s_axis_tuser (s_axis_tuser ),   // tuser or tdest for addressation data
        .i_s_axis_tkeep (s_axis_tkeep ),
        .i_s_axis_tlast (s_axis_tlast ),
        .i_s_axis_tvalid(s_axis_tvalid),
        .o_s_axis_tready(s_axis_tready),
        .o_m_axis_tdata (m_axis_tdata ),
        .o_m_axis_tkeep (m_axis_tkeep ),
        .o_m_axis_tuser (m_axis_tuser ),
        .o_m_axis_tlast (m_axis_tlast ),
        .o_m_axis_tvalid(m_axis_tvalid),
        .i_m_axis_tready(m_axis_tready),
        .i_scl_i        (i_scl_i      ),
        .i_sda_i        (i_sda_i      ),
        .o_scl_t        (o_scl_t      ),
        .o_sda_t        (o_sda_t      )
    );

    always_comb m_axis_tready = 1'b1;

    tb_slave_device_model tb_slave_device_model_inst (
        .i_clk          ( clk         ),
        .i_reset        ( reset       ),
        .iic_scl_i      ( o_scl_t     ),
        .iic_sda_i      ( o_sda_t     ),
        .iic_scl_o      ( i_scl_i     ),
        .iic_sda_o      ( i_sda_i     ));

endmodule