program tokenomics_query
  use tokenomics_engine
  implicit none

  integer :: n, i, ios, innovation_count
  character(len=64) :: kind, horizon_arg
  real(8) :: horizon_years
  real(8) :: timestamp, total_minted, circulating, staked, locked, burned
  real(8) :: supplied, borrowed, collateral, ltv, treasury, treasury_burn_rate
  real(8) :: velocity, base_emission_rate, halving_interval, policy_time, exposure_factor
  real(8) :: apy(3), vol(3), confidence
  real(8) :: m_total, v_total, m_circ, v_circ, m_staked, v_staked
  real(8) :: m_locked, v_locked, m_burned, v_burned
  real(8) :: m_supplied, v_supplied, m_borrowed, v_borrowed
  real(8) :: m_collateral, v_collateral, m_treasury, v_treasury
  real(8) :: m_velocity, v_velocity
  real(8) :: obs_var, process_var, scale, confidence_sum
  real(8) :: innovation_sum, innovation, uncertainty, correctness, certainty
  real(8) :: value, lower, upper, detail(3), recent_shift, first_circulating
  real(8) :: last_ltv, last_treasury_burn_rate, last_base_emission
  real(8) :: last_halving_interval, last_policy_time, last_exposure_factor
  real(8) :: last_apy(3), last_vol(3), relative_variance

  call get_command_argument(1,kind)
  call get_command_argument(2,horizon_arg)
  if (len_trim(kind) == 0 .or. len_trim(horizon_arg) == 0) error stop 'query args'
  read(horizon_arg,*,iostat=ios) horizon_years
  if (ios /= 0 .or. horizon_years < 0d0) error stop 'invalid horizon'

  read(*,*,iostat=ios) n
  if (ios /= 0 .or. n < 2) error stop 'insufficient history'

  confidence_sum = 0d0
  innovation_sum = 0d0
  innovation_count = 0
  first_circulating = 0d0

  do i=1,n
    read(*,*,iostat=ios) timestamp, total_minted, circulating, staked, locked, burned, &
         supplied, borrowed, collateral, ltv, treasury, treasury_burn_rate, velocity, &
         base_emission_rate, halving_interval, policy_time, exposure_factor, &
         apy(1), vol(1), apy(2), vol(2), apy(3), vol(3), confidence
    if (ios /= 0) error stop 'invalid observation row'

    if (timestamp < 0d0 .or. total_minted < 0d0 .or. circulating < 0d0 .or. &
        staked < 0d0 .or. locked < 0d0 .or. burned < 0d0 .or. supplied < 0d0 .or. &
        borrowed < 0d0 .or. collateral < 0d0 .or. treasury < 0d0 .or. &
        treasury_burn_rate < 0d0 .or. velocity < 0d0 .or. base_emission_rate < 0d0 .or. &
        halving_interval < 0d0 .or. policy_time < 0d0 .or. exposure_factor < 0d0 .or. &
        any(apy < 0d0) .or. any(vol < 0d0) .or. confidence < 0d0 .or. confidence > 10d0) &
         error stop 'invalid observation values'

    if (.not. stock_flow_conserved(circulating,staked,locked,burned,total_minted, &
         max(1d-6,1d-8*max(total_minted,1d0)))) error stop 'stock flow violation'

    confidence_sum = confidence_sum + confidence

    if (i == 1) then
      first_circulating = circulating
      call init_estimate(total_minted,m_total,v_total)
      call init_estimate(circulating,m_circ,v_circ)
      call init_estimate(staked,m_staked,v_staked)
      call init_estimate(locked,m_locked,v_locked)
      call init_estimate(burned,m_burned,v_burned)
      call init_estimate(supplied,m_supplied,v_supplied)
      call init_estimate(borrowed,m_borrowed,v_borrowed)
      call init_estimate(collateral,m_collateral,v_collateral)
      call init_estimate(treasury,m_treasury,v_treasury)
      call init_estimate(velocity,m_velocity,v_velocity)
    else
      innovation = 0d0
      innovation = innovation + relative_error(total_minted,m_total)
      innovation = innovation + relative_error(circulating,m_circ)
      innovation = innovation + relative_error(staked,m_staked)
      innovation = innovation + relative_error(locked,m_locked)
      innovation = innovation + relative_error(burned,m_burned)
      innovation = innovation + relative_error(supplied,m_supplied)
      innovation = innovation + relative_error(borrowed,m_borrowed)
      innovation = innovation + relative_error(collateral,m_collateral)
      innovation = innovation + relative_error(treasury,m_treasury)
      innovation = innovation + relative_error(velocity,m_velocity)
      innovation_sum = innovation_sum + innovation/10d0
      innovation_count = innovation_count + 1

      scale = max(0.01d0,(10d0-confidence)/10d0)
      call update_estimate(total_minted,scale,m_total,v_total)
      call update_estimate(circulating,scale,m_circ,v_circ)
      call update_estimate(staked,scale,m_staked,v_staked)
      call update_estimate(locked,scale,m_locked,v_locked)
      call update_estimate(burned,scale,m_burned,v_burned)
      call update_estimate(supplied,scale,m_supplied,v_supplied)
      call update_estimate(borrowed,scale,m_borrowed,v_borrowed)
      call update_estimate(collateral,scale,m_collateral,v_collateral)
      call update_estimate(treasury,scale,m_treasury,v_treasury)
      call update_estimate(velocity,scale,m_velocity,v_velocity)
    end if

    last_ltv = ltv
    last_treasury_burn_rate = treasury_burn_rate
    last_base_emission = base_emission_rate
    last_halving_interval = halving_interval
    last_policy_time = policy_time
    last_exposure_factor = exposure_factor
    last_apy = apy
    last_vol = vol
  end do

  relative_variance = 0d0
  relative_variance = relative_variance + v_total/max(m_total*m_total,1d0)
  relative_variance = relative_variance + v_circ/max(m_circ*m_circ,1d0)
  relative_variance = relative_variance + v_staked/max(m_staked*m_staked,1d0)
  relative_variance = relative_variance + v_locked/max(m_locked*m_locked,1d0)
  relative_variance = relative_variance + v_burned/max(m_burned*m_burned,1d0)
  relative_variance = relative_variance + v_supplied/max(m_supplied*m_supplied,1d0)
  relative_variance = relative_variance + v_borrowed/max(m_borrowed*m_borrowed,1d0)
  relative_variance = relative_variance + v_collateral/max(m_collateral*m_collateral,1d0)
  relative_variance = relative_variance + v_treasury/max(m_treasury*m_treasury,1d0)
  relative_variance = relative_variance + v_velocity/max(m_velocity*m_velocity,1d0)
  uncertainty = min(0.5d0,sqrt(max(0d0,relative_variance/10d0)))

  confidence = min(10d0,max(0d0,confidence_sum/real(n,8)))
  if (innovation_count > 0) then
    correctness = 10d0*exp(-20d0*innovation_sum/real(innovation_count,8))
  else
    correctness = 5d0
  end if
  correctness = min(10d0,max(0d0,correctness))
  certainty = 10d0/(1d0+20d0*uncertainty)
  certainty = min(10d0,max(0d0,certainty))

  call tokenomics_prediction(trim(kind),horizon_years,m_total,m_circ,m_staked,m_locked,m_burned, &
       m_supplied,m_borrowed,m_collateral,last_ltv,m_treasury,last_treasury_burn_rate,m_velocity, &
       last_base_emission,last_halving_interval,last_policy_time,last_exposure_factor,last_apy,last_vol, &
       uncertainty,value,lower,upper,detail)

  if (first_circulating > 1d-15) then
    recent_shift = m_circ/first_circulating-1d0
  else
    recent_shift = 0d0
  end if

  write(*,'(A,1X,10(ES24.16E3,1X))') 'RESULT', value, lower, upper, confidence, correctness, certainty, &
       recent_shift, detail(1), detail(2), detail(3)

contains

  subroutine init_estimate(observation,mean,var)
    real(8), intent(in) :: observation
    real(8), intent(out) :: mean,var
    mean = observation
    var = max(1d-12,(0.05d0*max(abs(observation),1d0))**2)
  end subroutine init_estimate

  subroutine update_estimate(observation,noise_scale,mean,var)
    real(8), intent(in) :: observation,noise_scale
    real(8), intent(inout) :: mean,var
    real(8) :: posterior_mean,posterior_var
    process_var = (0.002d0*max(abs(mean),1d0))**2
    obs_var = (noise_scale*max(abs(observation),1d0))**2
    call kalman_scalar_update(mean,var,observation,obs_var,process_var,posterior_mean,posterior_var)
    mean = posterior_mean
    var = posterior_var
  end subroutine update_estimate

  pure real(8) function relative_error(observation,estimate) result(err)
    real(8), intent(in) :: observation,estimate
    err = abs(observation-estimate)/max(abs(observation),1d0)
  end function relative_error

end program tokenomics_query
