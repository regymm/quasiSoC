// https://github.com/hdl-util/sdram-controller/blob/master/src/sdram_controller.sv
// MIT/Apache License

module sdram_controller #(
    parameter int CLK_RATE, // Speed of your sdram clock in Hz
	parameter int READ_BURST_LENGTH = 1, // 1, 2, 4, 8, or 256 (full page). All other values are reserved.
	parameter int WRITE_BURST = 1, // OFF = Single write mode, ON = Burst write mode (same length as read burst)
	parameter int BANK_ADDRESS_WIDTH,
	parameter int ROW_ADDRESS_WIDTH,
	parameter int COLUMN_ADDRESS_WIDTH,
	parameter int DATA_WIDTH,
	parameter int DQM_WIDTH,
	parameter int CAS_LATENCY,
	// All parameters below are measured in floating point seconds (i.e. 1ns = 1E-9).
	// They should be obtained from the datasheet for your chip.
	parameter real ROW_CYCLE_TIME,
	parameter real RAS_TO_CAS_DELAY,
	parameter real PRECHARGE_TO_REFRESH_OR_ROW_ACTIVATE_SAME_BANK_TIME,
	parameter real ROW_ACTIVATE_TO_ROW_ACTIVATE_DIFFERENT_BANK_TIME,
	parameter real ROW_ACTIVATE_TO_PRECHARGE_SAME_BANK_TIME,
	// Some SDRAM chips require a minimum clock stability time prior to initialization. If it's not in the datasheet, you can try setting it to 0.
	parameter real MINIMUM_STABLE_CONDITION_TIME,
	parameter real MODE_REGISTER_SET_CYCLE_TIME,
	parameter real WRITE_RECOVERY_TIME,
	parameter real AVERAGE_REFRESH_INTERVAL_TIME,

	// Please do not set these parameters
	parameter int USER_ADDRESS_WIDTH = BANK_ADDRESS_WIDTH + ROW_ADDRESS_WIDTH + COLUMN_ADDRESS_WIDTH,
	parameter int CHIP_ADDRESS_WIDTH = (ROW_ADDRESS_WIDTH > COLUMN_ADDRESS_WIDTH ? ROW_ADDRESS_WIDTH : COLUMN_ADDRESS_WIDTH)
) (
	input logic clk,

	// 0 = Idle
	// 1 = Write (with Auto Precharge)
	// 2 = Read (with Auto Precharge)
	// 3 = Self Refresh (TODO)
	input logic [1:0] command,
	input logic [USER_ADDRESS_WIDTH-1:0] data_address,
	input logic [DATA_WIDTH-1:0] data_write,
	output logic [DATA_WIDTH-1:0] data_read,
	output logic data_read_valid = 1'b0, // goes high when a burst-read is ready
	output logic data_write_done = 1'b0, // goes high once the first write of a burst-write / single-write is done

	// These ports should be connected directly to the SDRAM chip
	output logic clock_enable = 1'b0,
	output logic [BANK_ADDRESS_WIDTH-1:0] bank_activate,
	output logic [CHIP_ADDRESS_WIDTH-1:0] address,
	output logic chip_select,
	output logic row_address_strobe,
	output logic column_address_strobe,
	output logic write_enable,
	output logic [DQM_WIDTH-1:0] dqm = {DQM_WIDTH{1'b0}},
	inout wire [DATA_WIDTH-1:0] dq
);

localparam int ROW_CYCLE_CLOCKS = $unsigned(integer'(ROW_CYCLE_TIME * CLK_RATE));
localparam int RAS_TO_CAS_DELAY_CLOCKS = $unsigned(integer'(RAS_TO_CAS_DELAY * CLK_RATE));
localparam int PRECHARGE_TO_REFRESH_OR_ROW_ACTIVATE_SAME_BANK_CLOCKS = $unsigned(integer'(PRECHARGE_TO_REFRESH_OR_ROW_ACTIVATE_SAME_BANK_TIME * CLK_RATE));
localparam int ROW_ACTIVATE_TO_ROW_ACTIVATE_DIFFERENT_BANK_CLOCKS = $unsigned(integer'(ROW_ACTIVATE_TO_ROW_ACTIVATE_DIFFERENT_BANK_TIME * CLK_RATE));
localparam int ROW_ACTIVATE_TO_PRECHARGE_SAME_BANK_CLOCKS = $unsigned(integer'(ROW_ACTIVATE_TO_PRECHARGE_SAME_BANK_TIME * CLK_RATE));
localparam int MINIMUM_STABLE_CONDITION_CLOCKS = $unsigned(integer'(MINIMUM_STABLE_CONDITION_TIME * CLK_RATE));

localparam int MODE_REGISTER_SET_CLOCKS = $unsigned(integer'(MODE_REGISTER_SET_CYCLE_TIME * CLK_RATE));
localparam int WRITE_RECOVERY_CLOCKS = $unsigned(integer'(WRITE_RECOVERY_TIME * CLK_RATE));

localparam int AVERAGE_REFRESH_INTERVAL_CLOCKS = $unsigned(integer'(AVERAGE_REFRESH_INTERVAL_TIME * CLK_RATE));

localparam bit [2:0] STATE_UNINIT = 3'd0;
localparam bit [2:0] STATE_IDLE = 3'd1;
localparam bit [2:0] STATE_WRITING = 3'd2;
localparam bit [2:0] STATE_READING = 3'd3;
localparam bit [2:0] STATE_WAITING = 3'd4;
localparam bit [2:0] STATE_PRECHARGE = 3'd5;
logic [2:0] state = STATE_UNINIT;

localparam int REFRESH_TIMER_WIDTH = $clog2(AVERAGE_REFRESH_INTERVAL_CLOCKS + 1);
localparam bit [REFRESH_TIMER_WIDTH-1:0] REFRESH_TIMER_END = REFRESH_TIMER_WIDTH'(AVERAGE_REFRESH_INTERVAL_CLOCKS);
logic [REFRESH_TIMER_WIDTH-1:0] refresh_timer = REFRESH_TIMER_WIDTH'(0);

always_ff @(posedge clk)
begin
	// TODO: abort a read/write and refresh if it's taking too long (i.e. full-page)
	if (state == STATE_IDLE && refresh_timer >= REFRESH_TIMER_END) // Refresh will always occur from an idle state
		refresh_timer <= REFRESH_TIMER_WIDTH'(0);
	else if (state == STATE_UNINIT)
		refresh_timer <= REFRESH_TIMER_WIDTH'(0);
	else
		refresh_timer <= refresh_timer + 1'd1;
end

localparam int COUNTER_WIDTH = $clog2(MINIMUM_STABLE_CONDITION_CLOCKS + 1); // Row cycle time is the longest delay
logic [COUNTER_WIDTH-1:0] countdown = COUNTER_WIDTH'(0);

// Jump from waiting to a specified state
logic [2:0] destination_state = STATE_UNINIT;

// "Step" counter used for burst write/read counting and initialization steps. Must be at least 3 bits wide.
localparam int STEP_WIDTH = $clog2(READ_BURST_LENGTH == 1 ? $unsigned(8) : $unsigned(READ_BURST_LENGTH + 3 + CAS_LATENCY));
logic [STEP_WIDTH-1:0] step = STEP_WIDTH'(0);

logic [DATA_WIDTH-1:0] internal_dq = DATA_WIDTH'(0);
assign dq = state == STATE_WRITING ? internal_dq : {DATA_WIDTH{1'bz}}; // Tri-State driver


localparam bit [3:0] CMD_BANK_ACTIVATE = 4'd0;
localparam bit [3:0] CMD_BANK_PRECHARGE = 4'd1;
localparam bit [3:0] CMD_PRECHARGE_ALL = 4'd2;
localparam bit [3:0] CMD_WRITE = 4'd3;
localparam bit [3:0] CMD_READ = 4'd4;
localparam bit [3:0] CMD_MODE_REGISTER_SET = 4'd5;
localparam bit [3:0] CMD_NO_OP = 4'd6;
localparam bit [3:0] CMD_BURST_STOP = 4'd7;
localparam bit [3:0] CMD_AUTO_REFRESH = 4'd8;

logic [3:0] internal_command = CMD_NO_OP;
assign chip_select = !(internal_command != CMD_NO_OP);
assign row_address_strobe = !(internal_command == CMD_BANK_ACTIVATE || internal_command == CMD_BANK_PRECHARGE || internal_command == CMD_PRECHARGE_ALL || internal_command == CMD_MODE_REGISTER_SET || internal_command == CMD_AUTO_REFRESH);
assign column_address_strobe = !(internal_command == CMD_WRITE || internal_command == CMD_READ || internal_command == CMD_MODE_REGISTER_SET || internal_command == CMD_AUTO_REFRESH);
assign write_enable = !(internal_command == CMD_BANK_PRECHARGE || internal_command == CMD_PRECHARGE_ALL || internal_command == CMD_WRITE || internal_command == CMD_MODE_REGISTER_SET || internal_command == CMD_BURST_STOP);

logic pending_precharge = 1'd0;

logic [ROW_ADDRESS_WIDTH-1:0] last_row_address;
logic bank_or_row_differs;
assign bank_or_row_differs = bank_activate != data_address[USER_ADDRESS_WIDTH - 1 : USER_ADDRESS_WIDTH - BANK_ADDRESS_WIDTH] || last_row_address != data_address[USER_ADDRESS_WIDTH - 1 - BANK_ADDRESS_WIDTH : USER_ADDRESS_WIDTH - BANK_ADDRESS_WIDTH - ROW_ADDRESS_WIDTH];

always_ff @(posedge clk)
begin
	if (state == STATE_UNINIT)
	begin
		step <= step + 1'd1;
		// See Note 11 on page 20: Power up Sequence
		if (step == 3'd0)
		begin
			state <= STATE_WAITING;
			countdown <= COUNTER_WIDTH'(MINIMUM_STABLE_CONDITION_CLOCKS); // Wait for clock to stabilize
			destination_state <= STATE_UNINIT;
			clock_enable <= 1'b0;
			internal_command <= CMD_NO_OP;
			bank_activate <= {BANK_ADDRESS_WIDTH{1'bx}};
			address <= {CHIP_ADDRESS_WIDTH{1'bx}};
		end
		else if (step == 3'd1) // Power Down Mode Exit
		begin
			clock_enable <= 1'b1;
			internal_command <= CMD_NO_OP;
			bank_activate <= {BANK_ADDRESS_WIDTH{1'bx}};
			address <= {CHIP_ADDRESS_WIDTH{1'bx}};
		end
		else if (step == 3'd2) // Pre-charge all banks
		begin
			state <= STATE_WAITING;
			countdown <= COUNTER_WIDTH'(PRECHARGE_TO_REFRESH_OR_ROW_ACTIVATE_SAME_BANK_CLOCKS - 1);
			destination_state <= STATE_UNINIT;
			internal_command <= CMD_PRECHARGE_ALL;
			bank_activate <= {BANK_ADDRESS_WIDTH{1'bx}};
			if (CHIP_ADDRESS_WIDTH > 11)
				address[CHIP_ADDRESS_WIDTH-1:11] <= {CHIP_ADDRESS_WIDTH-11{1'bx}};
			address[10] <= 1'b1;
			address[9:0] <= 10'dx;
		end
		// else if (step == 3'd3) // Extended mode register set
		// begin
		// 	state <= STATE_WAITING;
		// 	countdown <= COUNTER_WIDTH'(MODE_REGISTER_SET_CLOCKS - 1);
		// 	destination_state <= STATE_UNINIT;
		// 	internal_command <= CMD_MODE_REGISTER_SET;
		// 	bank_activate <= 2'b01;
		// 	address <= {10'd0, 1'b0, 1'b0}; // Full strength driver
		// end
		else if (step == 3'd3) // Mode register set
		begin
			state <= STATE_WAITING;
			countdown <= COUNTER_WIDTH'(MODE_REGISTER_SET_CLOCKS - 1);
			destination_state <= STATE_UNINIT;
			internal_command <= CMD_MODE_REGISTER_SET;
			bank_activate <= {BANK_ADDRESS_WIDTH{1'b0}};
			if (CHIP_ADDRESS_WIDTH > 11)
				address[CHIP_ADDRESS_WIDTH-1:11] <= {CHIP_ADDRESS_WIDTH-11{1'b0}}; // 0 is a safe default for unknown manufacturer-specific mode values
			address[10] <= 1'b0; // Also low, reserved for future use
			address[9] <= WRITE_BURST ? 1'b0: 1'b1;
			address[8:7] <= 2'b00; // Standard operation mode, others reserved for future use
			address[6:4] <= 3'(CAS_LATENCY);
			address[3] <= 1'b0; // Sequential Burst Type
			address[2:0] <= READ_BURST_LENGTH == 1 ? 3'd0 : READ_BURST_LENGTH == 2 ? 3'd1 : READ_BURST_LENGTH == 4 ? 3'd2 : READ_BURST_LENGTH == 8 ? 3'd3 : READ_BURST_LENGTH == 256 ? 3'd7 : 3'd0;
		end
		else if (step == 3'd4 || step == 3'd5) // Double auto refresh
		begin
			state <= STATE_WAITING;
			countdown <= COUNTER_WIDTH'(ROW_CYCLE_CLOCKS - 1);
			destination_state <= step == 3'd5 ? STATE_IDLE : STATE_UNINIT;
			internal_command <= CMD_AUTO_REFRESH;
			bank_activate <= {BANK_ADDRESS_WIDTH{1'bx}};
			address <= {CHIP_ADDRESS_WIDTH{1'bx}};
		end
	end
	else if (state == STATE_IDLE)
	begin
		step <= STEP_WIDTH'(0);
		if (pending_precharge && (bank_or_row_differs || refresh_timer >= REFRESH_TIMER_END / 2))
		begin
			state <= STATE_PRECHARGE;
		end
		else if (refresh_timer >= REFRESH_TIMER_END) // Refresh timer expires
		begin
			state <= STATE_WAITING;
			countdown <= COUNTER_WIDTH'(ROW_CYCLE_CLOCKS - 1);
			destination_state <= STATE_IDLE;
			internal_command <= CMD_AUTO_REFRESH;
			bank_activate <= {BANK_ADDRESS_WIDTH{1'bx}};
			address <= {CHIP_ADDRESS_WIDTH{1'bx}};
		end
		else if (command == 2'd1 || command == 2'd2) // Write or Read (does a bank activate)
		begin
			if (!pending_precharge || bank_or_row_differs)
			begin
				state <= STATE_WAITING;
				countdown <= COUNTER_WIDTH'(RAS_TO_CAS_DELAY_CLOCKS - 1);
				destination_state <= command == 2'd1 ? STATE_WRITING : STATE_READING; // go to the correct state
				internal_command <= CMD_BANK_ACTIVATE;
				bank_activate <= data_address[USER_ADDRESS_WIDTH - 1 : USER_ADDRESS_WIDTH - BANK_ADDRESS_WIDTH];
				address <= data_address[USER_ADDRESS_WIDTH - 1 - BANK_ADDRESS_WIDTH : USER_ADDRESS_WIDTH - BANK_ADDRESS_WIDTH - ROW_ADDRESS_WIDTH];
				last_row_address <= data_address[USER_ADDRESS_WIDTH - 1 - BANK_ADDRESS_WIDTH : USER_ADDRESS_WIDTH - BANK_ADDRESS_WIDTH - ROW_ADDRESS_WIDTH];
			end
			else
			begin
				state <= command == 2'd1 ? STATE_WRITING : STATE_READING; // go to the correct state
				internal_command <= CMD_NO_OP;
			end
		end
		else
		begin
			state <= STATE_IDLE;
			internal_command <= CMD_NO_OP;
			bank_activate <= bank_activate;
			address <= address;
		end
	end
	else if (state == STATE_WRITING)
	begin
		step <= step + 1'd1;
		if (step == STEP_WIDTH'(1)) // Skip the first step clock to reduce the first data_write_done latency by 1 clock for burst writing
		begin
			internal_command <= CMD_WRITE;
			bank_activate <= data_address[USER_ADDRESS_WIDTH - 1 : USER_ADDRESS_WIDTH - BANK_ADDRESS_WIDTH];
			if (CHIP_ADDRESS_WIDTH != COLUMN_ADDRESS_WIDTH)
				address[CHIP_ADDRESS_WIDTH-1:COLUMN_ADDRESS_WIDTH] <= {(CHIP_ADDRESS_WIDTH - COLUMN_ADDRESS_WIDTH){1'b0}};
			address[COLUMN_ADDRESS_WIDTH-1:0] <= data_address[USER_ADDRESS_WIDTH - 1 - BANK_ADDRESS_WIDTH - ROW_ADDRESS_WIDTH : 0];
		end
		else
		begin
			internal_command <= CMD_NO_OP;
			bank_activate <= bank_activate;
			address <= address;
		end

		if (step == STEP_WIDTH'(WRITE_BURST ? READ_BURST_LENGTH + 1 : 1 + 1)) // Last write just finished
		begin
			state <= STATE_WAITING;
			countdown <= COUNTER_WIDTH'(WRITE_RECOVERY_CLOCKS - 2);
			if (bank_or_row_differs)
			begin
				destination_state <= STATE_PRECHARGE;
				pending_precharge <= 1'b1;
			end
			else
			begin
				destination_state <= STATE_IDLE;
				pending_precharge <= 1'b1;
			end
			data_write_done <= 1'b0;
			internal_dq <= {DATA_WIDTH{1'b0}};
		end
		else if (step == STEP_WIDTH'(WRITE_BURST ? READ_BURST_LENGTH : 1)) // Last write about to happen
		begin
			data_write_done <= 1'b0;
			internal_dq <= data_write;
		end
		else // Still writing
		begin
			data_write_done <= 1'b1;
			internal_dq <= data_write;
		end
	end
	else if (state == STATE_READING)
	begin
		internal_dq <= {DATA_WIDTH{1'bx}};
		step <= step + 1'd1;
		if (step == STEP_WIDTH'(0)) // Read
		begin
			internal_command <= CMD_READ;
			bank_activate <= data_address[USER_ADDRESS_WIDTH - 1 : USER_ADDRESS_WIDTH - BANK_ADDRESS_WIDTH];
			if (CHIP_ADDRESS_WIDTH > 11)
				address[CHIP_ADDRESS_WIDTH-1:11] <= {CHIP_ADDRESS_WIDTH-11{1'bx}};
			address[10] <= 1'b0;
			if (COLUMN_ADDRESS_WIDTH < 10)
				address[9:COLUMN_ADDRESS_WIDTH] <= {10-COLUMN_ADDRESS_WIDTH{1'bx}};
			address[COLUMN_ADDRESS_WIDTH-1:0] <= data_address[USER_ADDRESS_WIDTH - 1 - BANK_ADDRESS_WIDTH - ROW_ADDRESS_WIDTH : 0];
		end
		else // No-Operation
		begin
			internal_command <= CMD_NO_OP;
			bank_activate <= bank_activate;
			address <= address;
		end

		if (step == STEP_WIDTH'(CAS_LATENCY + READ_BURST_LENGTH + 2)) // Last read just finished
		begin
			if (bank_or_row_differs)
			begin
				state <= STATE_PRECHARGE;
				pending_precharge <= 1'b1;
			end
			else
			begin
				state <= STATE_IDLE;
				pending_precharge <= 1'b1;
			end
			data_read_valid <= 1'b0;
		end
		else if (step >= STEP_WIDTH'(CAS_LATENCY + 2)) // Still reading
		begin
			data_read <= dq;
			data_read_valid <= 1'b1;
		end
		else
		begin
			data_read <= {DATA_WIDTH{1'bx}};
			data_read_valid <= 1'd0;
		end
	end
	else if (state == STATE_WAITING)
	begin
		if (countdown == COUNTER_WIDTH'(0))
			state <= destination_state;
		else
			countdown <= countdown - 1'd1;
		internal_command <= CMD_NO_OP;
		bank_activate <= bank_activate;
		address <= address;
	end
	else if (state == STATE_PRECHARGE)
	begin
		state <= STATE_WAITING;
		destination_state <= STATE_IDLE;
		countdown <= COUNTER_WIDTH'(PRECHARGE_TO_REFRESH_OR_ROW_ACTIVATE_SAME_BANK_CLOCKS - 1);
		internal_command <= CMD_BANK_PRECHARGE;
		pending_precharge <= 1'b0;

		bank_activate <= bank_activate;
		if (CHIP_ADDRESS_WIDTH > 11)
			address[CHIP_ADDRESS_WIDTH-1:11] <= {CHIP_ADDRESS_WIDTH-11{1'bx}};
		address[10] <= 1'b1;
		address[9:0] <= 10'dx;
	end
end

endmodule
