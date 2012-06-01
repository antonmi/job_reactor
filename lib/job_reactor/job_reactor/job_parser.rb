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
#
# Job and job_callbacks are absolutely identical on the node side.
# They become callback of the Deferrable instance. 'job' is the first callback, 'job_callbacks' are the next
#
# Use job_callbacks to split your job into small parts.
# You can send additional arguments from one callback to another by merging them into 'args'.
# For example:
#
# job 'job' do |args|
#   args.merge!(:another_arg => 'Hello')
# end
#
# job_callback 'job', 'job_callback' do |args|
#   puts args[:another_arg]
# end
#
# This is true for errbacks too. Note that you can't access additional arguments added in callbacks in your errbacks
# In errbacks you also have :error key in args which point the error message
#
# Note, that callbacks and errbacks are called one after another synchronously in one EM tick.
#
# You also have :job_itself in your args. You can turn this option of by setting JR.config[:merge_job_itself_to_args] to false
# :job_itself point to Hash which has the following keys: "node", "id", name", "last_error", "run_at", "failed_at", "attempt", "period", "status"=>"error", "distributor", "on_success", "on_error"
# So, you can all information about the 'job' inside job.
#

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
