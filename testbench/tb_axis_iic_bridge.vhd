library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
    use UNISIM.VComponents.all;


entity tb_axis_iic_bridge is
end tb_axis_iic_bridge;


architecture Behavioral of tb_axis_iic_bridge is

    constant  CLK_PERIOD        :           integer := 100000000                                                    ;
    constant  CLK_I2C_PERIOD    :           integer := 400000                                                       ;
    constant  N_BYTES           :           integer := 1                                                            ;
    constant  WRITE_CONTROL     :           string  := "COUNTER"                                                    ;
    constant  DEPTH             :           integer := 32                                                           ;

    component axis_iic_bridge_vhd
        generic (
            CLK_PERIOD          :           integer := 100000000                                                    ;
            CLK_I2C_PERIOD      :           integer := 25000000                                                     ;
            N_BYTES             :           integer := 32                                                           ;
            WRITE_CONTROL       :           string  := "COUNTER"                                                    ;
            DEPTH               :           integer := 32                                                             
        ); 
        port (
            clk                 :   in      std_logic                                                               ;
            reset               :   in      std_logic                                                               ;
            
            s_axis_tdata        :   in      std_logic_vector ( ((N_BYTES*8)-1) downto 0 )                           ;
            s_axis_tuser        :   in      std_logic_vector (               7 downto 0 )                           ;
            s_axis_tkeep        :   in      std_logic_vector (       N_BYTES-1 downto 0 )                           ;
            s_axis_tvalid       :   in      std_logic                                                               ;
            s_axis_tready       :   out     std_logic                                                               ;
            s_axis_tlast        :   in      std_logic                                                               ;

            m_axis_tdata        :   out     std_logic_vector ( ((N_BYTES*8)-1) downto 0 )                           ;
            m_axis_tkeep        :   out     std_logic_vector (       N_BYTES-1 downto 0 )                           ;
            m_axis_tuser        :   out     std_logic_vector (               7 downto 0 )                           ;
            m_axis_tvalid       :   out     std_logic                                                               ;
            m_axis_tready       :   in      std_logic                                                               ;
            m_axis_tlast        :   out     std_logic                                                               ;
            
            scl_i               :   in      std_logic                                                               ;
            sda_i               :   in      std_logic                                                               ;
            scl_t               :   out     std_logic                                                               ;
            sda_t               :   out     std_logic                                                               
        );
    end component;

    signal  clk                 :           std_logic                                       := '0'                  ;
    signal  reset               :           std_logic                                       := '0'                  ;
    
    signal  s_axis_tdata        :           std_logic_vector ( ((N_BYTES*8)-1) downto 0 )   := (others => '0')      ;
    signal  s_axis_tuser        :           std_logic_vector (               7 downto 0 )   := (others => '0')      ;
    signal  s_axis_tkeep        :           std_logic_vector (       N_BYTES-1 downto 0 )   := (others => '0')      ;
    signal  s_axis_tvalid       :           std_logic                                       := '0'                  ;
    signal  s_axis_tready       :           std_logic                                                               ;
    signal  s_axis_tlast        :           std_logic                                       := '0'                  ;

    signal  m_axis_tdata        :           std_logic_vector ( ((N_BYTES*8)-1) downto 0 )                           ;
    signal  m_axis_tkeep        :           std_logic_vector (       N_BYTES-1 downto 0 )                           ;
    signal  m_axis_tuser        :           std_logic_vector (               7 downto 0 )                           ;
    signal  m_axis_tvalid       :           std_logic                                                               ;
    signal  m_axis_tready       :           std_logic                                       := '0'                  ;
    signal  m_axis_tlast        :           std_logic                                                               ;
    
    signal  scl_i               :           std_logic                                       := '0'                  ;
    signal  sda_i               :           std_logic                                       := '0'                  ;
    signal  scl_t               :           std_logic                                                               ;
    signal  sda_t               :           std_logic                                                               ;

    component tb_slave_device_model 
        port (
            IIC_SCL_I           :   in      std_logic                                                               ;
            IIC_SDA_I           :   in      std_logic                                                               ;
            IIC_SCL_O           :   out     std_logic                                                               ;
            IIC_SDA_O           :   out     std_logic                                                                
        );
    end component;

    signal  i                   :           integer                                         := 0                    ;

    component axis_iic_master_controller
        generic(
            CLK_FREQUENCY                       :   integer         :=  100000000                                                   ;
            CLK_IIC_FREQUENCY                   :   integer         :=  400000                                                      ;
            FIFO_DEPTH                          :   integer         :=  64 
        );
        port(
            CLK                                 :   in      std_logic                                                               ;
            RESET                               :   in      std_logic                                                               ;
            -- SLave AXI-Stream 
            S_AXIS_TDATA                        :   in      std_logic_Vector ( 7 downto 0 )                                         ;
            S_AXIS_TDEST                        :   in      std_logic_Vector ( 7 downto 0 )                                         ;
            S_AXIS_TVALID                       :   in      std_logic                                                               ;
            S_AXIS_TLAST                        :   in      std_logic                                                               ;
            S_AXIS_TREADY                       :   out     std_logic                                                               ;   

            M_AXIS_TDATA                        :   out     std_logic_Vector ( 7 downto 0 )                                         ;
            M_AXIS_TDEST                        :   out     std_logic_Vector ( 7 downto 0 )                                         ;
            M_AXIS_TVALID                       :   out     std_logic                                                               ;
            M_AXIS_TLAST                        :   out     std_logic                                                               ;
            M_AXIS_TREADY                       :   in      std_logic                                                               ;

            SCL_I                               :   in      std_logic                                                               ;
            SCL_T                               :   out     std_logic                                                               ;
            SDA_I                               :   in      std_logic                                                               ;
            SDA_T                               :   out     std_logic                                                                
        );
    end component;

    signal  SCL_I_1                             :           std_logic                                                               ;
    signal  SCL_T_1                             :           std_logic                                                               ;
    signal  SDA_I_1                             :           std_logic                                                               ;
    signal  SDA_T_1                             :           std_logic                                                               ;


begin

    CLK <= not CLK after 5 ns;

    i_processing : process(CLK)
    begin 
        if CLK'event AND CLK = '1' then 
            i <= i + 1;
        end if;
    end process;

    RESET <= '1' when i < 10 else '0';

    s_axis_processing : process(CLK)
    begin 
        if CLK'event AND CLK = '1' then 
            case i is 
                when 100    => s_axis_tdata <= x"00"; s_axis_tuser <= x"A6"; s_axis_tkeep <= "1"; s_axis_tvalid <= '1'; s_axis_tlast <= '0';
                when 101    => s_axis_tdata <= x"00"; s_axis_tuser <= x"A6"; s_axis_tkeep <= "1"; s_axis_tvalid <= '1'; s_axis_tlast <= '0';
                when 102    => s_axis_tdata <= x"00"; s_axis_tuser <= x"A6"; s_axis_tkeep <= "1"; s_axis_tvalid <= '1'; s_axis_tlast <= '1';

                when 100000 => s_axis_tdata <= x"08"; s_axis_tuser <= x"A7"; s_axis_tkeep <= "1"; s_axis_tvalid <= '1'; s_axis_tlast <= '1';
                when 100001 => s_axis_tdata <= x"08"; s_axis_tuser <= x"A9"; s_axis_tkeep <= "1"; s_axis_tvalid <= '1'; s_axis_tlast <= '1';

                when others => s_axis_tdata <= s_axis_tdata; s_axis_tuser <= s_axis_tuser; s_axis_tkeep <= s_axis_tkeep; s_axis_tvalid <= '0'; s_axis_tlast <= s_axis_tlast;
            end case;
        end if;
    end process;

    axis_iic_bridge_vhd_inst : axis_iic_bridge_vhd
        generic map (
            CLK_PERIOD          =>  CLK_PERIOD          ,
            CLK_I2C_PERIOD      =>  CLK_I2C_PERIOD      ,
            N_BYTES             =>  N_BYTES             ,
            WRITE_CONTROL       =>  WRITE_CONTROL       ,
            DEPTH               =>  DEPTH                
        )
        port map (
            clk                 =>  clk                 ,
            reset               =>  reset               ,
            
            s_axis_tdata        =>  s_axis_tdata        ,
            s_axis_tuser        =>  s_axis_tuser        ,
            s_axis_tkeep        =>  s_axis_tkeep        ,
            s_axis_tvalid       =>  s_axis_tvalid       ,
            s_axis_tready       =>  open                ,
            s_axis_tlast        =>  s_axis_tlast        ,

            m_axis_tdata        =>  open                ,
            m_axis_tkeep        =>  open                ,
            m_axis_tuser        =>  open                ,
            m_axis_tvalid       =>  open                ,
            m_axis_tready       =>  '1'                 ,
            m_axis_tlast        =>  open                ,
            
            scl_i               =>  scl_i               ,
            sda_i               =>  sda_i               ,
            scl_t               =>  scl_t               ,
            sda_t               =>  sda_t                
        );


    tb_slave_device_model_inst : tb_slave_device_model 
        port map (
            IIC_SCL_I           =>  scl_t               ,
            IIC_SDA_I           =>  sda_t               ,
            IIC_SCL_O           =>  scl_i               ,
            IIC_SDA_O           =>  sda_i               
        );


end Behavioral;
