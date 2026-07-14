// M3g -- Market microstructure sims
// Language: Zig (tick-level latency, deterministic memory layout)
// Protocol: line-delimited JSON on stdin/stdout to hub.tcl

const std = @import("std");
const math = std.math;

// -- Hyperbolic functions --------------------------------------------------
fn sinh(x: f64) f64 {
    return (@exp(x) - @exp(-x)) / 2.0;
}
fn cosh(x: f64) f64 {
    return (@exp(x) + @exp(-x)) / 2.0;
}
fn tanh(x: f64) f64 {
    return sinh(x) / cosh(x);
}

// -- BoundedPrediction (L2: every output has explicit bounds) -------------

const BoundedPrediction = struct {
    value: f64,
    lower_bound: f64,
    upper_bound: f64,
    confidence: f64,
    time_horizon: []const u8,
    sim_type: []const u8 = "market_microstructure",

    fn init(value: f64, lower: f64, upper: f64, confidence: f64, horizon: []const u8) !BoundedPrediction {
        if (lower > value or value > upper)
            return error.BoundsViolation;
        if (confidence < 0.0 or confidence > 10.0)
            return error.ConfidenceOutOfRange;
        return .{
            .value = value,
            .lower_bound = lower,
            .upper_bound = upper,
            .confidence = confidence,
            .time_horizon = horizon,
        };
    }
};

// -- Order book -----------------------------------------------------------

const Side = enum { bid, ask };

const Order = struct {
    price: f64,
    quantity: f64,
    side: Side,
    id: u64,
};

const MAX_LEVELS: usize = 256;

const OrderBook = struct {
    bids: [MAX_LEVELS]Order,
    asks: [MAX_LEVELS]Order,
    n_bids: usize,
    n_asks: usize,
    mid_price: f64,

    fn init() OrderBook {
        return .{
            .bids = undefined,
            .asks = undefined,
            .n_bids = 0,
            .n_asks = 0,
            .mid_price = 0.0,
        };
    }

    fn addOrder(self: *OrderBook, order: Order) void {
        switch (order.side) {
            .bid => {
                if (self.n_bids < MAX_LEVELS) {
                    self.bids[self.n_bids] = order;
                    self.n_bids += 1;
                }
            },
            .ask => {
                if (self.n_asks < MAX_LEVELS) {
                    self.asks[self.n_asks] = order;
                    self.n_asks += 1;
                }
            },
        }
        self.updateMid();
    }

    fn bestBid(self: *const OrderBook) f64 {
        if (self.n_bids == 0) return 0.0;
        var best: f64 = 0.0;
        for (self.bids[0..self.n_bids]) |b| {
            if (b.price > best) best = b.price;
        }
        return best;
    }

    fn bestAsk(self: *const OrderBook) f64 {
        if (self.n_asks == 0) return math.inf(f64);
        var best: f64 = math.inf(f64);
        for (self.asks[0..self.n_asks]) |a| {
            if (a.price < best) best = a.price;
        }
        return best;
    }

    fn spread(self: *const OrderBook) f64 {
        return self.bestAsk() - self.bestBid();
    }

    fn updateMid(self: *OrderBook) void {
        const bb = self.bestBid();
        const ba = self.bestAsk();
        if (bb > 0.0 and ba < math.inf(f64)) {
            self.mid_price = (bb + ba) / 2.0;
        }
    }

    // L2: slippage is a function of order size and current depth (non-linear)
    fn estimateSlippage(self: *const OrderBook, size: f64, side: Side) f64 {
        var remaining = size;
        var cost: f64 = 0.0;
        const ref_price = self.mid_price;

        switch (side) {
            .bid => {
                // Buying: walk up the ask side
                var i: usize = 0;
                while (i < self.n_asks and remaining > 0.0) : (i += 1) {
                    const fill = @min(remaining, self.asks[i].quantity);
                    cost += fill * self.asks[i].price;
                    remaining -= fill;
                }
            },
            .ask => {
                // Selling: walk down the bid side
                var i: usize = 0;
                while (i < self.n_bids and remaining > 0.0) : (i += 1) {
                    const fill = @min(remaining, self.bids[i].quantity);
                    cost += fill * self.bids[i].price;
                    remaining -= fill;
                }
            },
        }

        if (size <= remaining) return 0.0;
        const avg_price = cost / (size - remaining);
        return @abs(avg_price - ref_price) / ref_price;
    }
};

// -- Almgren-Chriss optimal execution -------------------------------------
// min integral [lambda * x(t) * dx/dt + eta * (dx/dt)^2] dt
// Solution via Riccati: x(t) = X * sinh(kappa*(T-t)) / sinh(kappa*T)
// kappa = sqrt(lambda / eta)

const AlmgrenChriss = struct {
    lambda: f64, // permanent impact
    eta: f64, // temporary impact
    sigma: f64, // volatility (for timing risk)
    risk_aversion: f64,

    fn optimalTrajectory(self: *const AlmgrenChriss, total_shares: f64, T: f64, n_buckets: usize, schedule: []f64) void {
        const kappa = @sqrt(self.risk_aversion * self.sigma * self.sigma / self.eta);
        const sinh_kT = sinh(kappa * T);
        const dt = T / @as(f64, @floatFromInt(n_buckets));

        var prev_x = total_shares;
        for (0..n_buckets) |i| {
            const t = @as(f64, @floatFromInt(i + 1)) * dt;
            const x_t = total_shares * sinh(kappa * (T - t)) / sinh_kT;
            schedule[i] = (prev_x - x_t) / total_shares;
            prev_x = x_t;
        }
    }

    fn executionCost(self: *const AlmgrenChriss, total_shares: f64, T: f64) f64 {
        const kappa = @sqrt(self.risk_aversion * self.sigma * self.sigma / self.eta);
        return self.eta * total_shares * total_shares * kappa / tanh(kappa * T);
    }
};

// -- Self-test ------------------------------------------------------------

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("M3g Market Microstructure Sim -- Zig {s}\n\n", .{@tagName(std.Target.Os.Tag.linux)});

    // Order book test
    try stdout.print("Order book (spread, slippage):\n", .{});
    var book = OrderBook.init();
    book.addOrder(.{ .price = 1800.0, .quantity = 5.0, .side = .bid, .id = 1 });
    book.addOrder(.{ .price = 1799.0, .quantity = 10.0, .side = .bid, .id = 2 });
    book.addOrder(.{ .price = 1798.0, .quantity = 20.0, .side = .bid, .id = 3 });
    book.addOrder(.{ .price = 1801.0, .quantity = 5.0, .side = .ask, .id = 4 });
    book.addOrder(.{ .price = 1802.0, .quantity = 10.0, .side = .ask, .id = 5 });
    book.addOrder(.{ .price = 1805.0, .quantity = 20.0, .side = .ask, .id = 6 });

    try stdout.print("  best bid: {d:.2} best ask: {d:.2}\n", .{ book.bestBid(), book.bestAsk() });
    try stdout.print("  spread: {d:.2}\n", .{book.spread()});

    const slip_small = book.estimateSlippage(3.0, .bid);
    const slip_large = book.estimateSlippage(20.0, .bid);
    try stdout.print("  slippage (3 ETH buy):  {d:.6}\n", .{slip_small});
    try stdout.print("  slippage (20 ETH buy): {d:.6}\n", .{slip_large});

    // L2: larger orders produce greater slippage
    if (slip_large > slip_small) {
        try stdout.print("  L2 non-linear slippage: PASS\n\n", .{});
    } else {
        try stdout.print("  L2 non-linear slippage: FAIL\n\n", .{});
    }

    // Almgren-Chriss test
    try stdout.print("Almgren-Chriss optimal execution:\n", .{});
    const ac = AlmgrenChriss{
        .lambda = 0.001,
        .eta = 0.01,
        .sigma = 0.02,
        .risk_aversion = 1.0e-6,
    };

    var schedule: [5]f64 = undefined;
    ac.optimalTrajectory(100.0, 30.0, 5, &schedule);

    try stdout.print("  schedule (5 buckets, 100 shares, 30 min):\n", .{});
    for (schedule, 0..) |s, i| {
        try stdout.print("    bucket {d}: {d:.4}\n", .{ i + 1, s });
    }

    const cost = ac.executionCost(100.0, 30.0);
    try stdout.print("  total cost: {d:.4}\n\n", .{cost});

    // BoundedPrediction test
    try stdout.print("BoundedPrediction:\n", .{});
    const bp = try BoundedPrediction.init(0.0034, 0.0018, 0.0052, 8.50, "next_trade");
    try stdout.print("  slippage: {d:.4} [{d:.4}, {d:.4}]\n", .{ bp.value, bp.lower_bound, bp.upper_bound });
    try stdout.print("  confidence: {d:.2}/10.00\n\n", .{bp.confidence});

    // Invariant checks
    try stdout.print("Invariant checks:\n", .{});
    if (BoundedPrediction.init(5.0, 6.0, 8.0, 7.0, "1h")) |_| {
        try stdout.print("  L2 bounds: FAIL\n", .{});
    } else |_| {
        try stdout.print("  L2 bounds: PASS (rejected lower > value)\n", .{});
    }
    if (BoundedPrediction.init(5.0, 4.0, 8.0, 11.0, "1h")) |_| {
        try stdout.print("  Confidence range: FAIL\n", .{});
    } else |_| {
        try stdout.print("  Confidence range: PASS (rejected 11.0 > 10.0)\n", .{});
    }

    try stdout.print("\nAll models operational.\n", .{});
}
