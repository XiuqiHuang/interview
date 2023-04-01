`timescale 1ns / 1ps

module axi_stream_insert_header #(
    parameter DATA_WD = 32,
    parameter DATA_BYTE_WD = DATA_WD / 8,
    parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
) (
    input clk,
    input rst_n,
    input valid_in,
    input [DATA_WD-1 : 0] data_in,
    input [DATA_BYTE_WD-1 : 0] keep_in,
    input last_in,
    output ready_in,
    output reg valid_out,
    output reg [DATA_WD-1 : 0] data_out,
    output reg [DATA_BYTE_WD-1 : 0] keep_out,
    output reg last_out,
    input ready_out,
    input valid_insert,
    input [DATA_WD-1 : 0] data_insert,
    input [DATA_BYTE_WD-1 : 0] keep_insert,
    input [BYTE_CNT_WD-1 : 0] byte_insert_cnt,
    output ready_insert
);

    // 内部信号
    reg [DATA_WD-1 : 0] data_buffer;
    reg [DATA_BYTE_WD-1 : 0] keep_buffer;
    reg last_buffer;
    reg insert_header;
    reg [BYTE_CNT_WD-1 : 0] byte_cnt_buffer;
    // 状态机
    localparam IDLE = 2'b00, DATA = 2'b01, HEADER = 2'b10, MIX = 2'b11;
    reg [1:0] state, next_state;

    // 状态逻辑
    always @(state or valid_in or valid_insert or last_in) begin
        case (state)
            IDLE: next_state = (valid_in && valid_insert) ? HEADER : (valid_in ? DATA : IDLE);
            DATA: next_state = (last_in && valid_in) ? IDLE : DATA;
            HEADER: next_state = (valid_in) ? MIX : HEADER;
            MIX: next_state = (last_buffer && valid_out && ready_out) ? HEADER : MIX;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= next_state;
    end

    // 输出逻辑
    always @(state or data_buffer or keep_buffer or last_buffer or data_in or keep_in or last_in or data_insert or keep_insert) begin
        case (state)
            IDLE: begin
                valid_out = 1'b0;
                data_out = data_in;
                keep_out = keep_in;
                last_out = last_in;
            end
            DATA: begin
                valid_out = valid_in;
                data_out = data_in;
                keep_out = keep_in;
                last_out = last_in;
            end
            HEADER: begin
                valid_out = valid_insert;
                data_out = data_insert;
                keep_out = keep_insert;
                last_out = 1'b0;
            end
            MIX: begin
                valid_out = 1'b1;
                data_out = data_buffer;
                keep_out = keep_buffer;
                last_out = last_buffer;
            end
        endcase
    end

    // 准备逻辑
    assign ready_in = (state == DATA) || (state == IDLE && valid_insert);
    assign ready_insert = (state == HEADER) || (state == IDLE && valid_in);

    // 数据更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_buffer <= 0;
            keep_buffer <= 0;
            last_buffer <= 0;
            insert_header <= 0;
            byte_cnt_buffer <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (valid_in && valid_insert) begin
                        data_buffer <= data_in;
                        keep_buffer <= keep_in;
                        last_buffer <= last_in;
                        insert_header <= 1'b1;
                        byte_cnt_buffer <= byte_insert_cnt - 1;
                    end
                end
                DATA: begin
                
                end
                HEADER: begin
                    if (valid_in) begin
                        data_buffer <= data_in;
                        keep_buffer <= keep_in;
                        last_buffer <= last_in;
                        insert_header <= 1'b0;
                        byte_cnt_buffer <= byte_insert_cnt - 1;
                    end
                end
                MIX: begin
                    if (valid_out && ready_out) begin
                        if (byte_cnt_buffer != 0) begin
                            data_buffer <= {data_buffer[DATA_WD-1-8:0], data_buffer[DATA_WD-1:DATA_WD-8]};
                            keep_buffer <= {keep_buffer[DATA_BYTE_WD-1-1:0], keep_buffer[DATA_BYTE_WD-1]};
                            byte_cnt_buffer <= byte_cnt_buffer - 1;
                        end else begin
                            data_buffer <= data_in;
                            keep_buffer <= keep_in;
                            last_buffer <= last_in;
                            insert_header <= 1'b1;
                            byte_cnt_buffer <= byte_insert_cnt - 1;
                        end
                    end
                end
            endcase
        end
    end

endmodule


