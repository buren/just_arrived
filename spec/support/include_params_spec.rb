# frozen_string_literal: true
require 'spec_helper'

RSpec.describe IncludeParams do
  describe '#permit' do
    describe 'many includes in param' do
      let(:param) { described_class.new('users,jobs') }

      it 'can return none' do
        expect(param.permit([])).to eq([])
        expect(param.permit('')).to eq([])
      end

      it 'can return one' do
        expect(param.permit(['users'])).to eq(['users'])
        expect(param.permit('users')).to eq(['users'])
      end

      it 'can return many' do
        expect(param.permit(%w(users jobs))).to eq(%w(users jobs))
        expect(param.permit('users', 'jobs')).to eq(%w(users jobs))
      end
    end

    describe 'one include in param' do
      let(:param) { described_class.new('users') }

      it 'can return none' do
        expect(param.permit([])).to eq([])
        expect(param.permit('')).to eq([])
        expect(param.permit('jobs')).to eq([])
      end

      it 'can return one' do
        expect(param.permit(['users'])).to eq(['users'])
        expect(param.permit('users')).to eq(['users'])
        expect(param.permit('users', 'jobs')).to eq(['users'])
      end
    end

    describe 'nil param' do
      let(:nil_param) { described_class.new(nil) }

      it 'returns empty list' do
        expect(nil_param.permit('')).to eq([])
      end
    end
  end
end
