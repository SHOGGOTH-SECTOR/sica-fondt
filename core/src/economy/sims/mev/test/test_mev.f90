program test_mev
  use mev_engine
  implicit none
  real(8) :: bids(3), profits(3), invp, bridgep
  integer :: winner
  integer :: gas(3), selected(3)
  real(8) :: vals(3), best
  bids = [1d0, 2d0, 3d0]
  call pga_all_pay(bids, 10d0, profits, winner)
  if (winner /= 3) error stop 'winner'
  if (abs(profits(1) + 1d0) > 1d-9) error stop 'loser pays'
  if (abs(profits(3) - 7d0) > 1d-9) error stop 'winner profit'
  gas = [4, 5, 9]; vals = [6d0, 7d0, 12d0]
  call knapsack_select(vals, gas, 9, selected, best)
  if (abs(best - 13d0) > 1d-9) error stop 'knapsack optimum'
  call cross_chain_profit(105d0, 100d0, 0.5d0, 0.2d0, 0.1d0, 0.8d0, 2d0, invp, bridgep)
  if (invp <= bridgep) error stop 'inventory latency advantage'
  print *, 'MEV TESTS PASSED'
end program
