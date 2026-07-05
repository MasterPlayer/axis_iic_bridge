`timescale 1ps / 1ps

module tb_axis_iic_bridge_x1 ();


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
    logic                     o_scl_t                     ;
    logic                     o_sda_t                     ;

    integer index = 0;

    initial begin 
        clk = 1'b1;
        forever 
            #50000 clk = ~clk;
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

               20000 : begin s_axis_tdata <= 8'h38; s_axis_tuser <= 8'hA7; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

              200000 : begin s_axis_tdata <= 8'h01; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b0; end 
              200001 : begin s_axis_tdata <= 8'hAA; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

              210000 : begin s_axis_tdata <= 8'h08; s_axis_tuser <= 8'hA7; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

              250000 : begin s_axis_tdata <= 8'h01; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b0; end 
              250001 : begin s_axis_tdata <= 8'h55; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

              260000 : begin s_axis_tdata <= 8'h08; s_axis_tuser <= 8'hA7; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

              300000 : begin s_axis_tdata <= 8'h01; s_axis_tuser <= 8'hA7; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 
            
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







    parameter  CMD_CLK_PERIOD     = 100000000     ;
    parameter  CMD_CLK_I2C_PERIOD = 400000        ;
    parameter  CMD_DATA_WIDTH     = 8             ;
    parameter  CMD_DEPTH          = 32            ;
    parameter  CMD_SIZE_WIDTH     = 8             ;

    logic [               7:0] cmd_iic_addr = '{default:0};
    logic [CMD_SIZE_WIDTH-1:0] cmd_size     = '{default:0};
    logic                      cmd_valid    = 1'b0        ;

    logic [CMD_DATA_WIDTH-1:0] cmd_s_axis_tdata  = '{default:0};
    logic [               0:0] cmd_s_axis_tkeep  = '{default:0};
    logic                      cmd_s_axis_tlast  = 1'b0        ;
    logic                      cmd_s_axis_tvalid = 1'b0        ;
    logic                      cmd_s_axis_tready               ;

    logic [CMD_DATA_WIDTH-1:0] cmd_m_axis_tdata        ;
    logic [               0:0] cmd_m_axis_tkeep        ;
    logic                      cmd_m_axis_tlast        ;
    logic                      cmd_m_axis_tvalid       ;
    logic                      cmd_m_axis_tready = 1'b0;

    logic cmd_scl_i;
    logic cmd_sda_i;
    logic cmd_scl_t;
    logic cmd_sda_t;


    axis_iic_bridge_cmd #(
        .CLK_PERIOD    (CMD_CLK_PERIOD    ),
        .CLK_I2C_PERIOD(CMD_CLK_I2C_PERIOD),
        .DATA_WIDTH    (CMD_DATA_WIDTH    ),
        .DEPTH         (CMD_DEPTH         ),
        .SIZE_WIDTH    (CMD_SIZE_WIDTH    )
    ) axis_iic_bridge_cmd_inst (
        .i_clk          (clk              ),
        .i_reset        (reset            ),
        //
        .i_cmd_iic_addr (cmd_iic_addr     ),
        .i_cmd_size     (cmd_size         ),
        .i_cmd_valid    (cmd_valid        ),
        //
        .i_s_axis_tdata (cmd_s_axis_tdata ),
        .i_s_axis_tkeep (cmd_s_axis_tkeep ),
        .i_s_axis_tlast (cmd_s_axis_tlast ),
        .i_s_axis_tvalid(cmd_s_axis_tvalid),
        .o_s_axis_tready(cmd_s_axis_tready),
        //
        .o_m_axis_tdata (cmd_m_axis_tdata ),
        .o_m_axis_tkeep (cmd_m_axis_tkeep ),
        .o_m_axis_tlast (cmd_m_axis_tlast ),
        .o_m_axis_tvalid(cmd_m_axis_tvalid),
        .i_m_axis_tready(cmd_m_axis_tready),
        //
        .i_scl_i        (cmd_scl_i        ),
        .i_sda_i        (cmd_sda_i        ),
        .o_scl_t        (cmd_scl_t        ),
        .o_sda_t        (cmd_sda_t        )
    );

    always_comb cmd_m_axis_tready = 1'b1;

    tb_slave_device_model tb_slave_device_model_cmd_inst (
        .i_clk    (clk      ),
        .i_reset  (reset    ),
        .iic_scl_i(cmd_scl_t),
        .iic_sda_i(cmd_sda_t),
        .iic_scl_o(cmd_scl_i),
        .iic_sda_o(cmd_sda_i)
    );


    always_ff @(posedge clk) begin : cmd_s_axis_processing 

        case (index) 

                // 2000 : begin cmd_s_axis_tdata <= 8'h01; cmd_s_axis_tuser <= 8'hA6; cmd_s_axis_tkeep <= 1'b1; cmd_s_axis_tvalid <= 1'b1; cmd_s_axis_tlast <= 1'b0; end 
                2001 : begin cmd_s_axis_tdata <= 8'h81; cmd_s_axis_tkeep <= 1'b1; cmd_s_axis_tvalid <= 1'b1; cmd_s_axis_tlast <= 1'b1; end 
                2002 : begin cmd_s_axis_tdata <= 8'h82; cmd_s_axis_tkeep <= 1'b1; cmd_s_axis_tvalid <= 1'b1; cmd_s_axis_tlast <= 1'b1; end 

               // 20000 : begin s_axis_tdata <= 8'h38; s_axis_tuser <= 8'hA7; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

              // 200000 : begin s_axis_tdata <= 8'h01; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b0; end 
              // 200001 : begin s_axis_tdata <= 8'hAA; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

              // 210000 : begin s_axis_tdata <= 8'h08; s_axis_tuser <= 8'hA7; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

              // 250000 : begin s_axis_tdata <= 8'h01; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b0; end 
              // 250001 : begin s_axis_tdata <= 8'h55; s_axis_tuser <= 8'hA6; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

              // 260000 : begin s_axis_tdata <= 8'h08; s_axis_tuser <= 8'hA7; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 

              // 300000 : begin s_axis_tdata <= 8'h01; s_axis_tuser <= 8'hA7; s_axis_tkeep <= 1'b1; s_axis_tvalid <= 1'b1; s_axis_tlast <= 1'b1; end 
            
            default: begin cmd_s_axis_tdata <= cmd_s_axis_tdata; cmd_s_axis_tkeep <= cmd_s_axis_tkeep; cmd_s_axis_tvalid <= 1'b0; cmd_s_axis_tlast <= cmd_s_axis_tlast; end 

        endcase // index

    end 


    always_ff @(posedge clk) begin : cmd_processing 
        case (index)
               2000 : begin cmd_iic_addr <= 8'hA6; cmd_size <= 8'h01; cmd_valid <= 1'b1; end
               2001 : begin cmd_iic_addr <= 8'hA6; cmd_size <= 8'h01; cmd_valid <= 1'b1; end
              // 20000 : begin cmd_iic_addr <= 8'hA7; cmd_size <= 8'h38; cmd_valid <= 1'b1; end
            default : begin cmd_iic_addr <= cmd_iic_addr; cmd_size <= cmd_size; cmd_valid <= 1'b0; end
        endcase
    end 


endmodule