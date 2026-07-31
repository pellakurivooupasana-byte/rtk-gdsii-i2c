module i2c_multimaster_tb;

    reg clk;
    reg rst;
    reg start;
    reg [6:0] slave_addr;
    reg [7:0] data;

    wire sda;
    wire scl;
    reg sda_slave;

    // SDA line
    assign sda = (sda_slave == 1'b0) ? 1'b0 : 1'bz;

    // DUT
    i2c_multimaster uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .slave_addr(slave_addr),
        .data(data),
        .sda(sda),
        .scl(scl)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Slave ACK generation (simple)
    initial begin
        sda_slave = 1'bz;

        #180;          // Approximate ACK time
        sda_slave = 1'b0;

        #20;
        sda_slave = 1'bz;
    end

    // Test sequence
    initial begin
        rst = 1;
        start = 0;
        slave_addr = 7'h42;
        data = 8'hAA;

        #20;
        rst = 0;

        #20;
        start = 1;

        #10;
        start = 0;

        #500;
        $stop;
    end

    // Monitor
    initial begin
        $monitor("Time=%0t State=%0d SCL=%b SDA=%b",
                  $time, uut.state, scl, sda);
    end

endmodule
