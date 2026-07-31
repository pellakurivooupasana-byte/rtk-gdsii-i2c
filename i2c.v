module i2c_multimaster (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [6:0] slave_addr,
    input wire [7:0] data,
    inout wire sda,
    inout wire scl
);

    parameter IDLE      = 3'd0;
    parameter START     = 3'd1;
    parameter SEND_ADDR = 3'd2;
    parameter ACK_WAIT  = 3'd3;
    parameter SEND_DATA = 3'd4;
    parameter STOP      = 3'd5;

    reg [2:0] state;
    reg [2:0] bit_cnt;

    reg sda_en, sda_out;
    reg scl_en;

    wire sda_in;
    wire scl_in;

    assign sda = (sda_en) ? sda_out : 1'bz;
    assign scl = (scl_en) ? 1'b0 : 1'bz;

    assign sda_in = sda;
    assign scl_in = scl;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state   <= IDLE;
            bit_cnt <= 3'd6;
            sda_en  <= 0;
            sda_out <= 1;
            scl_en  <= 0;
        end
        else begin
            case (state)

                IDLE: begin
                    sda_en  <= 0;
                    scl_en  <= 0;
                    bit_cnt <= 3'd6;

                    if (start)
                        state <= START;
                end

                START: begin
                    sda_en  <= 1;
                    sda_out <= 0;
                    state   <= SEND_ADDR;
                end

                SEND_ADDR: begin

                    // Clock stretching
                    if (scl_in == 0)
                        state <= SEND_ADDR;
                    else begin
                        sda_en  <= 1;
                        sda_out <= slave_addr[bit_cnt];

                        // Arbitration check
                        if (sda_out == 1'b1 && sda_in == 1'b0) begin
                            state <= IDLE;
                            sda_en <= 0;
                            scl_en <= 0;
                        end
                        else if (bit_cnt == 0)
                            state <= ACK_WAIT;
                        else
                            bit_cnt <= bit_cnt - 1'b1;
                    end
                end

                ACK_WAIT: begin
                    sda_en <= 0;

                    if (sda_in == 0) begin
                        bit_cnt <= 3'd7;
                        state   <= SEND_DATA;
                    end
                    else
                        state <= STOP;
                end

                SEND_DATA: begin

                    // Clock stretching
                    if (scl_in == 0)
                        state <= SEND_DATA;
                    else begin
                        sda_en  <= 1;
                        sda_out <= data[bit_cnt];

                        // Arbitration check
                        if (sda_out == 1'b1 && sda_in == 1'b0) begin
                            state <= IDLE;
                            sda_en <= 0;
                            scl_en <= 0;
                        end
                        else if (bit_cnt == 0)
                            state <= STOP;
                        else
                            bit_cnt <= bit_cnt - 1'b1;
                    end
                end

                STOP: begin
                    sda_en  <= 1;
                    sda_out <= 1;
                    scl_en  <= 0;
                    state   <= IDLE;
                end

                default:
                    state <= IDLE;

            endcase
        end
    end

endmodule
