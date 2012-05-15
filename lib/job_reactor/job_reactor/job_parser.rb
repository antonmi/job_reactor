# parse jobs defined in the JR.config[:job_directory]
# build hash of the following structure:
# {"job_1" => {
#    job:  Proc,
#    callbacks: [
#        ["first_callback", Proc],
#        ["second_callback", Proc]
#    ],
#    errbacks: [
#        ["first_errback", Proc],
#        ["second_errback", Proc]
#    ]
# },
# "job_2" => {
#     job: Proc,
#     callbacks: [[]],
#     errbacks: [[]]
#  }
# }
# Names of callbacks and errbacks are optional and may be used just for description

module JobReactor
  extend self

  def job(name, &block)
    JR.jobs.merge!(name => { job: block })
  end

  def job_callback(name, callback_name = 'noname', &block)
    JR.jobs[name].merge!(callbacks: []) unless JR.jobs[name][:callbacks]
    JR.jobs[name][:callbacks] << [callback_name, block]
  end

  def job_errback(name, errback_name = 'noname', &block)
    JR.jobs[name].merge!(errbacks: []) unless JR.jobs[name][:errbacks]
    JR.jobs[name][:errbacks] << [errback_name, block]
  end

end
