module microstructure_engine
  implicit none
contains
  real(8) function slippage_buy(ask_prices, ask_qty, order_qty) result(slip)
    real(8), intent(in) :: ask_prices(:), ask_qty(:), order_qty
    real(8) :: remain, take, cost, filled, best, vwap
    integer :: i
    if (order_qty<=0d0) then; slip=0d0; return; end if
    remain=order_qty; cost=0d0; filled=0d0; best=ask_prices(1)
    do i=1,size(ask_prices)
      if (remain<=0d0) exit
      take=min(remain,ask_qty(i)); cost=cost+take*ask_prices(i); filled=filled+take; remain=remain-take
    end do
    if (filled<=0d0 .or. remain>1d-12) then
      slip=huge(1d0)
    else
      vwap=cost/filled; slip=(vwap-best)/best
    end if
  end function

  pure real(8) function bid_ask_spread(best_bid,best_ask) result(s)
    real(8), intent(in) :: best_bid,best_ask
    s=max(0d0,best_ask-best_bid)
  end function

  subroutine almgren_chriss_schedule(total_qty,n_buckets,lambda,eta,sigma,risk_aversion,schedule)
    real(8), intent(in) :: total_qty,lambda,eta,sigma,risk_aversion
    integer, intent(in) :: n_buckets
    real(8), intent(out) :: schedule(n_buckets)
    real(8) :: kappa, denom, x_prev, x_next, t_next
    integer :: i
    if (n_buckets<=0) return
    if (total_qty<=0d0) then; schedule=0d0; return; end if
    if (eta<=0d0 .or. risk_aversion<=0d0 .or. sigma<=0d0) then
      schedule=1d0/real(n_buckets,8); return
    end if
    kappa=sqrt(max(1d-15,(risk_aversion*sigma*sigma+max(lambda,0d0))/eta))
    denom=sinh(kappa)
    if (abs(denom)<1d-12) then
      schedule=1d0/real(n_buckets,8); return
    end if
    x_prev=1d0
    do i=1,n_buckets
      t_next=real(i,8)/real(n_buckets,8)
      x_next=sinh(kappa*(1d0-t_next))/denom
      schedule(i)=max(0d0,x_prev-x_next)
      x_prev=x_next
    end do
    if (sum(schedule)>0d0) schedule=schedule/sum(schedule)
  end subroutine

  pure real(8) function arb_gap_decay(initial_gap, elapsed, tau) result(gap)
    real(8), intent(in) :: initial_gap,elapsed,tau
    if (tau<=0d0) then
      gap=0d0
    else
      gap=initial_gap*exp(-max(0d0,elapsed)/tau)
    end if
  end function

  subroutine fit_linear_impact(order_flow,price_change,lambda)
    real(8), intent(in) :: order_flow(:),price_change(:)
    real(8), intent(out) :: lambda
    real(8) :: mx,my,varx,cov
    mx=sum(order_flow)/size(order_flow); my=sum(price_change)/size(price_change)
    varx=sum((order_flow-mx)**2); cov=sum((order_flow-mx)*(price_change-my))
    if (varx<=1d-15) then; lambda=0d0; else; lambda=cov/varx; end if
  end subroutine
end module
