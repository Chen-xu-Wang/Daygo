#ifndef DAYGO_WIDGET_H
#define DAYGO_WIDGET_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
int32_t dg_widget_available(void);
// Synchronous; does not retain payload. 32 KiB maximum. 0 means success.
int32_t dg_widget_publish(const uint8_t *payload, int32_t length);
#ifdef __cplusplus
}
#endif
#endif
