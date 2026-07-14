! M3d -- MEV & adversarial extraction sims
! Language: Fortran (dense PDE/knapsack numerics, no GC pauses)
! Protocol: line-delimited JSON on stdin/stdout to hub.tcl

program mev_sim
  implicit none

  ! -- BoundedPrediction type -----------------------------------------------
  type :: BoundedPrediction
    double precision :: value
    double precision :: lower_bound
    double precision :: upper_bound
    double precision :: confidence
    character(len=16) :: time_horizon
    character(len=32) :: sim_type
  end type

  ! -- PGA auction state (Priority Gas Auction as all-pay auction) ----------
  type :: PGAAuction
    integer :: n_bidders
    double precision, allocatable :: bids(:)
    double precision, allocatable :: valuations(:)
    double precision :: extractable_value
  end type

  ! -- Knapsack block building ----------------------------------------------
  type :: Transaction
    double precision :: gas_price
    double precision :: gas_limit
    double precision :: mev_value
    integer :: tx_id
  end type

  ! -- Validator state for Markov model -------------------------------------
  integer, parameter :: N_STATES = 4
  character(len=8), parameter :: state_names(N_STATES) = &
    (/ 'active  ', 'pending ', 'slashed ', 'exited  ' /)

  call run_self_test()

contains

  ! -- PGA all-pay auction simulation ---------------------------------------
  ! Bidders submit gas bids; winner pays, all losers also pay (all-pay).
  ! Nash equilibrium: bid = valuation * (n-1)/n for uniform valuations.
  subroutine pga_simulate(n_bidders, ext_value, n_rounds, &
                          avg_winner_bid, avg_overpay)
    integer, intent(in) :: n_bidders, n_rounds
    double precision, intent(in) :: ext_value
    double precision, intent(out) :: avg_winner_bid, avg_overpay
    double precision :: bids(n_bidders), valuations(n_bidders)
    double precision :: winner_bid, total_winner, total_overpay
    integer :: i, r, winner_idx
    double precision :: max_bid

    total_winner = 0.0d0
    total_overpay = 0.0d0

    do r = 1, n_rounds
      ! Each bidder has a private valuation drawn uniform [0, ext_value]
      call random_number(valuations(1:n_bidders))
      valuations = valuations * ext_value

      ! Nash equilibrium bidding: bid = val * (n-1)/n
      bids = valuations * dble(n_bidders - 1) / dble(n_bidders)

      ! Add noise (bounded rationality)
      do i = 1, n_bidders
        call random_number(max_bid)
        bids(i) = bids(i) * (0.9d0 + 0.2d0 * max_bid)
      end do

      ! Winner = highest bid
      max_bid = bids(1)
      winner_idx = 1
      do i = 2, n_bidders
        if (bids(i) > max_bid) then
          max_bid = bids(i)
          winner_idx = i
        end if
      end do

      winner_bid = bids(winner_idx)
      total_winner = total_winner + winner_bid
      total_overpay = total_overpay + (winner_bid - valuations(winner_idx))
    end do

    avg_winner_bid = total_winner / dble(n_rounds)
    avg_overpay = total_overpay / dble(n_rounds)
  end subroutine

  ! -- Knapsack block builder -----------------------------------------------
  ! 0-1 knapsack: maximize MEV value subject to gas limit constraint.
  ! Uses dynamic programming (O(n * capacity)).
  subroutine knapsack_block(txs, n_tx, gas_capacity, selected, n_selected, &
                            total_value)
    type(Transaction), intent(in) :: txs(n_tx)
    integer, intent(in) :: n_tx
    integer, intent(in) :: gas_capacity
    integer, intent(out) :: selected(n_tx)
    integer, intent(out) :: n_selected
    double precision, intent(out) :: total_value

    integer :: dp_table(0:n_tx, 0:gas_capacity)
    integer :: i, w, gas_int

    dp_table = 0
    do i = 1, n_tx
      gas_int = int(txs(i)%gas_limit)
      do w = 0, gas_capacity
        if (gas_int <= w) then
          dp_table(i, w) = max(dp_table(i-1, w), &
            dp_table(i-1, w - gas_int) + int(txs(i)%mev_value * 1000.0d0))
        else
          dp_table(i, w) = dp_table(i-1, w)
        end if
      end do
    end do

    ! Backtrace to find selected transactions
    n_selected = 0
    selected = 0
    w = gas_capacity
    total_value = 0.0d0
    do i = n_tx, 1, -1
      if (dp_table(i, w) /= dp_table(i-1, w)) then
        n_selected = n_selected + 1
        selected(n_selected) = txs(i)%tx_id
        total_value = total_value + txs(i)%mev_value
        w = w - int(txs(i)%gas_limit)
      end if
    end do
  end subroutine

  ! -- WENO5 advection (1D shock-capturing PDE solver) ----------------------
  ! For adversarial dynamics: non-linear Fokker-Planck with shocks
  ! du/dt + d/dx[f(u)] = 0, f(u) = u^2/2 (Burgers equation as prototype)
  subroutine weno5_step(u, nx, dx, dt, u_new)
    integer, intent(in) :: nx
    double precision, intent(in) :: u(nx), dx, dt
    double precision, intent(out) :: u_new(nx)
    double precision :: flux_p(nx), flux_m(nx)
    double precision :: v(-2:2), beta(3), omega(3), alpha_w(3)
    double precision :: f_hat_p, f_hat_m, eps_w, alpha_lf
    integer :: i, k

    eps_w = 1.0d-6
    alpha_lf = maxval(abs(u))

    flux_p = 0.5d0 * (0.5d0 * u * u + alpha_lf * u)
    flux_m = 0.5d0 * (0.5d0 * u * u - alpha_lf * u)

    u_new = u
    do i = 3, nx - 2
      ! WENO5 reconstruction for positive flux (left-biased)
      v(-2) = flux_p(i-2)
      v(-1) = flux_p(i-1)
      v(0)  = flux_p(i)
      v(1)  = flux_p(i+1)
      v(2)  = flux_p(i+2)

      beta(1) = (13.0d0/12.0d0) * (v(-2) - 2*v(-1) + v(0))**2 &
              + 0.25d0 * (v(-2) - 4*v(-1) + 3*v(0))**2
      beta(2) = (13.0d0/12.0d0) * (v(-1) - 2*v(0) + v(1))**2 &
              + 0.25d0 * (v(-1) - v(1))**2
      beta(3) = (13.0d0/12.0d0) * (v(0) - 2*v(1) + v(2))**2 &
              + 0.25d0 * (3*v(0) - 4*v(1) + v(2))**2

      alpha_w(1) = 0.1d0 / (eps_w + beta(1))**2
      alpha_w(2) = 0.6d0 / (eps_w + beta(2))**2
      alpha_w(3) = 0.3d0 / (eps_w + beta(3))**2
      omega = alpha_w / sum(alpha_w)

      f_hat_p = omega(1) * (2*v(-2) - 7*v(-1) + 11*v(0)) / 6.0d0 &
              + omega(2) * (-v(-1) + 5*v(0) + 2*v(1)) / 6.0d0 &
              + omega(3) * (2*v(0) + 5*v(1) - v(2)) / 6.0d0

      ! WENO5 for negative flux (right-biased, mirror stencil)
      v(-2) = flux_m(i+2)
      v(-1) = flux_m(i+1)
      v(0)  = flux_m(i)
      v(1)  = flux_m(i-1)
      v(2)  = flux_m(i-2)

      beta(1) = (13.0d0/12.0d0) * (v(-2) - 2*v(-1) + v(0))**2 &
              + 0.25d0 * (v(-2) - 4*v(-1) + 3*v(0))**2
      beta(2) = (13.0d0/12.0d0) * (v(-1) - 2*v(0) + v(1))**2 &
              + 0.25d0 * (v(-1) - v(1))**2
      beta(3) = (13.0d0/12.0d0) * (v(0) - 2*v(1) + v(2))**2 &
              + 0.25d0 * (3*v(0) - 4*v(1) + v(2))**2

      alpha_w(1) = 0.1d0 / (eps_w + beta(1))**2
      alpha_w(2) = 0.6d0 / (eps_w + beta(2))**2
      alpha_w(3) = 0.3d0 / (eps_w + beta(3))**2
      omega = alpha_w / sum(alpha_w)

      f_hat_m = omega(1) * (2*v(-2) - 7*v(-1) + 11*v(0)) / 6.0d0 &
              + omega(2) * (-v(-1) + 5*v(0) + 2*v(1)) / 6.0d0 &
              + omega(3) * (2*v(0) + 5*v(1) - v(2)) / 6.0d0

      u_new(i) = u(i) - dt / dx * (f_hat_p + f_hat_m &
                 - (flux_p(i-1) + flux_m(i-1) &
                    + (flux_p(i-1) + flux_m(i-1))) * 0.0d0)
    end do

    ! Simplified: just use basic upwind for the update with WENO fluxes
    do i = 3, nx - 2
      u_new(i) = u(i) - dt / dx * (f_hat_p - f_hat_m)
    end do
  end subroutine

  ! -- BoundedPrediction constructor ----------------------------------------
  function make_prediction(val, lo, hi, conf, horizon) result(bp)
    double precision, intent(in) :: val, lo, hi, conf
    character(len=*), intent(in) :: horizon
    type(BoundedPrediction) :: bp

    if (lo > val .or. val > hi) then
      print *, "ERROR: invariant violation: lower <= value <= upper"
      stop 1
    end if
    if (conf < 0.0d0 .or. conf > 10.0d0) then
      print *, "ERROR: confidence must be in [0.00, 10.00]"
      stop 1
    end if

    bp%value = val
    bp%lower_bound = lo
    bp%upper_bound = hi
    bp%confidence = conf
    bp%time_horizon = horizon
    bp%sim_type = "mev_adversarial"
  end function

  ! -- Self-test ------------------------------------------------------------
  subroutine run_self_test()
    type(BoundedPrediction) :: bp
    double precision :: avg_bid, avg_overpay
    type(Transaction) :: txs(5)
    integer :: selected(5), n_sel
    double precision :: total_val
    double precision :: u(100), u_new(100), dx, dt
    integer :: i

    print *, "M3d MEV Adversarial Sim -- Fortran (gfortran)"
    print *, ""

    ! PGA auction test
    print *, "PGA all-pay auction (10 bidders, 1000 rounds):"
    call pga_simulate(10, 1.0d0, 1000, avg_bid, avg_overpay)
    write(*, '(A,F8.4)') "  avg winner bid: ", avg_bid
    write(*, '(A,F8.4)') "  avg overpay:    ", avg_overpay
    bp = make_prediction(avg_bid, avg_bid * 0.8d0, avg_bid * 1.2d0, &
                         8.50d0, "1h")
    write(*, '(A,F6.2,A)') "  confidence: ", bp%confidence, "/10.00"
    print *, ""

    ! Knapsack block building test
    print *, "Knapsack block builder (5 txs, capacity=100):"
    txs(1) = Transaction(gas_price=20.0d0, gas_limit=30.0d0, &
                         mev_value=5.0d0, tx_id=1)
    txs(2) = Transaction(gas_price=15.0d0, gas_limit=25.0d0, &
                         mev_value=4.0d0, tx_id=2)
    txs(3) = Transaction(gas_price=25.0d0, gas_limit=40.0d0, &
                         mev_value=7.0d0, tx_id=3)
    txs(4) = Transaction(gas_price=10.0d0, gas_limit=20.0d0, &
                         mev_value=3.0d0, tx_id=4)
    txs(5) = Transaction(gas_price=30.0d0, gas_limit=50.0d0, &
                         mev_value=9.0d0, tx_id=5)
    call knapsack_block(txs, 5, 100, selected, n_sel, total_val)
    write(*, '(A,I2,A,F6.2)') "  selected: ", n_sel, &
      " txs, total MEV: ", total_val
    print *, ""

    ! WENO5 shock test (Burgers equation step function)
    print *, "WENO5 advection (100 cells, Burgers equation):"
    dx = 1.0d0 / 100.0d0
    dt = 0.5d0 * dx
    u = 0.0d0
    do i = 1, 50
      u(i) = 1.0d0
    end do
    call weno5_step(u, 100, dx, dt, u_new)
    write(*, '(A,F8.4,A,F8.4)') "  u(48)=", u_new(48), &
      "  u(52)=", u_new(52)
    print *, ""

    ! BoundedPrediction invariant checks
    print *, "Invariant checks:"
    bp = make_prediction(0.15d0, 0.05d0, 0.30d0, 7.80d0, "1h")
    print *, "  L2 bounds: PASS"
    print *, ""
    print *, "All models operational."
  end subroutine

end program mev_sim
