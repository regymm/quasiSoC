//`define SIMULATION
// CPU features
`define RV32M
`define RV32A
`define IRQ_EN
`define MMU_EN


`ifdef SIMULATION
//	`define GPIO_EN
	`define UART_EN
//	`define CACHE_EN
//	`define MEM_SIMU_EN
//	`define SERIALBOOT_EN
//	`define UART_RST_EN
`else
	// peripheral features
	`define GPIO_EN
	`define UART_EN
	`define DDR_EN
	//`define PSRAM_EN
	//`define CACHE_EN
	`define SDCARD_EN
	//`define CH375B_EN
    `define VIDEO_EN
	//`define LCD_EN
	//`define PS2_EN
	//`define ETH_EN

	`define SERIALBOOT_EN
	`define UART_RST_EN

	//`define AXI_GPIO_TEST
`endif


