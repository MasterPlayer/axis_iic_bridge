`timescale 1ps / 1ps



module tb_slave_device_model (
    input  logic i_clk    ,
    input  logic i_reset  ,
    input  logic iic_scl_i,
    input  logic iic_sda_i,
    output logic iic_scl_o,
    output logic iic_sda_o
);


    initial begin
        $timeformat(-9, 3, " ns", 10);
    end

    logic [0:255][7:0] register_file = '{
        8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D, 8'h0E, 8'h0F,
        8'h10, 8'h11, 8'h12, 8'h13, 8'h14, 8'h15, 8'h16, 8'h17, 8'h18, 8'h19, 8'h1A, 8'h1B, 8'h1C, 8'h1D, 8'h1E, 8'h1F,
        8'h20, 8'h21, 8'h22, 8'h23, 8'h24, 8'h25, 8'h26, 8'h27, 8'h28, 8'h29, 8'h2A, 8'h2B, 8'h2C, 8'h2D, 8'h2E, 8'h2F,
        8'h30, 8'h31, 8'h32, 8'h33, 8'h34, 8'h35, 8'h36, 8'h37, 8'h38, 8'h39, 8'h3A, 8'h3B, 8'h3C, 8'h3D, 8'h3E, 8'h3F,
        8'h40, 8'h41, 8'h42, 8'h43, 8'h44, 8'h45, 8'h46, 8'h47, 8'h48, 8'h49, 8'h4A, 8'h4B, 8'h4C, 8'h4D, 8'h4E, 8'h4F,
        8'h50, 8'h51, 8'h52, 8'h53, 8'h54, 8'h55, 8'h56, 8'h57, 8'h58, 8'h59, 8'h5A, 8'h5B, 8'h5C, 8'h5D, 8'h5E, 8'h5F,
        8'h60, 8'h61, 8'h62, 8'h63, 8'h64, 8'h65, 8'h66, 8'h67, 8'h68, 8'h69, 8'h6A, 8'h6B, 8'h6C, 8'h6D, 8'h6E, 8'h6F,
        8'h70, 8'h71, 8'h72, 8'h73, 8'h74, 8'h75, 8'h76, 8'h77, 8'h78, 8'h79, 8'h7A, 8'h7B, 8'h7C, 8'h7D, 8'h7E, 8'h7F,
        8'h80, 8'h81, 8'h82, 8'h83, 8'h84, 8'h85, 8'h86, 8'h87, 8'h88, 8'h89, 8'h8A, 8'h8B, 8'h8C, 8'h8D, 8'h8E, 8'h8F,
        8'h90, 8'h91, 8'h92, 8'h93, 8'h94, 8'h95, 8'h96, 8'h97, 8'h98, 8'h99, 8'h9A, 8'h9B, 8'h9C, 8'h9D, 8'h9E, 8'h9F,
        8'hA0, 8'hA1, 8'hA2, 8'hA3, 8'hA4, 8'hA5, 8'hA6, 8'hA7, 8'hA8, 8'hA9, 8'hAA, 8'hAB, 8'hAC, 8'hAD, 8'hAE, 8'hAF,
        8'hB0, 8'hB1, 8'hB2, 8'hB3, 8'hB4, 8'hB5, 8'hB6, 8'hB7, 8'hB8, 8'hB9, 8'hBA, 8'hBB, 8'hBC, 8'hBD, 8'hBE, 8'hBF,
        8'hC0, 8'hC1, 8'hC2, 8'hC3, 8'hC4, 8'hC5, 8'hC6, 8'hC7, 8'hC8, 8'hC9, 8'hCA, 8'hCB, 8'hCC, 8'hCD, 8'hCE, 8'hCF,
        8'hD0, 8'hD1, 8'hD2, 8'hD3, 8'hD4, 8'hD5, 8'hD6, 8'hD7, 8'hD8, 8'hD9, 8'hDA, 8'hDB, 8'hDC, 8'hDD, 8'hDE, 8'hDF,
        8'hE0, 8'hE1, 8'hE2, 8'hE3, 8'hE4, 8'hE5, 8'hE6, 8'hE7, 8'hE8, 8'hE9, 8'hEA, 8'hEB, 8'hEC, 8'hED, 8'hEE, 8'hEF,
        8'hF0, 8'hF1, 8'hF2, 8'hF3, 8'hF4, 8'hF5, 8'hF6, 8'hF7, 8'hF8, 8'hF9, 8'hFA, 8'hFB, 8'hFC, 8'hFD, 8'hFE, 8'hFF 
    };

    logic d_iic_sda_i;
    logic d_iic_scl_i;

    logic sda_i_event;
    logic scl_i_event;

    logic has_start;
    logic has_stop;

    integer duration_div4 = 0;
    integer duration_div2 = 0;
    integer duration      = 0;

    logic scl_assert   = 1'b0;
    logic scl_deassert = 1'b0;

    typedef enum {
        WAIT_START_EVENT_ST,
        CALCULATION_ST,
        WAIT_STOP_EVENT_ST
    } duration_fsm;

    duration_fsm duration_fsm_state = WAIT_START_EVENT_ST; 

    always_ff @(posedge i_clk) begin 
        d_iic_sda_i <= iic_sda_i;
    end 

    always_ff @(posedge i_clk) begin 
        d_iic_scl_i <= iic_scl_i;
    end 

    always_comb sda_i_event = iic_sda_i ^ d_iic_sda_i;
    always_comb scl_i_event = iic_scl_i ^ d_iic_scl_i;

    always_comb scl_assert   = scl_i_event & iic_scl_i;
    always_comb scl_deassert = scl_i_event & ~iic_scl_i;

    always_comb has_start   = sda_i_event & !iic_sda_i & iic_scl_i;
    always_comb has_stop    = sda_i_event & iic_sda_i & iic_scl_i;

    always_ff @(posedge i_clk) begin : duration_fsm_state_processing 
        if (i_reset) begin 
            duration_fsm_state <= WAIT_START_EVENT_ST;
        end else begin 
            case (duration_fsm_state)
                WAIT_START_EVENT_ST: 
                    if (has_start) begin 
                        duration_fsm_state <= CALCULATION_ST;
                    end else begin 
                        duration_fsm_state <= duration_fsm_state;
                    end 

                CALCULATION_ST: 
                    if (scl_i_event) begin 
                        duration_fsm_state <= WAIT_STOP_EVENT_ST;
                    end else begin 
                        duration_fsm_state <= duration_fsm_state;
                    end 

                WAIT_STOP_EVENT_ST : 
                    if (has_stop) begin 
                        duration_fsm_state <= WAIT_START_EVENT_ST;
                    end else begin 
                        duration_fsm_state <= duration_fsm_state;
                    end 

                default : 
                    duration_fsm_state <= duration_fsm_state;
            endcase // current_state
        end 
    end 
    


    always_ff @(posedge i_clk) begin : duration_div4_processing 
        case (duration_fsm_state)

            WAIT_START_EVENT_ST: 
                duration_div4 <= 0;

            CALCULATION_ST :
                if (scl_i_event) begin 
                    duration_div4 <= duration_div4;
                end else begin 
                    duration_div4 <= duration_div4 + 1;
                end 

            default: 
                duration_div4 <= duration_div4;

        endcase // duration_fsm_state
    end 



    always_comb duration_div2 = duration_div4 << 1;
    always_comb duration      = duration_div4 << 2;



    integer duration_cnt         = '{default:0};
    integer duration_cnt_shifted = '{default:0};



    always_ff @(posedge i_clk) begin : duration_cnt_processing 
        case (duration_fsm_state)
            WAIT_START_EVENT_ST: 
                if (has_start) begin 
                    duration_cnt <= duration_cnt + 1;
                end else begin 
                    duration_cnt <= '{default:0};
                end 

            default : 
                if (duration_cnt < duration) begin 
                    duration_cnt <= duration_cnt + 1;
                end else begin 
                    duration_cnt <= '{default:0};
                end 

        endcase // duration_fsm_state
    end 

    logic duration_cnt_event = 1'b0;

    always_ff @(posedge i_clk) begin : duration_cnt_event_processing 
        case (duration_fsm_state)
            WAIT_START_EVENT_ST : 
                duration_cnt_event <= 1'b0;

            default : 
                if (duration_cnt < duration) begin 
                    duration_cnt_event <= 1'b0;
                end else begin 
                    duration_cnt_event <= 1'b1;
                end 

        endcase // duration_fsm_state
    end 

    always_ff @(posedge i_clk) begin : duration_cnt_shifted_processing 
        case (duration_fsm_state)
            WAIT_STOP_EVENT_ST: 
                if (duration_cnt_shifted < duration) begin 
                    duration_cnt_shifted <= duration_cnt_shifted + 1;
                end else begin 
                    duration_cnt_shifted <= '{default:0};
                end 

            default : 
                duration_cnt_shifted <= duration_cnt_shifted;

        endcase // duration_fsm_state
    end 



    logic has_event;



    always_ff @(posedge i_clk) begin : has_event_processing 
        case (duration_fsm_state)
            
            WAIT_STOP_EVENT_ST : 
                if (duration_cnt == duration) begin 
                    has_event <= 1'b1;
                end else begin 
                    has_event <= 1'b0;
                end 

            default : 
                has_event <= 1'b0;

        endcase // duration_fsm_state
    end 


    typedef enum {
        WAIT_START_ST, 
        RX_ADDR_ST,
        TX_ACK_ST,
        RX_DATA_ST,
        TX_DATA_ST
    } fsm;


    fsm current_state = WAIT_START_ST;


    always_ff @(posedge i_clk) begin : current_state_processing 
        if (has_stop) begin 
            current_state <= WAIT_START_ST;
        end else begin 

            case (current_state)

                WAIT_START_ST : 
                    if (has_start) begin 
                        current_state <= RX_ADDR_ST;
                    end else begin 
                        current_state <= current_state;
                    end 

                RX_ADDR_ST : 
                    if (scl_assert) begin 
                        if (bit_cnt == 0) begin 
                            current_state <= TX_ACK_ST;
                        end else begin
                            current_state <= current_state;
                        end 
                    end else begin 
                        current_state <= current_state;
                    end 

                TX_ACK_ST :     
                    if (scl_assert) begin 
                        if (!iic_address[0]) begin 
                            current_state <= RX_DATA_ST;
                        end else begin 
                            current_state <= TX_DATA_ST;
                        end 
                    end else begin 
                        current_state <= current_state;
                    end 

                RX_DATA_ST : 
                    if (scl_assert) begin 
                        if (bit_cnt == 0) begin 
                            current_state <= TX_ACK_ST;
                        end else begin 
                            current_state <= current_state;
                        end 
                    end else begin 
                        current_state <= current_state;
                    end 

                TX_DATA_ST : 
                    if (scl_assert) begin 
                        if (bit_cnt == 0) begin 
                            current_state <= TX_ACK_ST;
                        end else begin 
                            current_state <= current_state;
                        end 
                    end else begin 
                        current_state <= current_state;
                    end 

                default : 
                    current_state <= current_state;

            endcase // current_state
        end 
    end 


    logic [7:0] iic_address;


    always_ff @(posedge i_clk) begin : iic_address_processing 
        case (current_state)
            RX_ADDR_ST: 
                if (scl_assert) begin 
                    iic_address <= {iic_address[6:0], iic_sda_i};
                end else begin 
                    iic_address <= iic_address;
                end 

            default : 
                iic_address <= iic_address;

        endcase // current_state
    end 


    logic [2:0] bit_cnt = '{default:0};


    always_ff @(posedge i_clk) begin : bit_cnt_processing 
        case (current_state)
            RX_ADDR_ST: 
                if (scl_assert) begin 
                    bit_cnt <= bit_cnt - 1;
                end else begin 
                    bit_cnt <= bit_cnt;
                end 

            RX_DATA_ST : 
                if (scl_assert) begin 
                    bit_cnt <= bit_cnt - 1;
                end else begin 
                    bit_cnt <= bit_cnt;
                end 

            TX_DATA_ST : 
                if (scl_assert) begin 
                    bit_cnt <= bit_cnt - 1;
                end else begin 
                    bit_cnt <= bit_cnt;
                end 

            default : 
                bit_cnt <= 7;

        endcase // duration_fsm_state
    end 


    always_ff @(posedge i_clk) begin : iic_sda_o_processing 
        case (current_state) 
            RX_ADDR_ST : 
                iic_sda_o <= iic_sda_i;

            TX_ACK_ST : 
                // if (has_event) begin 
                if (duration_cnt_event) begin 
                    iic_sda_o <= 1'b0;
                end else begin 
                    iic_sda_o <= iic_sda_o;
                end 

            RX_DATA_ST : 
                // if (has_event) begin 
                iic_sda_o <= iic_sda_i;
                // end else begin 
                //     iic_sda_o <= iic_sda_o;
                // end 

            TX_DATA_ST : 
                if (duration_cnt_event) begin 
                    iic_sda_o <= register_file[ptr][bit_cnt];
                end else begin 
                    iic_sda_o <= iic_sda_o;
                end 

            default : 
                iic_sda_o <= iic_sda_o;

        endcase // current_state
    end 


    always_ff @(posedge i_clk) begin : iic_scl_o_processing 
        case (current_state)
            // RX_ADDR_ST : 
            //     iic_scl_o <= iic_scl_i;

            // TX_ACK_ST: 
            //     iic_scl_o <= iic_scl_i;

            // TX_DATA_ST : 
            //     iic_scl_o <= iic_scl_i;

            default : 
                iic_scl_o <= iic_scl_i;
        endcase // duration_fsm_state
    end 


    logic [7:0] ptr;


    always_ff @(posedge i_clk) begin : ptr_processing  
        case (current_state) 
            RX_DATA_ST : 
                if (scl_assert) begin
                    if (word_counter == 0) begin 
                        ptr <= {ptr[6:0], iic_sda_i};
                    end else begin 
                        ptr <= ptr; 
                    end  
                end else begin 
                    ptr <= ptr;
                end 

            TX_DATA_ST : 
                if (scl_assert)
                    if (bit_cnt == 0) 
                        ptr <= ptr + 1;

            default : 
                ptr <= ptr;
        endcase // duration_fsm_state
    end 


    integer word_counter = 0;

    always_ff @(posedge i_clk) begin : word_counter_processing 
        case (current_state)
            RX_DATA_ST : 
                if (scl_assert)
                    if (bit_cnt == 0) begin 
                        word_counter <= word_counter + 1;
                    end else begin 
                        word_counter <= word_counter;
                    end 
                else 
                    word_counter <= word_counter;

            WAIT_START_ST: 
                word_counter <= 0;

            default: 
                word_counter <= word_counter;
        endcase // current_state
    end 

endmodule
