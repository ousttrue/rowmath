pub fn MakeType(comptime _value: anytype) type {
    return struct {
        pub const lines = _value;
    };
}
