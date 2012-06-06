def wait_until(max_wait_time = 5)
  counter = 0
  until (block_given? && yield) || counter > max_wait_time
    sleep(1)
    counter = counter.succ
  end
end
