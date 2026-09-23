#ifndef SHRIKE_LINK6_H
#define SHRIKE_LINK6_H

#include <stdint.h>
#include <stdbool.h>

#define LINK6_PIN_PWR   12
#define LINK6_PIN_EN    13
#define LINK6_PIN_SCK   2
#define LINK6_PIN_CS    1
#define LINK6_PIN_MOSI  3
#define LINK6_PIN_MISO  0
#define LINK6_PIN_IRQ   14
#define LINK6_PIN_TRIG  15

#define LINK6_REG_ID              0x00
#define LINK6_REG_VER             0x01
#define LINK6_REG_CAPS            0x02
#define LINK6_REG_STATUS          0x03
#define LINK6_REG_IRQ_MASK        0x04
#define LINK6_REG_CTRL            0x05
#define LINK6_REG_PWM_PERIOD_LO   0x10
#define LINK6_REG_PWM_PERIOD_HI   0x11
#define LINK6_REG_PWM_DUTY_LO     0x12
#define LINK6_REG_PWM_DUTY_HI     0x13
#define LINK6_REG_UART_DIV_LO     0x20
#define LINK6_REG_UART_DIV_HI     0x21
#define LINK6_REG_UART_TX         0x22
#define LINK6_REG_UART_RX         0x23
#define LINK6_REG_SMP_CTRL        0x30
#define LINK6_REG_SMP_WIDTH_LO    0x31
#define LINK6_REG_SMP_WIDTH_HI    0x32
#define LINK6_REG_SMP_PERIOD_LO   0x33
#define LINK6_REG_SMP_PERIOD_HI   0x34

#define LINK6_ID_MAGIC  0xE6
#define LINK6_SYS_HZ    50000000u

#define LINK6_CTRL_CORE (1u << 0)
#define LINK6_CTRL_LED  (1u << 1)
#define LINK6_CTRL_PWM  (1u << 2)
#define LINK6_CTRL_UART (1u << 3)
#define LINK6_CTRL_SMP  (1u << 4)

static inline uint16_t link6_frame_write(uint8_t addr, uint8_t data)
{
    return (uint16_t)((1u << 15) | ((addr & 0x7Fu) << 8) | data);
}

static inline uint16_t link6_frame_read(uint8_t addr)
{
    return (uint16_t)((addr & 0x7Fu) << 8);
}

static inline uint32_t link6_pwm_period(uint32_t freq_hz)
{
    if (freq_hz == 0) return 1;
    uint32_t p = LINK6_SYS_HZ / freq_hz;
    if (p == 0) p = 1;
    if (p > 0xFFFFu) p = 0xFFFFu;
    return p;
}

#endif
