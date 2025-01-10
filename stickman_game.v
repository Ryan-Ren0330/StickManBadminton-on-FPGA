module stickman_game( 
    input CLOCK_50,           // 系统时钟 50MHz
    input [3:0] KEY,          // 按键输入，KEY[0] 用于复位
    input [9:0] SW,           // 开关，SW[0] 用于复位
    // PS/2 接口
    inout PS2_CLK,
    inout PS2_DAT,
    // VGA 信号
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK,
	 output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX4,
    output [6:0] HEX5
);

// 参数定义
parameter SCREEN_WIDTH = 320;
parameter SCREEN_HEIGHT = 240;
parameter STICKMAN_WIDTH = 24;
parameter STICKMAN_HEIGHT = 32;
parameter BALL_WIDTH =10;
parameter BALL_HEIGHT =10;

// 复位信号（高电平有效）
wire resetn;
assign resetn = SW[0];

// Player1 和 Player2 的位置
reg [8:0] player1_x; // Player1 x 坐标
reg [7:0] player1_y; // Player1 y 坐标
reg [8:0] player2_x; // Player2 x 坐标
reg [7:0] player2_y; // Player2 y 坐标
reg [8:0] ball_x; // ball x 坐标
reg [7:0] ball_y; // ball y 坐标

reg game_started; 
reg [1:0] game_state = GAME_STATE_START;
// PS/2 接口信号
wire [7:0] ps2_key_data;
wire ps2_key_pressed;

// PS/2 数据处理的内部存储器
reg [7:0] last_data_received;
reg f0_received;

// 按键状态存储器
reg left_arrow_pressed, right_arrow_pressed;
reg a_pressed, d_pressed;
// 在寄存器声明区域添加
reg [7:0] player1_score = 0; // Player1的分数
reg [7:0] player2_score = 0; // Player2的分数
reg scored_flag = 0;         // 防止重复计分的标志

// VGA 绘图信号
reg [8:0] VGA_X;
reg [7:0] VGA_Y;
reg [2:0] VGA_COLOR;
reg plot;

// 移动速度控制的时钟分频器
reg [19:0] move_counter;
wire move_tick = (move_counter == 0);
reg [19:0] move_counter_2;
wire move_tick_2 = (move_counter_2 == 0);
parameter BALL_MOVE_DELAY = 2000000; // 调整此值以改变速度
parameter GRAVITY_DELAY = 6000000;
reg [21:0] ball_move_counter;
wire ball_move_tick = (ball_move_counter >= BALL_MOVE_DELAY);
reg [19:0] collision_cooldown = 0;       // 碰撞冷却计时器
parameter COLLISION_COOLDOWN_TIME = 5000000; // 碰撞冷却时间（可调整）

reg [22:0] gravity_counter;         // 增加计数器位宽以匹配更大的延迟值
reg [3:0] gravity_accumulator = 0;     // 重力累积器

wire gravity_tick = (gravity_counter >= GRAVITY_DELAY);
//开始界面
wire [2:0] startbackground_color;
wire [16:0] startbackground_address = VGA_Y * SCREEN_WIDTH + VGA_X; // 计算 320x240 图像的地址

start_mem startbackground_inst (
    .address(startbackground_address),
    .clock(CLOCK_50),
    .q(startbackground_color) // 3 位颜色输出
);
// 背景 ROM 接口
wire [2:0] background_color;
wire [16:0] background_address = VGA_Y * SCREEN_WIDTH + VGA_X; // 计算 320x240 图像的地址

background_mem background_inst (
    .address(background_address),
    .clock(CLOCK_50),
    .q(background_color) // 3 位颜色输出
);

// Player1 的 ROM 接口
wire [15:0] player1_color;
wire [4:0] player1_pixel_x = VGA_X - player1_x; // 0~23，5位
wire [4:0] player1_pixel_y = VGA_Y - player1_y; // 0~31，5位
wire player1_active = (VGA_X >= player1_x) && (VGA_X < player1_x + STICKMAN_WIDTH) &&
                      (VGA_Y >= player1_y) && (VGA_Y < player1_y + STICKMAN_HEIGHT);

wire [12:0] player1_address = (player1_pixel_y * STICKMAN_WIDTH) + player1_pixel_x;
object_mem player1_mem (
    .address(player1_address),
    .clock(CLOCK_50),
    .q(player1_color) // Player1 像素颜色
);

// Player2 的 ROM 接口
wire [15:0] player2_color;
wire [4:0] player2_pixel_x = VGA_X - player2_x; // 0~23，5位
wire [4:0] player2_pixel_y = VGA_Y - player2_y; // 0~31，5位
wire player2_active = (VGA_X >= player2_x) && (VGA_X < player2_x + STICKMAN_WIDTH) &&
                      (VGA_Y >= player2_y) && (VGA_Y < player2_y + STICKMAN_HEIGHT);

wire [12:0] player2_address = (player2_pixel_y * STICKMAN_WIDTH) + player2_pixel_x;
object_mem2 player2_mem (
    .address(player2_address),
    .clock(CLOCK_50),
    .q(player2_color) // Player2 像素颜色
);
// ball 的 ROM 接口
wire [15:0] ball_color;
wire [4:0] ball_pixel_x = VGA_X - ball_x; // 0~23，5位
wire [4:0] ball_pixel_y = VGA_Y - ball_y; // 0~31，5位
wire ball_active = (VGA_X >= ball_x) && (VGA_X < ball_x + BALL_WIDTH) &&
                      (VGA_Y >= ball_y) && (VGA_Y < ball_y + BALL_HEIGHT);

wire [12:0] ball_address = (ball_pixel_y * BALL_WIDTH) + ball_pixel_x;
object_mem3 ball_mem (
    .address(ball_address),
    .clock(CLOCK_50),
    .q(ball_color) // ball 像素颜色
);
wire [2:0] finish1background_color;
wire [16:0] finish1background_address = VGA_Y * SCREEN_WIDTH + VGA_X; // 计算 320x240 图像的地址

finish1_mem finish1background_inst (
    .address(finish1background_address),
    .clock(CLOCK_50),
    .q(finish1background_color) // 3 位颜色输出
);
wire [2:0] finish2background_color;
wire [16:0] finish2background_address = VGA_Y * SCREEN_WIDTH + VGA_X; // 计算 320x240 图像的地址

finish2_mem finish2background_inst (
    .address(finish2background_address),
    .clock(CLOCK_50),
    .q(finish2background_color) // 3 位颜色输出
);


// 屏幕扫描的像素计数器
reg [8:0] h_counter = 0; // 水平计数器
reg [7:0] v_counter = 0; // 垂直计数器
// 首先在参数定义区域添加游戏状态定义
parameter GAME_STATE_START = 2'b00;    // 开始界面
parameter GAME_STATE_PLAYING = 2'b01;  // 游戏进行中
parameter GAME_STATE_P1_WIN = 2'b10;   // Player1获胜界面
parameter GAME_STATE_P2_WIN = 2'b11;   // Player2获胜界面
always @(posedge CLOCK_50 or negedge resetn) begin
    if (!resetn) begin
        game_state <= GAME_STATE_START;
    end else begin
        case (game_state)
            GAME_STATE_START: begin
                if (!KEY[3]) begin  // KEY[3]按下开始游戏
                    game_state <= GAME_STATE_PLAYING;
                end
            end
            
            GAME_STATE_PLAYING: begin
                if (player1_score >= 11) begin  // Player1获得11分
                    game_state <= GAME_STATE_P1_WIN;
                end else if (player2_score >= 11) begin  // Player2获得11分
                    game_state <= GAME_STATE_P2_WIN;
                end
            end

        endcase
    end
end
// 初始化 Player1 和 Player2 位置

initial begin
    player1_x = 60;
    player1_y = 200;
    player2_x = 260;
    player2_y = 200;
    ball_x = 150;
    ball_y = 125;
    move_counter = 0;
    move_counter_2 = 0;
    ball_move_counter = 0;
	 ball_dx = 3;    // 添加这行
    ball_dy = 1;    // 添加这行
end


always @(posedge CLOCK_50) begin
    if (!resetn) begin
        game_started <= 0;
    end else if (!KEY[0]) begin  // KEY[0]是低电平有效
        game_started <= 1;
    end
end
// PS/2 控制器处理
always @(posedge CLOCK_50) begin
    if (!resetn) begin
        last_data_received <= 8'h00;
        f0_received <= 1'b0;
        left_arrow_pressed <= 0;
        right_arrow_pressed <= 0;
        a_pressed <= 0;
        d_pressed <= 0;
    end
    else begin
        if (ps2_key_pressed) begin
            if (ps2_key_data == 8'hF0) begin
                f0_received <= 1'b1; // 接收到断码
            end
            else begin
                if (f0_received) begin
                    // 按键释放事件
                    case (ps2_key_data)
                        8'h6B: a_pressed <= 0; // 左箭头键
                        8'h74: d_pressed <= 0; // 右箭头键
                        8'h1C: left_arrow_pressed <= 0; // 'A' 键
                        8'h23: right_arrow_pressed <= 0; // 'D' 键
                    endcase
                    f0_received <= 1'b0;
                end
                else begin
                    // 按键按下事件
                    case (ps2_key_data)
                        8'h6B: a_pressed <= 1; // 左箭头键
                        8'h74: d_pressed <= 1; // 右箭头键
                        8'h1C: left_arrow_pressed <= 1; // 'A' 键
                        8'h23: right_arrow_pressed <= 1; // 'D' 键
                    endcase
                    last_data_received <= ps2_key_data;
                end
            end
        end
    end
end
PS2_Controller PS2 (
    // 输入
    .CLOCK_50        (CLOCK_50),
    .reset           (!resetn), // 使用统一的复位信号

    // 双向信号
    .PS2_CLK         (PS2_CLK),
    .PS2_DAT         (PS2_DAT),

    // 输出
    .received_data   (ps2_key_data),
    .received_data_en(ps2_key_pressed)
);

// Player1 移动逻辑
always @(posedge CLOCK_50) begin
    if (!resetn) begin
        move_counter <= 0;
		  player1_y = 200;
		  player1_x = 60;
    end else begin
        move_counter <= move_counter + 1;

        if (move_tick) begin
            move_counter <= 1;
            if (left_arrow_pressed && player1_x > 0)
                player1_x <= player1_x - 1; // 向左移动
            if (right_arrow_pressed && player1_x < ((SCREEN_WIDTH /2) - STICKMAN_WIDTH))
                player1_x <= player1_x + 1; // 向右移动
        end
    end
end

// Player2 移动逻辑
always @(posedge CLOCK_50) begin
    if (!resetn) begin
        move_counter_2 <= 0;
		  player2_y = 200;
		  player2_x = 260;
    end else begin
        move_counter_2 <= move_counter_2 + 1;

        if (move_tick_2) begin
            move_counter_2 <= 1;
            if (a_pressed && player2_x > (SCREEN_WIDTH /2))
                player2_x <= player2_x - 1; // 向左移动
            if (d_pressed && player2_x < (SCREEN_WIDTH - STICKMAN_WIDTH))
                player2_x <= player2_x + 1; // 向右移动
        end
    end
end


parameter BALL_SIZE = 10;
reg signed [8:0] ball_dx = 3; // 水平速度
reg signed [8:0] ball_dy = 1; // 垂直速度
parameter GRAVITY = 2;  
parameter MAX_VERTICAL_SPEED = 12;  // 减小最大速度
  // 新增：用于累积重力效果
// ball移动逻辑
// 在ball移动逻辑中的game_started部分添加碰撞检测
// 首先添加一个8位LFSR来生成随机数
reg [7:0] lfsr;
wire lfsr_feedback = lfsr[7] ^ lfsr[3] ^ lfsr[2] ^ lfsr[1];

// 在always块外添加随机数相关的参数定义
parameter RAND_SPEED_MIN = 2;
parameter RAND_SPEED_MAX = 4;

always @(posedge CLOCK_50) begin
    if (!resetn) begin
        ball_dx <= 3;
        ball_dy <= 1;
        ball_x <= 150;
        ball_y <= 125;
        gravity_accumulator <= 0;
        player1_score <= 0;   
        player2_score <= 0;    
        scored_flag <= 0;
        collision_cooldown <= 0;
        lfsr <= 8'b10111101;  // 初始化LFSR với một giá trị khác 0     
    end else begin
        // 更新LFSR
        lfsr <= {lfsr[6:0], lfsr_feedback};
        
        ball_move_counter <= ball_move_counter + 1;
        gravity_counter <= gravity_counter + 1;
        
        if (collision_cooldown > 0) begin
            collision_cooldown <= collision_cooldown - 1;
        end
        
        if (game_started) begin
            // 计分逻辑保持不变
            if (!scored_flag) begin  
                if (ball_y >= 220) begin
                    if (ball_x >= 160) begin
                        player1_score <= player1_score + 1;
                    end else begin
                        player2_score <= player2_score + 1;
                    end
                    scored_flag <= 1;
                end
                else if (ball_x < 15) begin
                    player1_score <= player1_score + 1;
                    scored_flag <= 1;
                end
                else if (ball_x > 305) begin
                    player2_score <= player2_score + 1;
                    scored_flag <= 1;
                end
            end

            if (!KEY[1] && scored_flag) begin
                ball_x <= 150;
                ball_y <= 125;
                ball_dx <= 3;
                ball_dy <= 1;
                gravity_accumulator <= 3;
                scored_flag <= 0;
            end

            // 重力效果更新保持不变
            if (gravity_tick) begin
                gravity_counter <= 2;
                if (ball_y < 220) begin
                    if (gravity_accumulator >= 4) begin
                        if (ball_dy < MAX_VERTICAL_SPEED) begin
                            ball_dy <= ball_dy + GRAVITY;
                        end
                        gravity_accumulator <= 0;
                    end else begin
                        gravity_accumulator <= gravity_accumulator + 1;
                    end
                end else begin
                    ball_dy <= 0;
                    ball_y <= 220;
                end
            end

            // 改进的碰撞检测和响应，添加随机性
            if (collision_cooldown == 0) begin  
                if (((ball_x >= player1_x-10) && (ball_x <= player1_x +15) && 
                     (ball_y +11>= player1_y ) && (ball_y +9 <= player1_y )) ||
                    ((ball_x >= player2_x) && (ball_x <= player2_x + 22) && 
                     (ball_y +11>= player2_y ) && (ball_y +9 <= player2_y ))) begin
                    
                    // 使用LFSR的低3位来生成随机的垂直速度
                    ball_dy <= -3;
                    
                    // 反转x方向速度并添加随机变化
                    if(ball_dx > 0)
                        ball_dx <= -(ball_dx );  // 添加0或1的随机速度
                    else
                        ball_dx <= -ball_dx ;    // 添加0或1的随机速度
                        
                    collision_cooldown <= COLLISION_COOLDOWN_TIME;
                    gravity_accumulator <= 3;
                end
            end

            // 球的位置更新保持不变
            if (ball_move_tick) begin
                ball_move_counter <= 0;
                
                if (ball_y < 220) begin
                    ball_y <= ball_y + ball_dy;
                    ball_x <= ball_x + ball_dx;
                end else begin
                    ball_y <= 220;
                end
            end
        end
    end
end
// 修改重力更新逻辑
// ball移动逻辑
// ball移动逻辑

// VGA 坐标生成
always @(posedge CLOCK_50 or negedge resetn) begin
    if (!resetn) begin
        h_counter <= 0;
        v_counter <= 0;
    end else begin
        VGA_X <= h_counter;
        VGA_Y <= v_counter;

        // 增加水平计数器
        if (h_counter < SCREEN_WIDTH - 1) begin
            h_counter <= h_counter + 1;
        end else begin
            h_counter <= 0;
            // 在每行结束时增加垂直计数器
            if (v_counter < SCREEN_HEIGHT - 1)
                v_counter <= v_counter + 1;
            else
                v_counter <= 0; // 返回顶部
        end
    end
end

always @(posedge CLOCK_50) begin
    case (game_state)
        GAME_STATE_START: begin
            VGA_COLOR <= startbackground_color;
        end
        
        GAME_STATE_PLAYING: begin
            if (player1_active && player1_color != 3'b111)
                VGA_COLOR <= player1_color;
            else if (player2_active && player2_color != 3'b111)
                VGA_COLOR <= player2_color;
            else if (ball_active && ball_color != 3'b110)
                VGA_COLOR <= ball_color;
            else
                VGA_COLOR <= background_color;
        end
        
        GAME_STATE_P1_WIN: begin
            VGA_COLOR <= finish1background_color;
        end
        
        GAME_STATE_P2_WIN: begin
            VGA_COLOR <= finish2background_color;
        end
    endcase
    plot <= 1;
end
function [6:0] seven_seg;
    input [3:0] bin;
    begin
        case (bin)
            4'h0: seven_seg = 7'b1000000;
            4'h1: seven_seg = 7'b1111001;
            4'h2: seven_seg = 7'b0100100;
            4'h3: seven_seg = 7'b0110000;
            4'h4: seven_seg = 7'b0011001;
            4'h5: seven_seg = 7'b0010010;
            4'h6: seven_seg = 7'b0000010;
            4'h7: seven_seg = 7'b1111000;
            4'h8: seven_seg = 7'b0000000;
            4'h9: seven_seg = 7'b0010000;
            default: seven_seg = 7'b1111111;
        endcase
    end
endfunction

// 分数到显示的转换逻辑
//wire [3:0] player1_score_tens = player1_score / 10;
//wire [3:0] player1_score_ones = player1_score % 10;
//wire [3:0] player2_score_tens = player2_score / 10;
//wire [3:0] player2_score_ones = player2_score % 10;
// 新增 reg 定义
reg [3:0] player1_score_tens;
reg [3:0] player1_score_ones;
reg [3:0] player2_score_tens;
reg [3:0] player2_score_ones;

// 在 always 块中计算和初始化
always @(posedge CLOCK_50 or negedge resetn) begin
    if (!resetn) begin
        // 在复位时初始化为 0
        player1_score_tens <= 0;
        player1_score_ones <= 0;
        player2_score_tens <= 0;
        player2_score_ones <= 0;
    end else begin
        // 正常情况下，计算分数的十位和个位
        player1_score_tens <= player1_score / 10;
        player1_score_ones <= player1_score % 10;
        player2_score_tens <= player2_score / 10;
        player2_score_ones <= player2_score % 10;
    end
end

// 7 段数码管显示
assign HEX5 = seven_seg(player1_score_tens);
assign HEX4 = seven_seg(player1_score_ones);
assign HEX1 = seven_seg(player2_score_tens);
assign HEX0 = seven_seg(player2_score_ones);


// VGA 适配器模块
vga_adapter VGA (
    .resetn(resetn),
    .clock(CLOCK_50),
    .colour(VGA_COLOR),
    .x(VGA_X),
    .y(VGA_Y),
    .plot(plot),
    // VGA 信号
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .VGA_BLANK_N(VGA_BLANK_N),
    .VGA_SYNC_N(VGA_SYNC_N),
    .VGA_CLK(VGA_CLK)
);
defparam VGA.RESOLUTION = "320x240";
defparam VGA.MONOCHROME = "FALSE";
defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
defparam VGA.BACKGROUND_IMAGE = "bg.mif"; // 背景图像文件

endmodule