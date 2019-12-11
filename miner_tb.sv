`default_nettype none
`timescale 1 ns / 10 ps
`define GEN_CNT_P 10
`define GEN_CNT_R 50

module miner_tb;
	logic[639:0] message;
	logic [255:0] hashed;
	logic clk, rst, done;

	logic [255:0] rst_hashed[`GEN_CNT_P][`GEN_CNT_R];
	logic rst_done [`GEN_CNT_P][`GEN_CNT_R] ;	
	logic rst_rst [`GEN_CNT_P][`GEN_CNT_R] ;	

	//miner uut (.block(message), .hashed(hashed), .clk(clk), .rst(rst), .done(done));

	genvar i ;
	genvar j ;

	for (i=0;i<`GEN_CNT_P;i=i+1) begin
		for (j=0;j<`GEN_CNT_R;j=j+1) begin
			if (j==0) begin
				miner uut (
					.block(message & (message << i)), 
					.hashed(rst_hashed[i][j]), 
					.clk(clk), 
					.rst(rst), 
					.done(rst_done[i][j])
				);
			end
			else begin
				miner uut (
					.block({384'b0,rst_hashed[i][j-1]}), 
					.hashed(rst_hashed[i][j]), 
					.clk(clk), 
					.rst(rst_rst[i][j]), 
					.done(rst_done[i][j])
				);
			end
		end
	end

	integer ii ;
	integer jj ;
	always @ (posedge clk) begin
		for (ii=0;ii<`GEN_CNT_P;ii=ii+1) begin
			for (jj=0;jj<`GEN_CNT_R-1;jj=jj+1) begin
				if (rst_done [ii][jj] == 1'b1) begin
					rst_rst[ii][jj+1] <= 'b0 ;
				end
			end
		end
	end

	
	always @ (posedge clk) begin
		for (ii=0;ii<`GEN_CNT_P;ii=ii+1) begin
			for (jj=0;jj<`GEN_CNT_R;jj=jj+1) begin
				if (ii==0 && jj == 0) begin
					done = rst_done[ii][jj] ;
					hashed = rst_hashed[ii][jj] ;
				end
				else begin
					done = done & rst_done[ii][jj] ;
					hashed = hashed | rst_hashed[ii][jj] ;
				end
			end
		end
	end

	reg[31:0] cnt ;
	always @ (posedge clk) begin
		cnt = cnt + 1; 
		if (cnt[4:0] =='h0) begin
			for (ii=0;ii<`GEN_CNT_P;ii=ii+1) begin
				for (jj=0;jj<`GEN_CNT_R;jj=jj+1) begin
					if (rst_done[ii][jj] == 1) begin
						$display ("\t%x.",rst_hashed [ii][jj]) ;
					end
					else begin
						$display ("%d clocks index %d %d done %x rst %x.",
							cnt,ii,jj,rst_done[ii][jj],rst_rst[ii][jj]) ;
					end
				end
			end
		end
	end

	initial begin
    	clk = 0;
		forever #5 clk = ~clk ;
	end

	initial begin
    	$dumpfile("miner_tb.vcd");
    	$dumpvars;
    	message = 640'h0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a29ab5f49ffff001d1dac2b7c;
		done = 0 ;
		cnt = 'h0 ;
		for (ii=0;ii<`GEN_CNT_P;ii=ii+1) begin
			for (jj=0;jj<`GEN_CNT_R;jj=jj+1) begin
				rst_rst[ii][jj] = 'b1 ;
			end
		end
    	rst = 1; #5
    	rst = 0;
    	$display("%d clocks Begin miner_tb",cnt);
    	while(done !== 1'b1) begin
    		//assign clk = ~clk;
    		#5;
    	end
		#1000 ;
    	$display("%d clocks FINISHED miner_tb", cnt);
    	$finish;
	end
endmodule