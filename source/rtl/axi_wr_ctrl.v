module axi_wr_ctrl#(
    	parameter  C_M_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
		parameter integer C_M_AXI_BURST_LEN	    = 16,//支持（1,2,4，8，16，32，64，128，256）
		parameter integer C_M_AXI_ID_WIDTH	    = 1,

        //upgrade
		parameter integer C_M_AXI_ADDR_WIDTH	= 28,
		parameter integer C_M_AXI_DATA_WIDTH	= 16,

		parameter integer C_M_AXI_AWUSER_WIDTH	= 0,
		parameter integer C_M_AXI_ARUSER_WIDTH	= 0,
		parameter integer C_M_AXI_WUSER_WIDTH	= 0,
		parameter integer C_M_AXI_RUSER_WIDTH	= 0,
		parameter integer C_M_AXI_BUSER_WIDTH	= 0 
)(      
        /****************前端接口**************/
        input wire  [C_M_AXI_DATA_WIDTH-1 : 0]       FIFO_AXI_DATA            ,          //FIFO与AXI相连待发送数据
        input wire  [C_M_AXI_ADDR_WIDTH-1 : 0]       CTRL_AWADDR              ,          //控制器与AXI相连,判断AXI写DDR地址的数值

        //?多路数据可通过增补 FIFO个数以及输入路数完成?

        // input wire  [C_M_AXI_DATA_WIDTH-1 : 0]       FIFO_AXI_DATA         ,          //FIFO与AXI相连待发送数据       
        // input wire  [C_M_AXI_DATA_WIDTH-1 : 0]       FIFO_AXI_DATA         ,          //FIFO与AXI相连待发送数据
        // input wire  [C_M_AXI_DATA_WIDTH-1 : 0]       FIFO_AXI_DATA         ,          //FIFO与AXI相连待发送数据
        // input wire  [C_M_AXI_DATA_WIDTH-1 : 0]       FIFO_AXI_DATA         ,          //FIFO与AXI相连待发送数据

        input  wire                                  M_AXI_AWREADY            ,          //写地址准备好
        input  wire                                  M_AXI_WREADY             ,          //写数据准备好
        /****************总信号****************/            

        input  wire                                  M_AXI_ACLK               ,          //总AXI时钟
		input  wire                                  M_AXI_ARESETN            ,          //复位

		output wire [C_M_AXI_ID_WIDTH-1 : 0]        M_AXI_AWID               ,           //写地址ID
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0]      M_AXI_AWADDR             ,           //写地址总线给出首地址即可，后续地址自行突发计算
		output wire [7 : 0]                         M_AXI_AWLEN              ,           //突发长度。突发长度给出了突发传输的确切数字
		output wire [2 : 0]                         M_AXI_AWSIZE             ,           //突发尺寸。每次突发事件中传输字节个数

		output wire [1 : 0]                         M_AXI_AWBURST            ,           //突发类型
		output wire                                 M_AXI_AWLOCK             ,           //锁类型
		output wire [3 : 0]                         M_AXI_AWCACHE            ,           //缓存类型
		output wire [2 : 0]                         M_AXI_AWPROT             ,           //保护类型

        /****************写信号****************/            
		output wire                                 M_AXI_AWVALID            ,           //写地址有效

		output wire [C_M_AXI_DATA_WIDTH-1 : 0]      M_AXI_WDATA              ,           //写数据
		output wire [C_M_AXI_DATA_WIDTH/8-1 : 0]    M_AXI_WSTRB              ,           //写选通（strobe）。这个信号指示内存中要更新的字节位置
		output wire                                 M_AXI_WLAST              ,           //写last
		output wire                                 M_AXI_WVALID             ,           //写有效

		input  wire [C_M_AXI_ID_WIDTH-1 : 0]         M_AXI_BID                ,          //响应ID
		input  wire [1 : 0]                          M_AXI_BRESP              ,          //写响应
		input  wire                                  M_AXI_BVALID             ,          //写响应有效
		output wire                                 M_AXI_BREADY              ,           //响应ready

        //读与写类似            
		output wire [C_M_AXI_ID_WIDTH-1 : 0]        M_AXI_ARID               ,           
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0]      M_AXI_ARADDR             ,           
		output wire [7 : 0]                         M_AXI_ARLEN              ,           
		output wire [2 : 0]                         M_AXI_ARSIZE             ,           
		output wire [1 : 0]                         M_AXI_ARBURST            ,           
		output wire                                 M_AXI_ARLOCK             ,           
		output wire [3 : 0]                         M_AXI_ARCACHE            ,           
		output wire [2 : 0]                         M_AXI_ARPROT             ,           
		output wire [3 : 0]                         M_AXI_ARQOS              ,           
		output wire [C_M_AXI_ARUSER_WIDTH-1 : 0]    M_AXI_ARUSER             ,           
		output wire                                 M_AXI_ARVALID            ,           
		input  wire                                  M_AXI_ARREADY            ,          

		input  wire [C_M_AXI_ID_WIDTH-1 : 0]         M_AXI_RID                ,
		input  wire [C_M_AXI_DATA_WIDTH-1 : 0]       M_AXI_RDATA              ,
		input  wire [1 : 0]                          M_AXI_RRESP              ,
		input  wire                                  M_AXI_RLAST              ,
		input  wire [C_M_AXI_RUSER_WIDTH-1 : 0]      M_AXI_RUSER              ,
		input  wire                                  M_AXI_RVALID             ,
		output wire                                  M_AXI_RREADY             ,

        //没啥用
		output wire [3 : 0]                         M_AXI_AWQOS               ,           //
        output wire [C_M_AXI_AWUSER_WIDTH-1 : 0]    M_AXI_AWUSER              ,           //
		output wire [C_M_AXI_WUSER_WIDTH-1 : 0]     M_AXI_WUSER               ,           //
		input  wire [C_M_AXI_BUSER_WIDTH-1 : 0]      M_AXI_BUSER                          //
);

//这个好像没啥用
// /****************计算二进制位宽***********************/

// function integer clogb2(input integer number);
// begin
//     for(clogb2 = 0 ; number > 0 ; clogb2 = clogb2 + 1 )
//         number = number >> 1;
//     end
// endfunction

/**********************参数***************************/
parameter   P_ST_IDLE        = 'd0 ,

            P_ST_WRITE_START = 'd1 ,
            P_ST_WRITE_TRANS = 'd2 ,
            P_ST_WRITE_END   = 'd3 ,

            P_ST_READ_START  = 'd4 ,
            P_ST_READ_TRANS  = 'd5 ,
            P_ST_READ_END    = 'd6 ;

/**********************状态机*************************/
reg [7:0]  r_st_current_write    ;
reg [7:0]  r_st_next_write       ;

reg [7:0]  r_st_current_read     ;
reg [7:0]  r_st_next_read        ;

/**********************寄存器*************************/
reg  [C_M_AXI_ADDR_WIDTH - 1 : 0] r_m_axi_awaddr        ;
reg                               r_m_axi_awvalid       ;
reg  [C_M_AXI_DATA_WIDTH - 1 : 0] r_m_axi_wdata         ;
reg                               r_m_axi_wlast         ;
reg                               r_m_axi_wvalid        ;
reg  [C_M_AXI_ADDR_WIDTH - 1 : 0] r_m_axi_araddr        ;
reg                               r_m_axi_arvalid       ;
reg                               r_m_axi_rready        ;
reg                               r_write_start         ;
reg                               r_read_start          ;
reg [7:0]                         r_burst_cnt           ;
reg [C_M_AXI_DATA_WIDTH - 1 : 0]  r_axi_read_data       ;
/**********************网表型*************************/
wire   w_system_rst                                     ;
wire   w_write_last                                     ;

/**********************组合逻辑***********************/
assign M_AXI_AWID    = 'd0                              ;
assign M_AXI_AWLEN   =  C_M_AXI_BURST_LEN               ;
assign M_AXI_AWSIZE  =  C_M_AXI_DATA_WIDTH/8 -1 ;	// 传输数据字节个数
assign M_AXI_AWBURST =  2'b01                           ;
assign M_AXI_AWLOCK  =  'd0                             ;
assign M_AXI_AWCACHE =  4'b0010                         ;
assign M_AXI_AWPROT  =  'd0                             ;
assign M_AXI_AWQOS   =  'd0                             ;
assign M_AXI_AWUSER  =  'd0                             ;
assign M_AXI_AWADDR  = r_m_axi_awaddr + C_M_TARGET_SLAVE_BASE_ADDR ;
assign M_AXI_AWVALID = r_m_axi_awvalid                  ;

assign M_AXI_WSTRB   = {C_M_AXI_DATA_WIDTH{1'b1}}       ;
assign M_AXI_WUSER   = 'd0                              ;
assign M_AXI_WDATA   = r_m_axi_wdata                    ; 

assign M_AXI_WLAST   = (C_M_AXI_BURST_LEN == 1) ? w_write_last : r_m_axi_wlast ; 

assign M_AXI_WVALID  = r_m_axi_wvalid                   ;

assign M_AXI_BREADY  = 1'b1                             ; 

assign M_AXI_ARID    = 'd0                              ;
assign M_AXI_ARADDR  = r_m_axi_araddr + C_M_TARGET_SLAVE_BASE_ADDR;
assign M_AXI_ARLEN   = C_M_AXI_BURST_LEN                ;
assign M_AXI_ARSIZE  = clogb2(C_M_AXI_DATA_WIDTH/8 -1)  ;
assign M_AXI_ARBURST = 2'b01                            ;
assign M_AXI_ARLOCK  = 'd0                              ;
assign M_AXI_ARCACHE = 4'b0010                          ;
assign M_AXI_ARPROT  = 'd0                              ;
assign M_AXI_ARQOS   = 'd0                              ;
assign M_AXI_ARUSER  = 'd0                              ;
assign M_AXI_ARVALID = r_m_axi_arvalid                  ;

assign M_AXI_RREADY  = r_m_axi_rready                   ;

assign w_system_rst  = ~M_AXI_ARESETN                   ;
assign w_write_last  = M_AXI_WVALID && M_AXI_WREADY     ;
/**********************例化***************************/


/**********************进程***************************/
always@(posedge M_AXI_ACLK)
    if(w_system_rst ||M_AXI_AWVALID && M_AXI_AWREADY)
        r_m_axi_awvalid <= 'd0;
    else if(r_write_start)
        r_m_axi_awvalid <= 'd1; 
    else 
        r_m_axi_awvalid <= r_m_axi_awvalid;

always@(posedge M_AXI_ACLK)
    //送地址
    if(r_write_start)
        r_m_axi_awaddr <= CTRL_AWADDR;
    else 
        r_m_axi_awaddr <= 'd0;

always@(posedge M_AXI_ACLK)
    if(w_system_rst ||M_AXI_WLAST )
        r_m_axi_wvalid <= 'd0;
    else if(M_AXI_AWVALID && M_AXI_AWREADY)
        r_m_axi_wvalid <= 'd1;
    else 
        r_m_axi_wvalid <= r_m_axi_wvalid;

always@(posedge M_AXI_ACLK)
    if(w_system_rst || M_AXI_WLAST)
        r_m_axi_wdata <= 'd0;
    else if(M_AXI_WVALID && M_AXI_WREADY)
        r_m_axi_wdata <= FIFO_AXI_DATA;
    else 
        r_m_axi_wdata <= r_m_axi_wdata;

always@(posedge M_AXI_ACLK)
    //burst len > 2
    if(C_M_AXI_BURST_LEN == 1)
        r_m_axi_wlast <= 0;
    else if(C_M_AXI_BURST_LEN == 2 && (M_AXI_WVALID && M_AXI_WREADY && !r_m_axi_wlast))
        r_m_axi_wlast <= M_AXI_WVALID  & M_AXI_WREADY;
    else if(C_M_AXI_BURST_LEN > 2 && r_burst_cnt == C_M_AXI_BURST_LEN - 2)
        r_m_axi_wlast <= 'd1;
    else
        r_m_axi_wlast <= 'd0;

always@(posedge M_AXI_ACLK)
    if(w_system_rst || M_AXI_WLAST)
        r_burst_cnt <= 'd0;
    else if(M_AXI_WVALID && M_AXI_WREADY)
        r_burst_cnt <= r_burst_cnt + 1; 
    else
        r_burst_cnt <= r_burst_cnt;

/*---------------------------------------------------*/
always@(posedge M_AXI_ACLK)
    if(w_system_rst || (M_AXI_ARVALID && M_AXI_ARREADY))
        r_m_axi_arvalid <= 'd0;
    else if(r_read_start)
        r_m_axi_arvalid <= 'd1;
    else
        r_m_axi_arvalid <= r_m_axi_arvalid;
    

always@(posedge M_AXI_ACLK)
    if(r_read_start)
        r_m_axi_araddr <= 'd0;
    else
        r_m_axi_araddr <= 'd0;
    
always@(posedge M_AXI_ACLK)
    if(w_system_rst || M_AXI_RLAST)
        r_m_axi_rready <= 'd0;
    else if(M_AXI_ARVALID && M_AXI_ARREADY)
        r_m_axi_rready <= 'd1;
    else
        r_m_axi_rready <= r_m_axi_rready;

always@(posedge M_AXI_ACLK)
    if(M_AXI_RVALID && M_AXI_RREADY)
        r_axi_read_data <= M_AXI_RDATA;
    else
        r_axi_read_data <= r_axi_read_data;

/*--------------------------------*/
always@(posedge M_AXI_ACLK)
    if(w_system_rst)
        r_st_current_write <= P_ST_IDLE         ;
    else 
        r_st_current_write <= r_st_next_write   ;

always@(*)
    case(r_st_current_write)
        P_ST_IDLE        : r_st_next_write = P_ST_WRITE_START ;
        P_ST_WRITE_START : r_st_next_write = r_write_start ? P_ST_WRITE_TRANS : P_ST_WRITE_START ;
        P_ST_WRITE_TRANS : r_st_next_write = M_AXI_WLAST   ? P_ST_WRITE_END   : P_ST_WRITE_TRANS ;
        P_ST_WRITE_END   : r_st_next_write = (r_st_current_read == P_ST_READ_END) ? P_ST_IDLE : P_ST_WRITE_END;
        default          : r_st_next_write = P_ST_IDLE ;
    endcase
    
always@(posedge M_AXI_ACLK)
    if(r_st_current_write == P_ST_WRITE_START)
        r_write_start <= 'd1;
    else 
        r_write_start <= 'd0;

/*--------------------------------*/
always@(posedge M_AXI_ACLK)
    if(w_system_rst)
        r_st_current_read <= P_ST_IDLE         ;
    else 
        r_st_current_read <= r_st_next_read   ;

always@(*)
    case(r_st_current_read)
        P_ST_IDLE        : r_st_next_read = (r_st_current_write == P_ST_WRITE_END) ? P_ST_READ_START  : P_ST_IDLE;
        P_ST_READ_START  : r_st_next_read = r_read_start ? P_ST_READ_TRANS : P_ST_READ_START;
        P_ST_READ_TRANS  : r_st_next_read = M_AXI_RLAST  ? P_ST_READ_END   : P_ST_READ_TRANS ;
        P_ST_READ_END    : r_st_next_read = P_ST_IDLE ;
        default          : r_st_next_read = P_ST_IDLE ;
    endcase

always@(posedge M_AXI_ACLK)
    if(r_st_current_read == P_ST_READ_START)
        r_read_start <= 'd1;
    else 
        r_read_start <= 'd0;
    

endmodule
