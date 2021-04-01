# frozen_string_literal: true

RSpec.describe KLog do
  it 'has a version number' do
    expect(KLog::VERSION).not_to be nil
  end

  it 'has a standard error' do
    expect { raise KLog::Error, 'some message' }
      .to raise_error('some message')
  end

  describe '#default_logger' do
    subject { described_class.default_logger }

    it { is_expected.not_to be_nil }
  end
end
