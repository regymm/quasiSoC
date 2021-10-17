// pComputer basic MMIO library
#ifndef MMIO_BASIC_H
#define MMIO_BASIC_H
extern volatile int* uart_tx;
extern volatile int* uart_tx_done;
extern volatile int* uart_rx_reset;
extern volatile int* uart_rx_new;
extern volatile int* uart_rx_data;

extern volatile int* psram_base;

extern volatile int* video_base;

extern volatile int* distram_base;

extern volatile int* sd_cache_base;
extern volatile int* sd_address;
extern volatile int* sd_do_read;
extern volatile int* sd_do_write;
extern volatile int* sd_ncd;
extern volatile int* sd_ready;
extern volatile int* sd_cache_dirty;

extern volatile int* gpio_ctrl;

extern volatile int* uart_dma_ctrl;

char uart_getchar();
void uart_putchar(char c);
void uart_putstr(const char* str);
#endif
