//go:build windows

package main

import (
	"errors"
	"runtime"
	"syscall"
	"unsafe"
)

type mcfBlob struct {
	Size uint32
	Data *byte
}

var (
	mcfCrypt32   = syscall.NewLazyDLL("crypt32.dll")
	mcfProtect   = mcfCrypt32.NewProc("CryptProtectData")
	mcfUnprotect = mcfCrypt32.NewProc("CryptUnprotectData")
	mcfFree      = syscall.NewLazyDLL("kernel32.dll").NewProc("LocalFree")
)

func dpapiTransform(input []byte, decrypt bool) ([]byte, error) {
	if len(input) == 0 || uint64(len(input)) > uint64(^uint32(0)) {
		return nil, errors.New("invalid DPAPI input")
	}
	in := mcfBlob{uint32(len(input)), &input[0]}
	var out mcfBlob
	proc := mcfProtect
	if decrypt {
		proc = mcfUnprotect
	}
	// CRYPTPROTECT_UI_FORBIDDEN; no machine scope or optional entropy.
	ok, _, _ := proc.Call(uintptr(unsafe.Pointer(&in)), 0, 0, 0, 0, 1, uintptr(unsafe.Pointer(&out)))
	runtime.KeepAlive(input)
	if ok == 0 {
		return nil, errors.New("Windows DPAPI operation failed")
	}
	if out.Data != nil {
		defer mcfFree.Call(uintptr(unsafe.Pointer(out.Data)))
	}
	if out.Data == nil || out.Size == 0 || uint64(out.Size) > uint64(^uint(0)>>1) {
		return nil, errors.New("empty or oversized DPAPI output")
	}
	buf := unsafe.Slice(out.Data, int(out.Size))
	result := append([]byte(nil), buf...)
	if decrypt {
		clear(buf)
	}
	return result, nil
}

func protectConfig(b []byte) ([]byte, error)   { return dpapiTransform(b, false) }
func unprotectConfig(b []byte) ([]byte, error) { return dpapiTransform(b, true) }
