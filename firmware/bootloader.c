// Load DOOM from SD Card and jump to engine execution

#include <stdint.h>

// Address Map
#define SDCARD_BASE 0x40000000
#define SDRAM_BASE  0x80000000

#define APP_SIZE    0x00010000
#define PROG_ENTRY  0x80000000

// Linker aliases
extern uint8_t _sidata[];
extern uint8_t _sdata[];
extern uint8_t _edata[];
extern uint8_t _sbss[];
extern uint8_t _ebss[];


void bootloader(void);

void __attribute__((naked, section(".boot"))) _start(void) {
    // Initialize stack pointer
    __asm("la sp, __stack_top");
    // Jump to C function
    __asm("j bootloader");
}

void __attribute__((noreturn)) bootloader(void) {
    // copy .data section from ROM to RAM
    uint8_t* src = _sidata;
    uint8_t* dst = _sdata;
    while (dst < _edata){
        *dst++ = *src++;
    }
    
    // zero initialize .bss
    uint8_t* bss = _sbss;
    while (bss < _ebss){
        *bss++ = 0;
    }

    // // Copy the program from SD Card to SDRAM
    // volatile uint32_t *src = (volatile uint32_t *)SDCARD_BASE;
    // volatile uint32_t *dst = (volatile uint32_t *)SDRAM_BASE;
    // uint32_t words_to_copy = APP_SIZE / 4;
    
    // for (uint32_t i = 0; i < words_to_copy; i++) {
    //     dst[i] = src[i];
    // }

    // // Jump to program entry
    // ((void (*)(void))PROG_ENTRY)();

    // Draw a picture to the frame buffer and then spin forever
    volatile uint32_t *fb_base = (volatile uint32_t *)0x30000000;

    while (1) {
        for (int x = 0; x < 80; x++) {

            int prev_x = (x == 0) ? 79 : (x - 1);

            for (int y = 0; y < 200; y++) {
                fb_base[prev_x + y * 80] = 0x00000000;
            }

            for (int y = 0; y < 200; y++) {
                fb_base[x + y * 80] = 0xC0C0C0C0;
            }

            for (int d = 0; d < 140000; d++) asm volatile ("nop");
        }
    }
}