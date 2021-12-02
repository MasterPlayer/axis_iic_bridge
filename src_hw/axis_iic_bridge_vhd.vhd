library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use ieee.std_logic_unsigned.all;
    use ieee.std_logic_arith.all;


entity axis_iic_bridge_vhd is
    generic (
        CLK_PERIOD      :           integer := 100000000                                    ;
        CLK_I2C_PERIOD  :           integer := 25000000                                     ;
        N_BYTES         :           integer := 32                                           ;
        WRITE_CONTROL   :           string  := "COUNTER"                                    ;
        DEPTH           :           integer := 32                                             
    ); 
    port (
        clk             :   in      std_logic                                               ;
        reset           :   in      std_logic                                               ;
        
        s_axis_tdata    :   in      std_logic_vector ( ((N_BYTES*8)-1) downto 0 )           ;
        s_axis_tuser    :   in      std_logic_vector (               7 downto 0 )           ;
        s_axis_tkeep    :   in      std_logic_vector (       N_BYTES-1 downto 0 )           ;
        s_axis_tvalid   :   in      std_logic                                               ;
        s_axis_tready   :   out     std_logic                                               ;
        s_axis_tlast    :   in      std_logic                                               ;

        m_axis_tdata    :   out     std_logic_vector ( ((N_BYTES*8)-1) downto 0 )           ;
        m_axis_tkeep    :   out     std_logic_vector (       N_BYTES-1 downto 0 )           ;
        m_axis_tuser    :   out     std_logic_vector (               7 downto 0 )           ;
        m_axis_tvalid   :   out     std_logic                                               ;
        m_axis_tready   :   in      std_logic                                               ;
        m_axis_tlast    :   out     std_logic                                               ;
        
        scl_i           :   in      std_logic                                               ;
        sda_i           :   in      std_logic                                               ;
        scl_t           :   out     std_logic                                               ;
        sda_t           :   out     std_logic                                               
    );
end axis_iic_bridge_vhd;



architecture axis_iic_bridge_vhd_arch of axis_iic_bridge_vhd is

    component axis_iic_bridge 
        generic (
            CLK_PERIOD      :           integer := 100000000                                    ;
            CLK_I2C_PERIOD  :           integer := 25000000                                     ;
            N_BYTES         :           integer := 32                                           ;
            WRITE_CONTROL   :           string  := "COUNTER"                                    ;
            DEPTH           :           integer := 32                                             
        ); 
        port (
            clk             :   in      std_logic                                               ;
            reset           :   in      std_logic                                               ;
            
            s_axis_tdata    :   in      std_logic_vector ( ((N_BYTES*8)-1) downto 0 )           ;
            s_axis_tuser    :   in      std_logic_vector (               7 downto 0 )           ;
            s_axis_tkeep    :   in      std_logic_vector (       N_BYTES-1 downto 0 )           ;
            s_axis_tvalid   :   in      std_logic                                               ;
            s_axis_tready   :   out     std_logic                                               ;
            s_axis_tlast    :   in      std_logic                                               ;

            m_axis_tdata    :   out     std_logic_vector ( ((N_BYTES*8)-1) downto 0 )           ;
            m_axis_tkeep    :   out     std_logic_vector (       N_BYTES-1 downto 0 )           ;
            m_axis_tuser    :   out     std_logic_vector (               7 downto 0 )           ;
            m_axis_tvalid   :   out     std_logic                                               ;
            m_axis_tready   :   in      std_logic                                               ;
            m_axis_tlast    :   out     std_logic                                               ;
            
            scl_i           :   in      std_logic                                               ;
            sda_i           :   in      std_logic                                               ;
            scl_t           :   out     std_logic                                               ;
            sda_t           :   out     std_logic                                               
        );
    end component;



begin

    axis_iic_bridge_inst : axis_iic_bridge 
        generic map (
            CLK_PERIOD      =>  CLK_PERIOD          ,
            CLK_I2C_PERIOD  =>  CLK_I2C_PERIOD      ,
            N_BYTES         =>  N_BYTES             ,
            WRITE_CONTROL   =>  WRITE_CONTROL       ,
            DEPTH           =>  DEPTH                
        )
        port map (
            clk             =>  clk                 ,
            reset           =>  reset               ,
            
            s_axis_tdata    =>  s_axis_tdata        ,
            s_axis_tuser    =>  s_axis_tuser        ,
            s_axis_tkeep    =>  s_axis_tkeep        ,
            s_axis_tvalid   =>  s_axis_tvalid       ,
            s_axis_tready   =>  s_axis_tready       ,
            s_axis_tlast    =>  s_axis_tlast        ,

            m_axis_tdata    =>  m_axis_tdata        ,
            m_axis_tkeep    =>  m_axis_tkeep        ,
            m_axis_tuser    =>  m_axis_tuser        ,
            m_axis_tvalid   =>  m_axis_tvalid       ,
            m_axis_tready   =>  m_axis_tready       ,
            m_axis_tlast    =>  m_axis_tlast        ,
            
            scl_i           =>  scl_i               ,
            sda_i           =>  sda_i               ,
            scl_t           =>  scl_t               ,
            sda_t           =>  sda_t                
        );

end axis_iic_bridge_vhd_arch;
