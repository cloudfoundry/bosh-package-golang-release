package main

import (
	"crypto/fips140"
	"fmt"
	"os"
)

func main() {
	if !fips140.Enabled() {
		fmt.Fprintln(os.Stderr, "FAIL: FIPS 140-3 mode is not enabled")
		os.Exit(1)
	}
	fmt.Println("PASS: FIPS 140-3 mode is enabled")
}
