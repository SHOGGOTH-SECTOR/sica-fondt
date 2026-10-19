module mev_engine
  implicit none
contains
  subroutine pga_all_pay(bids, opportunity_value, profits, winner)
    real(8), intent(in) :: bids(:), opportunity_value
    real(8), intent(out) :: profits(size(bids))
    integer, intent(out) :: winner
    integer :: i
    winner = maxloc(bids, dim=1)
    do i=1,size(bids)
      profits(i) = -bids(i)
    end do
    profits(winner) = opportunity_value - bids(winner)
  end subroutine

  subroutine knapsack_select(values, gas, gas_limit, selected, best_value)
    real(8), intent(in) :: values(:)
    integer, intent(in) :: gas(:), gas_limit
    integer, intent(out) :: selected(size(values))
    real(8), intent(out) :: best_value
    real(8), allocatable :: dp(:,:)
    integer :: n, i, w
    n = size(values)
    allocate(dp(0:n,0:gas_limit)); dp = 0d0
    do i=1,n
      do w=0,gas_limit
        dp(i,w)=dp(i-1,w)
        if (gas(i)<=w) dp(i,w)=max(dp(i,w), dp(i-1,w-gas(i))+values(i))
      end do
    end do
    best_value=dp(n,gas_limit); selected=0; w=gas_limit
    do i=n,1,-1
      if (abs(dp(i,w)-dp(i-1,w))>1d-12) then
        selected(i)=1; w=w-gas(i)
      end if
    end do
    deallocate(dp)
  end subroutine

  subroutine cross_chain_profit(p_src,p_dst,slippage,gas_cost,bridge_fee,depreciation,q,inventory_profit,bridge_profit)
    real(8), intent(in) :: p_src,p_dst,slippage,gas_cost,bridge_fee,depreciation,q
    real(8), intent(out) :: inventory_profit,bridge_profit
    real(8) :: spread
    spread = p_src-p_dst
    inventory_profit = (spread-slippage-gas_cost)*q
    bridge_profit = (spread-bridge_fee-depreciation)*q
  end subroutine

  pure real(8) function sandwich_probability(trade_fraction, slippage_tolerance, liquidity_score) result(p)
    real(8), intent(in) :: trade_fraction, slippage_tolerance, liquidity_score
    real(8) :: z
    z = 5d0*max(0d0,trade_fraction) + 3d0*max(0d0,slippage_tolerance) - 2d0*max(0d0,liquidity_score)
    p = 1d0/(1d0+exp(-z))
  end function

  pure real(8) function all_pay_social_cost(bids) result(cost)
    real(8), intent(in) :: bids(:)
    cost = sum(max(bids,0d0))
  end function
end module
