package tests

import "core:testing"

@(test)
my_test :: proc(t: ^testing.T) {
    n := 2 + 2

    // Check if `n` is the expected value of `4`.
    // If not, fail the test with the provided message.
    testing.expect(t, n == 4, "2 + 2 failed to equal 4.")
}
