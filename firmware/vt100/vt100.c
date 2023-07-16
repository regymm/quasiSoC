/**
 * File              : vt100.c
 * License           : GPL-3.0-or-later
 * Author            : Peter Gu <github.com/regymm>
 * Date              : 2023.05.23
 * Last Modified Date: 2023.05.23
 */
// VT100 firmware running on 8 KB memory (possibly 4 KB ROM + 4 KB RAM)
// running on quasisoc/pcpu and (previously) heteroterminal/vexriscv
/*typedef unsigned char uint8_t;*/

#define ROWS 24
#define COLS 80
#define BUFFER_LIM 512
extern void cpld_write_cmd(int addr, int data);
extern int cpld_is_ready();
extern int rx_has_new();
extern int rx_val();
extern int rx_next();
/*extern int led(int);*/
unsigned volatile int* const hdmi_fb = (unsigned int*) 0xC000; // to 0x87FC
unsigned int* const fb = (unsigned int*) 0x4000; // to 0x87FC
unsigned int* const buf = (unsigned int*) 0x4800; // uart buffer
int* const head = (int*) 0x4FFC;
int* const tail = (int*) 0x4FF8;
int* const scroll_start = (int*) 0x4FF4;
int* const scroll_end = (int*) 0x4FF0;

static inline void rx_to_queue()
{
	while (rx_has_new()) {
		unsigned int c = rx_val();
		rx_next();
		if (c == 0) continue;
		// check full
		int t = (*tail) ;
		int flg = (t&0x3) * 8;
		/*unsigned int buf_elem = buf[t >> 2];*/
		buf[t>>2] = (buf[t>>2] & (~(0xFF << flg))) + (c << flg);
		/*if (flg == 0) {*/
			/*buf[t >> 2] = (buf_elem & 0xFFFFFF00) + c;*/
		/*} else if (flg == 1) {*/
			/*buf[t >> 2] = (buf_elem & 0xFFFF00FF) + (c << 8);*/
		/*} else if (flg == 2) {*/
			/*buf[t >> 2] = (buf_elem & 0xFF00FFFF) + (c << 16);*/
		/*} else if (flg == 3) {*/
			/*buf[t >> 2] = (buf_elem & 0x00FFFFFF) + (c << 24);*/
		/*}*/
		*tail = t == 1023 ? 0 : t + 1;
		if (*tail == *head) { // overflow!
			/*led(3);*/
			/*int i;*/
			/*for (i = 0; i < 100000; i++);*/
			/*led(1);*/
			/*for (i = 0; i < 100000; i++);*/
		}
	}
}

static inline int dequeue()
{
	int h = *head;
	unsigned int buf_elem = buf[h >> 2];
	*head = h == 1023 ? 0 : h + 1;
	int flg = (h & 3) * 8;
	return (buf_elem & (0xFF << flg)) >> flg;
	/*if (flg == 0)*/
		/*return buf_elem & 0x000000FF;*/
	/*if (flg == 1)*/
		/*return (buf_elem & 0x0000FF00) >> 8;*/
	/*if (flg == 2)*/
		/*return (buf_elem & 0x00FF0000) >> 16;*/
	/*if (flg == 3)*/
		/*return (buf_elem & 0xFF000000) >> 24;*/
	/*return -1;*/
}

static inline  void cpld_wait_safe()
{
	/*while (1) {*/
		rx_to_queue();
		/*[>if (*((int *)0xf000)) return;<]*/
		/*if (cpld_is_ready()) return;*/
	/*}*/
}

static inline void lcd_wchar_safe(int x, int y, int c, int iscursor)
{
	hdmi_fb[x + y * COLS] = (iscursor ? 0xf000 : 0x0f00) + (c & 0xff);
	cpld_wait_safe();
	/*cpld_write_cmd(2, x);*/
	/*cpld_write_cmd(3, y);*/
	/*cpld_write_cmd(4, c);*/
}

static inline void buf_wchar(int x, int y, int c)
{
	// also write to buffer
	unsigned int idx = (y * COLS + x) >> 2;
	int i4 = (x & 0x3) * 8;
	/*unsigned int c4 = fb[idx];*/
	if (idx > (BUFFER_LIM - 1)) {
		/*led(2);*/
		return;
	}
	fb[idx] = (fb[idx] & (~(0xFF << i4))) + (c << i4);
}

static inline void scroll_down(int* pos_y)
{
	if (*pos_y == *scroll_end) {
		// if no scroll control
		int i, j;
		for (i = 20 * *scroll_start; i < 20 * *scroll_end; i++) {
			fb[i] = fb[i + 20];
			cpld_wait_safe();
		}
		/*for (j = 0; j < 23; j++) {*/
			/*for (i = 0; i < 20; i++) {*/
				/*fb[j*20 + i] = fb[(j+1)*20 + i];*/
			/*}*/
			/*cpld_wait_safe();*/
		/*}*/
		for (i = 0; i < 20; i++)
			fb[*scroll_end * 20 + i] = 0x20202020;
		/*// write to LCD, all*/
		/*for (j = 0; j < 24; j++)*/
			/*for (i = 0; i < 80; i++) {*/
				/*lcd_wchar_safe(i, j, fb[(j*80+i)>>2] >> ((i&0x3)*8), 0);*/
			/*}*/
	}
	else *pos_y = (*pos_y == (ROWS - 1) ? (ROWS - 1) : *pos_y + 1);
	/*else if (*pos_y < *scroll_start || *pos_y > *scroll_end) *pos_y = *pos_y + 1;*/
}

static inline void scroll_up(int* pos_y)
{
	int i;
	if (*pos_y == *scroll_start) {
		for (i = 20 * *scroll_end - 1; i >= (*scroll_start + 1) * 20; i--) {
			fb[i] = fb[i - 20];
			cpld_wait_safe();
		}
		for (i = 20 * *scroll_start; i < 20 * (*scroll_start + 1); i++)
			fb[i] = 0x20202020;
	}
	else *pos_y = (*pos_y == 0 ? 0 : *pos_y - 1);
}

void (* csiarr) = (void (*))0x8E00;

void c_start()
{
	// cursor position
	int pos_x;
	int pos_y;
	int cursor_show;
	pos_x = 0;
	pos_y = 0;
	cursor_show = 1;
	*head = 0;
	*tail = 0;
	*scroll_start = 0;
	*scroll_end = ROWS - 1;
	
	// VT100 seqs
	int in_esc_seq = 0; // 0: none, 1: esc, 2: csi, 3: qmark
	int csi_param[10];
	int csi_param_cnt = 0;

	int on_line_end = 0; // 80th char printed, hide cursor

	int i, j;
	// clear all, including cursor
	for (i = 0; i < 80; i++) {
		for (j = 0; j < 40; j++) {
			buf_wchar(i, j, ' ');
			lcd_wchar_safe(i, j, ' ', 0);
			/*lcd_wchar_safe(&buf_head, &buf_tail, i, j, ' ', 1);*/
			/*while(!cpld_is_ready());*/
			/*cpld_write_cmd(2, i);*/
			/*cpld_write_cmd(3, j);*/
			/*cpld_write_cmd(4,  ' ');*/

			/*while(!cpld_is_ready());*/
			/*cpld_write_cmd(1, 0);*/
		}
	}

	while (1) {
		cpld_wait_safe();
		// commit -- sync
		while (*head != *tail) {
			cpld_wait_safe();
			/*cpld_write_cmd(1, 0);*/
			unsigned int c = dequeue();
			// handle char c
			if (c < '\x20') {
				/*if (c == '\x00') {*/
					cpld_wait_safe();
				/*} else if (c == '\x07') { // BELL*/
					/*cpld_wait_safe();*/
				/*} else*/
				if (c == '\x08') { // Backspace
					cpld_wait_safe();
					/*pos_x = pos_x == 0 ? 0 : pos_x - 1;*/
					pos_x--;
				} else if (c == '\x09') { // TAB
					/*pos_x = ((pos_x >> 2) << 2) + 4;*/
					pos_x = (pos_x | 0x3) + 1;
					/*if (pos_x > 79) pos_x = 79;*/
				} else if (c == '\x0A') { // Line feed
					on_line_end = 0;
					scroll_down(&pos_y);
				} else if (c == '\x0D') { // Carriage return
					pos_x = 0;
				} else if (c == '\x1B') { // Escape
					in_esc_seq = 1;
					for (i = 0; i < 9; i++) csi_param[i] = 0;
					csi_param_cnt = 0;
				}
				/*else if (c < ' ') {*/
					cpld_wait_safe();
				/*} // don't let unsupported controls poision our eyes*/
			}
			else if (in_esc_seq == 1) { // ^[
				cpld_wait_safe();
				in_esc_seq = 0;
				if (c == '[') in_esc_seq = 2;
				else if (c == 'M') { // scroll up
					/*pos_x = 0;*/
					scroll_up(&pos_y);
				}
			} else if (in_esc_seq == 2) { // ^[[
				cpld_wait_safe();
				if (c == '?') {
					in_esc_seq = 3;
				}
				else if (c == ';') {
					csi_param_cnt++;
				}
				else if (c <= '9') {
					csi_param[csi_param_cnt] = csi_param[csi_param_cnt] * 10 + c - '0';
				}
				else {
					in_esc_seq = 0;
					int move = csi_param[0] == 0 ? 1 : csi_param[0];
					if (c == 'A') {
						pos_y = pos_y - move;
						/*if (pos_y < 0) pos_y = 0;*/
						/*on_line_end = 0;*/
					} else if (c == 'B') {
						pos_y = pos_y + move;
						/*if (pos_y > 23) pos_y = 23;*/
						/*on_line_end = 0;*/
					} else if (c == 'C') {
						pos_x = pos_x + move;
						/*if (pos_x > 79) pos_y = 79;*/
						/*on_line_end = 0;*/
					} else if (c == 'D') {
						pos_x = pos_x - move;
						/*if (pos_x < 0) pos_y = 0;*/
						/*on_line_end = 0;*/
					} else if (c == 'G') {
						pos_y = csi_param[0] - 1;
					} else if (c == 'H') {
						/*pos_x = csi_param[0] == 0 ? 0 : (csi_param[0] - 1);*/
						/*pos_y = csi_param[1] == 0 ? 0 : (csi_param[1] - 1);*/
						pos_y = csi_param[0] - 1;
						pos_x = csi_param[1] - 1;
						on_line_end = 0;
						/*if (pos_y > 23) pos_y = 23;*/
						/*if (pos_x > 79) pos_x = 79;*/
					} else if (c == 'J') {
						/*for(j = 0; j < 24; j++) {*/
							/*for (i = 0; i < 80; i++) {*/
								/*buf_wchar(i, j, ' ');*/
							/*}*/
							/*cpld_wait_safe();*/
						/*}*/
						int clear_start = csi_param[0] == 0 ? (pos_x + pos_y * COLS) : 0;
						int clear_end = csi_param[0] == 1 ? (pos_x + pos_y * COLS) : (COLS * ROWS - 1);
						for (i = clear_start; i <= clear_end; i++) {
							int i4 = (i & 0x3) * 8;
							if (i>>2 < BUFFER_LIM)
								fb[i>>2] = (fb[i>>2] & (~(0xFF<<i4))) + (' ' << i4);
							cpld_wait_safe();
						}
						/*pos_x = 0; pos_y = 0;*/
					} else if (c == 'K') {
						int clrstart = csi_param[0] == 0 ? pos_x : 0;
						int clrend = csi_param[0] == 1 ? pos_x : (COLS - 1);
						for (i = clrstart; i <= clrend; i++) {
							buf_wchar(i, pos_y, ' ');
							cpld_wait_safe();
						}
						on_line_end = 0;
					} else if (c == 'P') {
						/*for (i = pos_x; i < pos_x + (csi_param[0] == 0 ? 1 : csi_param[0]); i++)*/
							/*buf_wchar(i, pos_y, ' ');*/
					} else if (c == 'r') { // set scroll region
						int is_all = csi_param[0] + csi_param[1];
						*scroll_start = is_all ? csi_param[0]-1 : 0;
						*scroll_end = is_all ? csi_param[1]-1 : (ROWS - 1);
						pos_y = 0; // cursor to top
					}
				}
			} else if (in_esc_seq == 3) { // ^[[?
				cpld_wait_safe();
				/*if (c >= '0' && c <= '9')*/
				if (c <= '9')
					;
					/*csi_param[0] = csi_param[0] * 10 + c - '0';*/
				else { // hide/show cursor is the only supported
					in_esc_seq = 0;
					/*if (csi_param[0] == 25) {*/
						/*if (c == 'h') cursor_show = 1;*/
						/*else if (c == 'l') cursor_show = 0;*/
					/*}*/
				}
			} else { // normal char
				cpld_wait_safe();
				in_esc_seq = 0;
				if (on_line_end) {
					on_line_end = 0;
					scroll_down(&pos_y);
					pos_x = 0;
					// pos_y auto updated
				}
				buf_wchar(pos_x, pos_y, c);
				if (pos_x == (COLS - 1)) on_line_end = 1;
				pos_x = pos_x + 1;
				/*if (pos_x == 80) {*/
					/*on_line_end = 1;*/
					/*pos_x = 79;*/
				/*}*/
			}
			if (pos_x > (COLS - 1)) pos_x = (COLS - 1);
			else if (pos_x < 0) pos_x = 0;
			if (pos_y > (ROWS - 1)) pos_y = (ROWS - 1);
			else if (pos_y < 0) pos_y = 0;
		}
		// sync to CPLD
		for (j = 0; j < ROWS; j++)
			for (i = 0; i < COLS; i++) {
				lcd_wchar_safe(i, j, fb[(j*COLS+i)>>2] >> ((i&0x3)*8), i == pos_x && j == pos_y);
			}
		cpld_wait_safe();
		/*cpld_write_cmd(2, pos_x);*/
		/*cpld_write_cmd(3, pos_y);*/
		/*cpld_write_cmd(5, 0);*/
	}
}
