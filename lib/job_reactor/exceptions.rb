module JobReactor

  # The purpose of exceptions is in their names
  # TODO

  class NoJobsDefined < RuntimeError
  end
  class NoSuchJob < RuntimeError
  end
  class CancelJob < RuntimeError
  end
  class NodePoolIsEmpty < RuntimeError
  end
  class NoSuchNode < RuntimeError
  end
  class LostConnection < RuntimeError
  end
  class SchedulePeriodicJob < RuntimeError
  end

end


