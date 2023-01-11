module integer_mate::math_u128 {
    use integer_mate::math_u64;

    const MAX_U128: u128 = 0xffffffffffffffffffffffffffffffff;

    const HI_64_MASK: u128 = 0xffffffffffffffff0000000000000000;
    const LO_64_MASK: u128 = 0x0000000000000000ffffffffffffffff;

    const DIV_BY_ZERO: u64 = 1;

    public fun wrapping_add(n1: u128, n2: u128): u128 {
        let (sum, _) = overflowing_add(n1, n2);
        sum
    }

    public fun overflowing_add(n1: u128, n2: u128): (u128, bool) {
        let (sum0, carry0) = math_u64::carry_add(lo(n1), lo(n2), 0);
        let (sum1, carry1) = math_u64::carry_add(hi(n1), hi(n2), carry0);
        ((((sum1 as u128) << 64) + (sum0 as u128)), carry1 == 1)
    }
    
    public fun wrapping_sub(n1: u128, n2: u128): u128 {
        let (result, _) = overflowing_sub(n1, n2);
        result
    }
    
    public fun overflowing_sub(n1: u128, n2: u128): (u128, bool) {
        if (n1 >= n2) {
            ((n1 - n2), false)
        } else {
            ((MAX_U128 - n2 + n1 + 1), true)
        }
    }
    
    public fun wrapping_mul(n1: u128, n2: u128): u128 {
        let (m, _) = overflowing_mul(n1, n2);
        m
    }
    
    public fun overflowing_mul(n1: u128, n2: u128): (u128, bool) {
        let (c0, c1) = full_mul(n1, n2);
        if (c1 > 0) {
            (c0, true)
        } else {
            (c0, false)
        }
    }

    public fun full_mul(n1: u128, n2: u128): (u128, u128) {
        let c0 = lo_u128(n1) * lo_u128(n2);
        let a1 = lo_u128(n1) * hi_u128(n2);
        let b0 = hi_u128(n1) * lo_u128(n2);
        let c1 = hi_u128(c0) + lo_u128(a1) + lo_u128(b0);
        c0 = ((lo(c1) as u128) << 64) + (lo(c0) as u128);
        c1 = hi_u128(n1) *  hi_u128(n2) + hi_u128(c1) + hi_u128(a1) + hi_u128(b0);
        (c0, c1)
    }

    public fun hi(n: u128): u64 {
        (((n & HI_64_MASK) >> 64) as u64)
    }

    public fun lo(n: u128): u64 {
        ((n & LO_64_MASK) as u64)
    }

    public fun hi_u128(n: u128): u128 {
        (n & HI_64_MASK) >> 64
    }

    public fun lo_u128(n: u128): u128 {
        (n & LO_64_MASK)
    }

    public fun from_lo_hi(lo: u64, hi: u64): u128 {
        ((hi as u128) << 64) + (lo as u128)
    }

    public fun checked_div_round(num: u128, denom: u128, round_up: bool): u128 {
        if (denom == 0) {
            abort DIV_BY_ZERO
        };
        let quotient = num / denom;
        let remainer = num % denom;
        if (round_up && (remainer > 0)) {
            return (quotient + 1)
        };
        quotient
    }

    public fun max(num1: u128, num2: u128): u128 {
        if (num1 > num2) {
            num1
        } else {
            num2
        }
    }

    public fun min(num1: u128, num2: u128): u128 {
        if (num1 < num2) {
            num1
        } else {
            num2
        }
    }

    #[test]
    fun test_overflowing_add() {
        let (m, o) = overflowing_add(10, 10);
        assert!(m == 20u128 && o == false, 0);

        let (m, o) = overflowing_add(MAX_U128, 10);
        assert!(m == 9u128 && o == true, 0);
    }

    #[test]
    fun test_full_mul() {
        let (lo, hi) = full_mul(0, 10);
        assert!(hi == 0 && lo == 0, 0);

        let (lo, hi) = full_mul(10, 10);
        assert!(hi == 0 && lo == 100, 0);

        let (lo, hi) = full_mul(9999, 10);
        assert!(hi == 0 && lo == 99990, 0);

        let (lo, hi) = full_mul(MAX_U128, 0);
        assert!(hi == 0 && lo == 0, 0);

        let (lo, hi) = full_mul(MAX_U128, 1);
        assert!(hi == 0 && lo == MAX_U128, 0);

        let (lo, hi) = full_mul(MAX_U128, 10);
        assert!(hi == 9 && lo == 0xfffffffffffffffffffffffffffffff6, 0);

        let (lo, hi) = full_mul(10, MAX_U128);
        assert!(hi == 9 && lo == 0xfffffffffffffffffffffffffffffff6, 0);

        let (lo, hi) = full_mul(MAX_U128, MAX_U128);
        assert!(hi == 0xfffffffffffffffffffffffffffffffe && lo == 1, 0);
    }

    #[test]
    fun test_wrapping_mul() {
        assert!(wrapping_mul(0, 10) == 0, 0);
        assert!(wrapping_mul(10, 0) == 0, 0);
        assert!(wrapping_mul(10, 10) == 100, 0);
        assert!(wrapping_mul(99999, 10) == 10 * 99999, 0);
        assert!(wrapping_mul(MAX_U128, 0) == 0, 0);
        assert!(wrapping_mul(MAX_U128, 1) == MAX_U128, 0);
        assert!(wrapping_mul(MAX_U128, 10) == 0xfffffffffffffffffffffffffffffff6, 0);
        assert!(wrapping_mul(10, MAX_U128) == 0xfffffffffffffffffffffffffffffff6, 0);
        assert!(wrapping_mul(MAX_U128, MAX_U128) == 1, 0);
    }

    #[test]
    fun test_overflowing_mul() {
        let (r, o) = overflowing_mul(0, 10);
        assert!(r == 0 && o == false, 0);

        let (r, o) = overflowing_mul(10, 10);
        assert!(r == 100 && o == false, 0);

        let (r, o) = overflowing_mul(MAX_U128, 10);
        assert!(r == 0xfffffffffffffffffffffffffffffff6 && o == true, 0);
    }
}
