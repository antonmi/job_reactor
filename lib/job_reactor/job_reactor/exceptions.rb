module JobReactor

  # The purpose of exceptions is in their names
  # TODO

  class NoSuchJob < RuntimeError
  end
  class CancelJob < RuntimeError
  end

end


