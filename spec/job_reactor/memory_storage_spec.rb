require 'spec_helper'
require 'job_reactor/storages/memory_storage'

module JobReactor
  module MemoryStorage
    def self.flush_storage
      @storage = {}
    end
  end
end

describe 'Memory storage' do

  before do
    @job = { 'key' => 'value'}
    JR::MemoryStorage.flush_storage
  end

  it 'should save job' do
    JR::MemoryStorage.save(@job)
    expect(JR::MemoryStorage.storage.values.first['key']).to eq('value')
    expect(JR::MemoryStorage.storage.values.first['id']).to_not be_nil
  end

  it 'should save job and call the block' do
    JR::MemoryStorage.save(@job) do |hash|
      expect(hash).to_not be_nil
    end
  end

  it 'should load job' do
    JR::MemoryStorage.save(@job) do |hash|
      @id = hash['id']
    end
    JR::MemoryStorage.load('id' => @id) do |hash|
      expect(hash).to eq(@job)
    end
  end

  it 'should destroy job' do
    JR::MemoryStorage.save(@job) do |hash|
      @id = hash['id']
    end
    JR::MemoryStorage.destroy('id' => @id)
    expect(JR::MemoryStorage.storage).to be_empty
  end

end