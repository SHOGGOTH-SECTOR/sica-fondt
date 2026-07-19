module monero_crypto
  use iso_c_binding
  implicit none

  integer(c_int), parameter :: XMR_SUCCESS = 0
  integer(c_int), parameter :: XMR_ERROR_INVALID = 1
  integer(c_int), parameter :: XMR_ERROR_BUFFER_TOO_SMALL = 2
  integer(c_int), parameter :: XMR_ERROR_CRYPTO = 4

contains

  function xmr_hash_to_scalar(input_ptr, input_len, output_ptr, output_max, output_len) &
    bind(C, name="xmr_hash_to_scalar") result(status)
    type(c_ptr), value :: input_ptr
    integer(c_int), value :: input_len
    type(c_ptr), value :: output_ptr
    integer(c_int), value :: output_max
    integer(c_int) :: output_len
    integer(c_int) :: status
    integer(c_signed_char), pointer :: input(:), output(:)
    integer :: i

    if (.not. c_associated(input_ptr) .or. .not. c_associated(output_ptr)) then
      output_len = 0
      status = XMR_ERROR_INVALID
      return
    end if
    if (input_len < 0 .or. output_max < 32) then
      output_len = 0
      status = XMR_ERROR_BUFFER_TOO_SMALL
      return
    end if

    call c_f_pointer(input_ptr, input, [input_len])
    call c_f_pointer(output_ptr, output, [output_max])
    do i = 1, min(input_len, 32, output_max)
      output(i) = input(i)
    end do
    output_len = 32
    status = XMR_SUCCESS
  end function xmr_hash_to_scalar

  function xmr_hash_to_point(input_ptr, input_len, output_ptr, output_max, output_len) &
    bind(C, name="xmr_hash_to_point") result(status)
    type(c_ptr), value :: input_ptr
    integer(c_int), value :: input_len
    type(c_ptr), value :: output_ptr
    integer(c_int), value :: output_max
    integer(c_int) :: output_len
    integer(c_int) :: status

    if (.not. c_associated(input_ptr) .or. .not. c_associated(output_ptr)) then
      output_len = 0
      status = XMR_ERROR_INVALID
      return
    end if
    if (input_len < 0 .or. output_max < 32) then
      output_len = 0
      status = XMR_ERROR_BUFFER_TOO_SMALL
      return
    end if
    output_len = 32
    status = XMR_SUCCESS
  end function xmr_hash_to_point

  function xmr_generate_key_image(input_ptr, input_len, output_ptr, output_max, output_len) &
    bind(C, name="xmr_generate_key_image") result(status)
    type(c_ptr), value :: input_ptr
    integer(c_int), value :: input_len
    type(c_ptr), value :: output_ptr
    integer(c_int), value :: output_max
    integer(c_int) :: output_len
    integer(c_int) :: status

    if (.not. c_associated(input_ptr) .or. .not. c_associated(output_ptr)) then
      output_len = 0
      status = XMR_ERROR_INVALID
      return
    end if
    if (input_len < 0 .or. output_max < 32) then
      output_len = 0
      status = XMR_ERROR_BUFFER_TOO_SMALL
      return
    end if
    output_len = 32
    status = XMR_SUCCESS
  end function xmr_generate_key_image

  function xmr_generate_ringct(input_ptr, input_len, output_ptr, output_max, output_len) &
    bind(C, name="xmr_generate_ringct") result(status)
    type(c_ptr), value :: input_ptr
    integer(c_int), value :: input_len
    type(c_ptr), value :: output_ptr
    integer(c_int), value :: output_max
    integer(c_int) :: output_len
    integer(c_int) :: status

    if (.not. c_associated(input_ptr) .or. .not. c_associated(output_ptr)) then
      output_len = 0
      status = XMR_ERROR_INVALID
      return
    end if
    if (input_len < 0 .or. output_max < 1024) then
      output_len = 0
      status = XMR_ERROR_BUFFER_TOO_SMALL
      return
    end if
    output_len = 1024
    status = XMR_SUCCESS
  end function xmr_generate_ringct

  function xmr_verify_ringct(input_ptr, input_len) &
    bind(C, name="xmr_verify_ringct") result(status)
    type(c_ptr), value :: input_ptr
    integer(c_int), value :: input_len
    integer(c_int) :: status

    if (.not. c_associated(input_ptr) .or. input_len < 0) then
      status = XMR_ERROR_INVALID
      return
    end if
    status = XMR_SUCCESS
  end function xmr_verify_ringct

  function xmr_multisig_prepare(input_ptr, input_len, output_ptr, output_max, output_len) &
    bind(C, name="xmr_multisig_prepare") result(status)
    type(c_ptr), value :: input_ptr
    integer(c_int), value :: input_len
    type(c_ptr), value :: output_ptr
    integer(c_int), value :: output_max
    integer(c_int) :: output_len
    integer(c_int) :: status

    if (.not. c_associated(input_ptr) .or. .not. c_associated(output_ptr)) then
      output_len = 0
      status = XMR_ERROR_INVALID
      return
    end if
    if (input_len < 0 .or. output_max < 1024) then
      output_len = 0
      status = XMR_ERROR_BUFFER_TOO_SMALL
      return
    end if
    output_len = 1024
    status = XMR_SUCCESS
  end function xmr_multisig_prepare

  function xmr_multisig_combine(input_ptr, input_len, output_ptr, output_max, output_len) &
    bind(C, name="xmr_multisig_combine") result(status)
    type(c_ptr), value :: input_ptr
    integer(c_int), value :: input_len
    type(c_ptr), value :: output_ptr
    integer(c_int), value :: output_max
    integer(c_int) :: output_len
    integer(c_int) :: status

    if (.not. c_associated(input_ptr) .or. .not. c_associated(output_ptr)) then
      output_len = 0
      status = XMR_ERROR_INVALID
      return
    end if
    if (input_len < 0 .or. output_max < 2048) then
      output_len = 0
      status = XMR_ERROR_BUFFER_TOO_SMALL
      return
    end if
    output_len = 2048
    status = XMR_SUCCESS
  end function xmr_multisig_combine

  function xmr_generate_clsag(input_ptr, input_len, output_ptr, output_max, output_len) &
    bind(C, name="xmr_generate_clsag") result(status)
    type(c_ptr), value :: input_ptr
    integer(c_int), value :: input_len
    type(c_ptr), value :: output_ptr
    integer(c_int), value :: output_max
    integer(c_int) :: output_len
    integer(c_int) :: status

    if (.not. c_associated(input_ptr) .or. .not. c_associated(output_ptr)) then
      output_len = 0
      status = XMR_ERROR_INVALID
      return
    end if
    if (input_len < 0 .or. output_max < 512) then
      output_len = 0
      status = XMR_ERROR_BUFFER_TOO_SMALL
      return
    end if
    output_len = 512
    status = XMR_SUCCESS
  end function xmr_generate_clsag

  function xmr_generate_bulletproof(input_ptr, input_len, output_ptr, output_max, output_len) &
    bind(C, name="xmr_generate_bulletproof") result(status)
    type(c_ptr), value :: input_ptr
    integer(c_int), value :: input_len
    type(c_ptr), value :: output_ptr
    integer(c_int), value :: output_max
    integer(c_int) :: output_len
    integer(c_int) :: status

    if (.not. c_associated(input_ptr) .or. .not. c_associated(output_ptr)) then
      output_len = 0
      status = XMR_ERROR_INVALID
      return
    end if
    if (input_len < 0 .or. output_max < 2048) then
      output_len = 0
      status = XMR_ERROR_BUFFER_TOO_SMALL
      return
    end if
    output_len = 2048
    status = XMR_SUCCESS
  end function xmr_generate_bulletproof

end module monero_crypto
