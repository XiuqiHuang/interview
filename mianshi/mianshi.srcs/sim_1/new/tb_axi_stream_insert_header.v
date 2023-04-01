`timescale 1ns / 1ps

module tb_axi_stream_insert_header;

    parameter DATA_WD = 32;
    parameter DATA_BYTE_WD = DATA_WD / 8;
    parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD);

    reg clk;
    reg rst_n;
    reg valid_in;
    reg [DATA_WD-1 : 0] data_in;
    reg [DATA_BYTE_WD-1 : 0] keep_in;
    reg last_in;
    wire ready_in;
    wire valid_out;
    wire [DATA_WD-1 : 0] data_out;
    wire [DATA_BYTE_WD-1 : 0] keep_out;
    wire last_out;
    reg ready_out;
    reg valid_insert;
    reg [DATA_WD-1 : 0] data_insert;
    reg [DATA_BYTE_WD-1 : 0] keep_insert;
    reg [BYTE_CNT_WD-1 : 0] byte_insert_cnt;
    wire ready_insert;

    // Instantiate the design under test (DUT)
    axi_stream_insert_header #(
        .DATA_WD(DATA_WD),
        .DATA_BYTE_WD(DATA_BYTE_WD),
        .BYTE_CNT_WD(BYTE_CNT_WD)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .data_in(data_in),
        .keep_in(keep_in),
        .last_in(last_in),
        .ready_in(ready_in),
        .valid_out(valid_out),
        .data_out(data_out),
        .keep_out(keep_out),
        .last_out(last_out),
        .ready_out(ready_out),
        .valid_insert(valid_insert),
        .data_insert(data_insert),
        .keep_insert(keep_insert),
        .byte_insert_cnt(byte_insert_cnt),
        .ready_insert(ready_insert)
    );

    always begin
        #5 clk = ~clk;
    end

    initial begin
        clk = 0;
        rst_n = 0;
        valid_in = 0;
        data_in = 0;
        keep_in = 0;
        last_in = 0;
        ready_out = 1;
        valid_insert = 0;
        data_insert = 0;
        keep_insert = 0;
        byte_insert_cnt = 0;

        #10 rst_n = 1;

        valid_insert = 1;
        data_insert = 32'hDEADBEEF;
        keep_insert = 4'b1111;
        byte_insert_cnt = 4;
        valid_in = 1;
        data_in = 32'h12345678;
        keep_in = 4'b1111;
        last_in = 1;

        #20 if (valid_out) begin
                if (data_out !== data_insert || keep_out !== keep_insert || last_out !== 0) $display("Error: Mismatch on first output data");
            end
        #20 if (valid_out) begin
                if (data_out !== data_in || keep_out !== keep_in || last_out !== 1) $display("Error: Mismatch on second output data");
            end

        #20 valid_insert = 1;
        data_insert = 32'hCAFEBABE;
        keep_insert = 4'b0111;
        byte_insert_cnt = 3;

        valid_in = 1;
        data_in = 32'h89ABCDEF;
        keep_in = 4'b1111;
        last_in = 1;

        #20 if (valid_out) begin
                if (data_out !== {data_insert[23:0], data_in[31:24]} || keep_out !== keep_insert || last_out !== 0) $display("Error: Mismatch on third output data");
            end
        #20 if (valid_out) begin
                if (data_out !== {data_in[23:0], 8'b00000000} || keep_out !== 4'b1110 || last_out !== 1) $display("Error: Mismatch on fourth output data");
            end
    end

endmodule
