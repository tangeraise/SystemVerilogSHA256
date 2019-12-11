iverilog:
	iverilog -o simv -g2012 miner_tb.sv miner.sv sha_256.sv sha_mainloop.sv sha_padder.sv

run:
	./simv
