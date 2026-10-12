//go:build darwin && cgo

package darwin

/*
#cgo CFLAGS: -I${SRCDIR}/../../../native/include
#cgo LDFLAGS: -L${SRCDIR}/../../../build/native/darwin/universal -ldaygo_capture -framework Foundation -framework WidgetKit
#include "daygo_widget.h"
*/
import "C"

import (
	"context"
	"fmt"
	"unsafe"
)

func (*System) WidgetAvailable() bool { return C.dg_widget_available() == 1 }
func (*System) PublishWidgetSnapshot(ctx context.Context, payload []byte) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	if len(payload) == 0 || len(payload) > 32*1024 {
		return fmt.Errorf("invalid widget payload size")
	}
	code := C.dg_widget_publish((*C.uint8_t)(unsafe.Pointer(&payload[0])), C.int32_t(len(payload)))
	if code != 0 {
		return fmt.Errorf("publish widget snapshot: native code %d", int32(code))
	}
	return nil
}
