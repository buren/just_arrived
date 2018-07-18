# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateChatMessageService do
  describe '#create' do
    let(:author) { FactoryBot.create(:user) }
    let(:chat) { FactoryBot.create(:chat) }
    let(:language_id) { FactoryBot.create(:language).id }
    let(:body) { 'Watwoman, watman.' }

    subject do
      described_class.create(
        chat: chat,
        language_id: language_id,
        body: body,
        author: author
      )
    end

    it 'creates one new message' do
      expect { subject }.to change(Message, :count).by(1)
    end

    it 'calls messsage created notifier' do
      allow(NewChatMessageNotifier).to receive(:call)
      subject
      expect(NewChatMessageNotifier).to have_received(:call).once
    end

    it 'sends message to admin' do
      allow(DeliverNotification).to receive(:call)
      subject
      expect(DeliverNotification).to have_received(:call).once
    end
  end

  describe '#send_notification?' do
    context 'valid message' do
      it 'returns true if last_message is nil' do
        message = FactoryBot.create(:message)
        result = described_class.send_notification?(message: message, last_message: nil)
        expect(result).to eq(true)
      end

      it 'returns true last_message is older than SEND_IF_NO_MESSAGE_IN_HOURS hours' do
        some_hours_ago = (described_class::SEND_IF_NO_MESSAGE_IN_HOURS + 1).hours.ago
        message = FactoryBot.create(:message)
        last_message = FactoryBot.create(:message, created_at: some_hours_ago)

        result = described_class.send_notification?(
          message: message,
          last_message: last_message
        )
        expect(result).to eq(true)
      end

      it 'returns false last_message is older than SEND_IF_NO_MESSAGE_IN_HOURS hours' do
        few_hours_ago = (described_class::SEND_IF_NO_MESSAGE_IN_HOURS - 1).hours.ago
        message = FactoryBot.create(:message)
        last_message = FactoryBot.create(:message, created_at: few_hours_ago)

        result = described_class.send_notification?(
          message: message,
          last_message: last_message
        )
        expect(result).to eq(false)
      end
    end
  end
end
