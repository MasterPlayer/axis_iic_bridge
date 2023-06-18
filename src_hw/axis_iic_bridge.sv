`timescale 1ns / 1ps


module axis_iic_bridge #(
    parameter CLK_PERIOD     = 100000000,
    parameter CLK_I2C_PERIOD = 25000000 ,
    parameter N_BYTES        = 32       ,
    parameter WRITE_CONTROL  = "COUNTER",
    parameter DEPTH          = 32        
) (
    input  logic                     clk          ,
    input  logic                     reset        ,
    
    input  logic [((N_BYTES*8)-1):0] s_axis_tdata ,
    input  logic [              7:0] s_axis_tuser , // tuser or tdest for addressation data
    input  logic [      N_BYTES-1:0] s_axis_tkeep ,
    input  logic                     s_axis_tvalid,
    output logic                     s_axis_tready,
    input  logic                     s_axis_tlast ,

    output logic [((N_BYTES*8)-1):0] m_axis_tdata ,
    output logic [      N_BYTES-1:0] m_axis_tkeep ,
    output logic [              7:0] m_axis_tuser ,
    output logic                     m_axis_tvalid,
    input  logic                     m_axis_tready,
    output logic                     m_axis_tlast ,
    
    input  logic                     scl_i        ,
    input  logic                     sda_i        ,
    output logic                     scl_t        ,
    output logic                     sda_t
);

    
    localparam DURATION      = (CLK_PERIOD/CLK_I2C_PERIOD);
    localparam DURATION_DIV2 = ((DURATION)/2)-1           ;
    localparam DURATION_DIV4 = ((DURATION)/4)             ;
    localparam DATA_WIDTH    = (N_BYTES*8)                ;

    logic [$clog2(DURATION)-1:0] duration_cnt         = '{default:0};
    logic [$clog2(DURATION)-1:0] duration_cnt_shifted = '{default:0};
    logic                        has_event            = 1'b0        ;
    logic                        allow_counting       = 1'b0        ;
    logic                        clk_assert           = 1'b0        ;
    logic                        clk_deassert         = 1'b0        ;
    logic [                 2:0] bit_cnt              = '{default:0};
    logic                        has_ack              = 1'b0        ;

    logic d_scl_i     = 1'b1;
    logic scl_i_event = 1'b0;

    logic [                7:0] i2c_address       = '{default:0};
    logic [   (DATA_WIDTH-1):0] transmission_size = '{default:0};
    logic [$clog2(N_BYTES)-1:0] word_byte_counter = '{default:0};

    /* status registers*/
    logic bad_transmission_flaq = 1'b0;
    logic aborted_flaq          = 1'b0;
    logic byte_transmitted_flaq = 1'b0;

    logic                    has_read_op           = 1'b0;
    logic                    has_nack_required     = 1'b0;

    logic                    last_reached_flaq      = 1'b0;
    /*perform swap for input data stream*/
    logic [(DATA_WIDTH-1):0] s_axis_tdata_swap           ;

    logic [(DATA_WIDTH-1):0] in_dout_data                     ;
    logic [(DATA_WIDTH-1):0] in_dout_data_shift = '{default:0};
    logic [   (N_BYTES-1):0] in_dout_keep                     ;
    logic [             7:0] in_dout_user                     ;
    logic                    in_dout_last                     ;
    logic                    in_rden            = 1'b0        ;
    logic                    in_empty                         ;

    logic [N_BYTES-1:0][7:0] out_din_data = '{default:0};
    logic [N_BYTES-1:0]      out_din_keep = '{default:0};
    logic [        7:0]      out_din_user = '{default:0};
    logic                    out_din_last = 1'b0        ;
    logic                    out_wren     = 1'b0        ;
    logic                    out_full                   ;
    logic                    out_awfull                 ;

    logic d_sda_i;
    logic has_bus_busy = 1'b0;

    typedef enum {
        IDLE_ST,
        START_ST,
        TX_ADDR_ST,
        WAIT_ACK_ST,
        WRITE_ST,
        WAIT_WRITE_ACK_ST,
        READ_ST,
        WAIT_READ_ACK_ST,
        STOP_ST,
        AWAIT_OTHER_MASTER_ST,
        FLUSH_ST 
    } fsm;

    fsm current_state = IDLE_ST;

    
    for (genvar index = 0; index < N_BYTES; index++) begin : GEN_S_AXIS_TDATA_SWAP
        // high = (((n_bytes)-index)*8)-1;
        // low = (((n_bytes-1)-index)*8);
        // high_ = ((index+1)*8)-1;
        // low_ = (index*8);
        always_comb begin
            s_axis_tdata_swap[((N_BYTES-index)*8)-1:(((N_BYTES-1)-index)*8)] = s_axis_tdata[(((index+1)*8)-1):(index*8)];
        end

    end 

    always_ff @(posedge clk) begin 
        if (in_rden) begin 
            if (in_dout_last)
                last_reached_flaq <= 1'b1;
            else
                last_reached_flaq <= 1'b0;
        end 
    end 

    always_ff @(posedge clk) begin 
        case (current_state)
            WAIT_ACK_ST : 
                if (clk_assert) begin 
                    if (sda_i) begin 
                        bad_transmission_flaq <= 1'b1;
                    end else begin 
                        bad_transmission_flaq <= 1'b0;
                    end 
                end else begin 
                    bad_transmission_flaq <= 1'b0;
                end 

            default : 
                bad_transmission_flaq <= 1'b0;

        endcase
    end 

    always_ff @(posedge clk) begin 
        if (has_event) begin 
            case (current_state) 
                WAIT_WRITE_ACK_ST : // TO DO : probably in this state fsm goes to FLUSH, if no ACK flaq received
                    if (has_ack)  
                        byte_transmitted_flaq <= 1'b1;
                    else 
                        byte_transmitted_flaq <= 1'b0;

                default : 
                    byte_transmitted_flaq <= 1'b0;
            
            endcase // current_state
        end else begin  
            byte_transmitted_flaq <= 1'b0;
        end 
    end 

    always_ff @(posedge clk) begin 
        if (duration_cnt < (DURATION-1)) 
            duration_cnt <= duration_cnt + 1;
        else 
            duration_cnt <= '{default:0};
    end 

    always_ff @(posedge clk) begin 
        if (duration_cnt == (DURATION_DIV4))
            allow_counting <= 1'b1;
    end 

    always_ff @(posedge clk) begin 
        if (allow_counting) 
            if (duration_cnt_shifted < (DURATION-1)) begin 
                duration_cnt_shifted <= duration_cnt_shifted + 1;
            end else begin 
                duration_cnt_shifted <= '{default:0};
            end 
    end 

    always_ff @(posedge clk) begin 
        if (duration_cnt == (DURATION-1)) 
            has_event <= 1'b1;
        else 
            has_event <= 1'b0;
    end 

    always_ff @(posedge clk) begin 
        if (duration_cnt_shifted == (DURATION_DIV2)) 
            clk_deassert <= 1'b1;
        else 
            clk_deassert <= 1'b0;
    end 

    always_ff @(posedge clk) begin 
        if (duration_cnt_shifted == (DURATION-1)) 
            clk_assert <= 1'b1;
        else 
            clk_assert <= 1'b0;
    end 

    always_ff @(posedge clk) begin 
        case (current_state) 
            IDLE_ST : 
                scl_t <= 1'b1;

            START_ST : 
                if (clk_assert) 
                    scl_t <= 1'b0;

            TX_ADDR_ST: 
                if (duration_cnt_shifted == (DURATION-1))
                    scl_t <= 1'b1;
                else if (duration_cnt_shifted == DURATION_DIV2) 
                    scl_t <= 1'b0;

            WAIT_ACK_ST: 
                if (duration_cnt_shifted == (DURATION-1))
                    scl_t <= 1'b1;
                else if (duration_cnt_shifted == DURATION_DIV2) 
                    scl_t <= 1'b0;

            WRITE_ST : 
                if (duration_cnt_shifted == (DURATION-1))
                    scl_t <= 1'b1;
                else if (duration_cnt_shifted == DURATION_DIV2) 
                    scl_t <= 1'b0;

            WAIT_WRITE_ACK_ST : 
                if (duration_cnt_shifted == (DURATION-1))
                    scl_t <= 1'b1;
                else if (duration_cnt_shifted == DURATION_DIV2) 
                    scl_t <= 1'b0;

            READ_ST : 
                if (duration_cnt_shifted == (DURATION-1))
                    scl_t <= 1'b1;
                else if (duration_cnt_shifted == DURATION_DIV2) 
                    scl_t <= 1'b0;

            WAIT_READ_ACK_ST : 
                if (duration_cnt_shifted == (DURATION-1))
                    scl_t <= 1'b1;
                else if (duration_cnt_shifted == DURATION_DIV2) 
                    scl_t <= 1'b0;

            STOP_ST : 
                if (clk_assert)
                    scl_t <= 1'b1;

            default : 
                scl_t <= 1'b1;
        endcase // current_state_
    end 



    always_ff @(posedge clk) begin 
        if (has_event)
            case (current_state)
                FLUSH_ST : 
                    aborted_flaq <= 1'b1;

                default : 
                    aborted_flaq <= 1'b0;

            endcase // current_state
    end

    

    always_ff @(posedge clk) begin 
        if (has_event) begin 
            case (current_state)
                IDLE_ST : 
                    if (!in_empty) begin 
                        if (in_dout_data) begin 
                            sda_t <= 1'b0;
                        end else begin 
                            sda_t <= 1'b1;
                        end 
                    end else begin  
                        sda_t <= 1'b1;
                    end 

                START_ST : 
                    sda_t <= i2c_address[7];

                TX_ADDR_ST : 
                    if (bit_cnt) begin 
                        sda_t <= i2c_address[7];
                    end else begin 
                        sda_t <= 1'b1;
                    end 

                WAIT_ACK_ST : 
                    if (has_read_op) begin 
                        // if read operation
                        sda_t <= 1'b1;
                    end else begin 
                        sda_t <= in_dout_data_shift[(DATA_WIDTH-1)];
                    end 

                WRITE_ST :
                    if (bit_cnt) 
                        sda_t <= in_dout_data_shift[(DATA_WIDTH-1)]; //TO DO : Here is data
                    else
                        sda_t <= 1'b1;

                WAIT_WRITE_ACK_ST : 
                    sda_t <= in_dout_data_shift[(DATA_WIDTH-1)]; //TO DO : Here is data

                READ_ST : 
                    if (bit_cnt) 
                        sda_t <= 1'b1;
                    else begin 
                        if (has_nack_required)
                            sda_t <= 1'b1;
                        else 
                            sda_t <= 1'b0;
                    end 

                WAIT_READ_ACK_ST: 
                    if (transmission_size)
                        sda_t <= 1'b1;
                    else 
                        sda_t <= 1'b0;

                default : 
                    sda_t <= 1'b1;

            endcase
        end 
    end 

    always_ff @(posedge clk) begin 
        if (reset) begin 
            current_state <= IDLE_ST;
        end else begin 

            if (has_event) begin 
                case (current_state)
                    IDLE_ST : 
                        if (!has_bus_busy) begin  
                            if (!in_empty) begin
                                if (in_dout_data) begin // number of bytes has presented
                                    current_state <= START_ST;
                                end 
                            end 
                        end else begin 
                            current_state <= AWAIT_OTHER_MASTER_ST;
                        end 

                    // State where input buffer was erase because transaction was aborted
                    FLUSH_ST: 
                        if (last_reached_flaq) 
                            current_state <= IDLE_ST;

                    START_ST : 
                        current_state <= TX_ADDR_ST;

                    // transmit i2c address + r/w bit
                    TX_ADDR_ST : 
                        if (!bit_cnt) 
                            current_state <= WAIT_ACK_ST;

                    // wait from device ACK signal,
                    WAIT_ACK_ST : 
                        if (has_ack) begin 
                            if (has_read_op) begin 
                                current_state <= READ_ST;
                            end else begin 
                                current_state <= WRITE_ST;
                            end 
                        end else begin 
                            current_state <= FLUSH_ST;
                        end 

                    WRITE_ST : 
                        if (!bit_cnt) 
                            current_state <= WAIT_WRITE_ACK_ST;

                    WAIT_WRITE_ACK_ST : // TO DO : probably in this state fsm goes to FLUSH, if no ACK flaq received
                        if (has_ack)  
                            if (transmission_size) begin 
                                current_state <= WRITE_ST;
                            end else begin 
                                current_state <= STOP_ST;
                            end 
                    
                    READ_ST : 
                        if (!bit_cnt) 
                            current_state <= WAIT_READ_ACK_ST;

                    WAIT_READ_ACK_ST : 
                        if (transmission_size)
                            current_state <= READ_ST;
                        else 
                            current_state <= STOP_ST;

                    STOP_ST :
                        current_state <= IDLE_ST;

                    AWAIT_OTHER_MASTER_ST : 
                        if (!has_bus_busy)
                            current_state <= IDLE_ST;

                    default: 
                        current_state <= current_state;
                endcase 
            end else begin 
                current_state <= current_state;
            end 
        end 
    end 

    always_ff @(posedge clk) begin
        if (has_event)
            case (current_state) 
                IDLE_ST : 
                    i2c_address <= in_dout_user;

                START_ST : 
                    i2c_address <= {i2c_address[6:0], 1'b0};
                
                TX_ADDR_ST : 
                    i2c_address <= {i2c_address[6:0], 1'b0};

                default: 
                    i2c_address <= i2c_address;
            endcase
    end

    always_ff @(posedge clk) begin 
        if (has_event)
            case (current_state)
                IDLE_ST : 
                    has_read_op <= in_dout_user[0];

                default: 
                    has_read_op <= has_read_op;
            endcase // current_state
    end 

    always_ff @(posedge clk) begin 
        if (has_event) begin 
            case (current_state) 

                TX_ADDR_ST : 
                    bit_cnt <= bit_cnt - 1;

                WRITE_ST : 
                    bit_cnt <= bit_cnt - 1;

                READ_ST : 
                    bit_cnt <= bit_cnt - 1;

                default : 
                    bit_cnt <= 7;
            endcase // current_state
        end 
    end 

    always_ff @(posedge clk) begin 
        case (current_state)
            WAIT_ACK_ST : 
                if (clk_assert) begin 
                    if (!sda_i) begin 
                        has_ack <= 1'b1;
                    end else begin   
                        has_ack <= 1'b0;
                    end 
                end 

            WAIT_WRITE_ACK_ST : 
                if (clk_assert) begin 
                    if (!sda_i) begin 
                        has_ack <= 1'b1;
                    end else begin   
                        has_ack <= 1'b0;
                    end 
                end 

            default: 
                has_ack <= 1'b0;

        endcase // current_state
    end 

    fifo_in_sync_user_xpm #(
        .DATA_WIDTH(DATA_WIDTH),
        .USER_WIDTH(8         ),
        .MEMTYPE   ("block"   ),
        .DEPTH     (DEPTH     )
    ) fifo_in_sync_user_xpm_inst (
        .CLK          (clk              ),
        .RESET        (reset            ),
        .S_AXIS_TDATA (s_axis_tdata_swap),
        .S_AXIS_TKEEP (s_axis_tkeep     ),
        .S_AXIS_TUSER (s_axis_tuser     ),
        .S_AXIS_TVALID(s_axis_tvalid    ),
        .S_AXIS_TREADY(s_axis_tready    ),
        .S_AXIS_TLAST (s_axis_tlast     ),
        .IN_DOUT_DATA (in_dout_data     ),
        .IN_DOUT_KEEP (in_dout_keep     ),
        .IN_DOUT_USER (in_dout_user     ),
        .IN_DOUT_LAST (in_dout_last     ),
        .IN_RDEN      (in_rden          ),
        .IN_EMPTY     (in_empty         )
    );

    always_ff @(posedge clk) begin 
        if (has_event) begin 
            case (current_state)
                TX_ADDR_ST : 
                    if (!bit_cnt) 
                        in_dout_data_shift <= in_dout_data;
                
                WAIT_ACK_ST : 
                    in_dout_data_shift <= {in_dout_data_shift[DATA_WIDTH-2:0], 1'b0};

                WRITE_ST : 
                    if (bit_cnt)
                        in_dout_data_shift <= {1'b0, in_dout_data_shift[DATA_WIDTH-2:0], 1'b0};
                    else 
                        if (word_byte_counter == (N_BYTES-1)) 
                            in_dout_data_shift <= in_dout_data;

                WAIT_WRITE_ACK_ST: 
                    in_dout_data_shift <= {in_dout_data_shift[DATA_WIDTH-2:0], 1'b0};

                default: 
                    in_dout_data_shift <= in_dout_data_shift;
            endcase // current_state
        end 
    end 

    /*Read Enable signal for input fifo*/
    always_ff @(posedge clk) begin : in_rden_processing
        if (has_event) begin  
            case (current_state) 
                IDLE_ST : 
                    if (!in_empty)
                        in_rden <= 1'b1;
                    else 
                        in_rden <= 1'b0;

                TX_ADDR_ST : 
                    if (!bit_cnt)
                        in_rden <= ~has_read_op;
                    else 
                        in_rden <= 1'b0;

                FLUSH_ST : 
                    in_rden <= ~last_reached_flaq;

                WRITE_ST : 
                    if (!bit_cnt)
                        if (word_byte_counter == (N_BYTES-1))
                            if (transmission_size)
                                in_rden <= 1'b1;
                            else
                                in_rden <= 1'b0;
                        else
                            in_rden <= 1'b0;
                    else 
                        in_rden <= 1'b0;

                default : in_rden <= 1'b0;
            endcase
        end else begin 
            in_rden <= 1'b0;
        end 
    end 

    always_ff @(posedge clk) begin : word_byte_counter_proc
        if (has_event) 
            case (current_state)

                IDLE_ST : 
                    word_byte_counter <= '{default:0};

                WRITE_ST : 
                    if (!bit_cnt)
                        if (word_byte_counter == (N_BYTES-1))
                            word_byte_counter <= '{default:0};
                        else 
                            word_byte_counter <= word_byte_counter + 1;

                READ_ST :
                    if (!bit_cnt)
                        if (word_byte_counter == (N_BYTES-1)) 
                            word_byte_counter <= '{default:0};
                        else 
                            word_byte_counter <= word_byte_counter + 1;


                default: 
                    word_byte_counter <= word_byte_counter;

            endcase // current_state
    end 


    for (genvar index = 0; index < N_BYTES; index++) begin : GEN_SWAP_TRANSMISSION_SIZE
        always_ff @(posedge clk) begin
            if (has_event) begin 
                case (current_state) 
                    IDLE_ST: 
                        if (!in_empty)
                            transmission_size[((N_BYTES-index)*8)-1:(((N_BYTES-1)-index)*8)] <= in_dout_data[(((index+1)*8)-1):(index*8)];

                    WAIT_ACK_ST : 
                        transmission_size <= transmission_size - 1;

                    // WRITE_ST:
                    WAIT_WRITE_ACK_ST:  
                        // if (!bit_cnt) 
                        transmission_size <= transmission_size - 1;

                    WAIT_READ_ACK_ST : 
                        // if (!bit_cnt)
                        transmission_size <= transmission_size - 1;

                    default: 
                        transmission_size <= transmission_size;

                endcase // current_state
            end 
        end 
    end 

    always_ff @(posedge clk) begin 
        if (transmission_size == 0)
            has_nack_required <= 1'b1;
        else 
            has_nack_required <= 1'b0; 
    end 

    fifo_out_sync_tuser_xpm #(
        .DATA_WIDTH(DATA_WIDTH),
        .USER_WIDTH(8         ),
        .MEMTYPE   ("block"   ),
        .DEPTH     (DEPTH     )
    ) fifo_out_sync_tuser_xpm_inst (
        .CLK          (clk          ),
        .RESET        (reset        ),
        
        .OUT_DIN_DATA (out_din_data ),
        .OUT_DIN_KEEP (out_din_keep ),
        .OUT_DIN_USER (out_din_user ),
        .OUT_DIN_LAST (out_din_last ),
        .OUT_WREN     (out_wren     ),
        .OUT_FULL     (out_full     ),
        .OUT_AWFULL   (out_awfull   ),
        
        .M_AXIS_TDATA (m_axis_tdata ),
        .M_AXIS_TKEEP (m_axis_tkeep ),
        .M_AXIS_TUSER (m_axis_tuser ),
        .M_AXIS_TVALID(m_axis_tvalid),
        .M_AXIS_TLAST (m_axis_tlast ),
        .M_AXIS_TREADY(m_axis_tready)
    );


    /* 
     * 
     */
    always_ff @(posedge clk) begin 
        case (current_state)
            READ_ST : 
                if (!bit_cnt)
                    out_din_last <= has_nack_required;

            default : 
                out_din_last <= out_din_last;
                
        endcase // current_state
    end 


    /*out wren actual on;y for reading operations. 
     * this signal asserted only when 
     * 1) current word fully received from iic device 
     * 2) last halfword received (determine from transmission_size)
     */
    always_ff @(posedge clk) begin 
        if (has_event) begin 
            case (current_state)
                READ_ST : 
                    if (!bit_cnt) begin 
                        if (word_byte_counter == N_BYTES-1) begin
                            out_wren <= 1'b1;
                        end else begin 
                            if (has_nack_required) begin 
                                out_wren <= 1'b1;
                            end else begin  
                                out_wren <= 1'b0;
                            end 
                        end
                    end else begin  
                        out_wren <= 1'b0;
                    end 

                default : 
                    out_wren <= 1'b0;

            endcase // current_state
        end else begin 
            out_wren <= 1'b0;
        end 
    end 

    /* 
     * output data presented as N_BYTES count of 8 bit registers 
     * which addressation dependent word_byte_counter register
     */
    always_ff @(posedge clk) begin 
        case (current_state) 
            READ_ST : 
                if (scl_i_event)
                    out_din_data[word_byte_counter] <= {out_din_data[word_byte_counter][6:0], sda_i};

            default : 
                out_din_data <= out_din_data;

        endcase // current_state
    end 


    /* 
     * KEEP signal required for support AXI-Stream with last halfword, when data count not multiple N_BYTES value
     */
    always_ff @(posedge clk) begin : out_din_keep_proc 
        if (out_wren) begin 
            out_din_keep <= '{default:0};
        end else begin 
            if (has_event)
                case (current_state) 
                    READ_ST : 
                        if (!bit_cnt) 
                            out_din_keep[word_byte_counter] <= 1'b1;

                    default : 
                        out_din_keep <= out_din_keep;
                endcase // current_state
        end 

    end 


    /* 
     * save device address for next transmission if operation read performed
     */
    always_ff @(posedge clk) begin 
        case (current_state) 
            IDLE_ST : 
                out_din_user <= in_dout_user;

            default : 
                out_din_user <= out_din_user;

        endcase // current_state
    end 

    /*FF for create event when i2c clk changed*/
    always_ff @(posedge clk) begin 
        d_scl_i <= scl_i;
    end 

    always_comb begin 
        if (scl_i & ~d_scl_i)
            scl_i_event = 1'b1;
        else 
            scl_i_event = 1'b0;
    end 


    /*ff for determine event when input data change state*/
    always_ff @(posedge clk) begin : d_sda_i_proc
        d_sda_i <= sda_i;
    end

    /* 
     * Signal for ability determine multimaster mode
     * when no active transactions on i2c bus, and when SDA goes to LOW state, but SCL is HIGH, 
     * then another master i2c perform operation
     */
    always_ff @(posedge clk) begin : has_bus_busy_proc
        case (current_state)
            IDLE_ST : 
                if (d_sda_i & !sda_i & scl_i)
                    has_bus_busy <= 1'b1;

            AWAIT_OTHER_MASTER_ST : 
                if  (sda_i & !d_sda_i & scl_i)
                    has_bus_busy <= 1'b0;

            default : 
                has_bus_busy <= 1'b0;

        endcase // current_state
    end 


endmodule