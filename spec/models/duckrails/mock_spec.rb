require 'rails_helper'

module Duckrails
  RSpec.describe Mock, type: :model do
    context 'attributes' do
      it { should respond_to :headers, :headers= }
      it { should respond_to :status, :status= }
      it { should respond_to :request_method, :request_method= }
      it { should respond_to :content_type, :content_type= }
      it { should respond_to :route_path, :route_path= }
      it { should respond_to :name, :name= }
      it { should respond_to :body_type, :body_type= }
      it { should respond_to :body_content, :body_content= }
      it { should respond_to :script_type, :script_type= }
      it { should respond_to :script, :script= }
    end

    context 'relations' do
      it { should have_many(:headers).dependent(:destroy) }
      it { should accept_nested_attributes_for(:headers).allow_destroy(true) }

      it 'should reject headers if all values are nil' do
        mock = FactoryGirl.build(:mock)
        mock.headers_attributes = [{}]
        expect(mock.save).to be true
      end
    end

    context 'validations' do
      context 'presence' do
        it { should validate_presence_of :status }
        it { should validate_presence_of :request_method}
        it { should validate_presence_of :content_type}
        it { should validate_presence_of :route_path}
        it { should validate_presence_of :name }

        context '#body_type' do
          it 'should not validate presence if body content is empty' do
            mock = FactoryGirl.build :mock, body_content: nil
            expect(mock).not_to validate_presence_of :body_type
          end

          it 'should validate presence if body content is present' do
            mock = FactoryGirl.build :mock, body_content: 'DuckRails'
            expect(mock).to validate_presence_of :body_type
          end
        end

        context '#body_content' do
          it 'should not validate presence if body type is empty' do
            mock = FactoryGirl.build :mock, body_type: nil
            expect(mock).not_to validate_presence_of :body_content
          end

          it 'should validate presence if body type is present' do
            mock = FactoryGirl.build :mock, body_type: 'embedded_ruby'
            expect(mock).to validate_presence_of :body_content
          end
        end

        context '#script_type' do
          it 'should not validate presence if script content is empty' do
            mock = FactoryGirl.build :mock, script: nil
            expect(mock).not_to validate_presence_of :script_type
          end

          it 'should validate presence if script content is present' do
            mock = FactoryGirl.build :mock, script: 'DuckRails'
            expect(mock).to validate_presence_of :script_type
          end
        end

        context '#script' do
          it 'should not validate presence if script type is empty' do
            mock = FactoryGirl.build :mock, script_type: nil
            expect(mock).not_to validate_presence_of :script
          end

          it 'should validate presence if script type is present' do
            mock = FactoryGirl.build :mock, script_type: 'embedded_ruby'
            expect(mock).to validate_presence_of :script
          end
        end
      end

      context 'uniqueness' do
        context '#name' do
          subject { FactoryGirl.build :mock }

          it { should validate_uniqueness_of(:name) }

          it 'should validate uniqueness without case sensitivity' do
            FactoryGirl.create(:mock)
            mock = FactoryGirl.build(:mock, name: 'Default MOCK')
            expect(mock).to be_invalid
            expect(mock.errors[:name]).to include('has already been taken')
          end
        end

        context '#route_path' do
          it 'should not allow duplicates with same methods' do
            FactoryGirl.create(:mock)

            mock = FactoryGirl.build(:mock)
            expect(mock).to be_invalid
            expect(mock.errors[:route_path]).to include 'has already been taken'
          end

          it 'should allow duplicates with different methods' do
            FactoryGirl.create(:mock)

            mock = FactoryGirl.build(:mock, request_method: 'post')
            expect(mock).to be_invalid
            expect(mock.errors[:route_path].size).to eq 0
          end
        end
      end

      context 'inclusion' do
        it { should validate_inclusion_of(:body_type).
          in_array([Duckrails::Mock::SCRIPT_TYPE_STATIC,
            Duckrails::Mock::SCRIPT_TYPE_EMBEDDED_RUBY])
        }

        it {
          should validate_inclusion_of(:script_type).
          in_array([Duckrails::Mock::SCRIPT_TYPE_STATIC,
            Duckrails::Mock::SCRIPT_TYPE_EMBEDDED_RUBY])
        }
      end

      context 'route' do
        context 'with Bad URI' do
          it 'should be invalid' do
            mock = FactoryGirl.build :mock, route_path: 'httpgih[]com'

            expect(mock).to be_invalid
            expect(mock.errors[:route_path]).to include 'is not a valid route'
          end
        end

        context 'with action not served by the mocks controller' do
          it 'should be invalid' do
            mock = FactoryGirl.build :mock, route_path: '/'

            expect(mock).to be_invalid
            expect(mock.errors[:route_path]).to include 'already in use'
          end
        end

        context 'with action served by the mocks controller but not by the #serve_mock method' do
          it 'should be invalid' do
            mock = FactoryGirl.build :mock, route_path: '/duckrails/mocks'

            expect(mock).to be_invalid
            expect(mock.errors[:route_path]).to include 'already in use'
          end
        end

        context 'with action served by the mocks controller, by the #serve_mock method but for another mock' do
          it 'should be invalid' do
            FactoryGirl.create :mock
            mock = FactoryGirl.build :mock

            expect(mock).to be_invalid
            expect(mock.errors[:route_path]).to include 'has already been taken'
          end
        end

        context 'updating an existing mock without changing the route passes' do
          it 'should be valid' do
            mock = FactoryGirl.create :mock
            mock.name = 'Changed Default Name'
            expect(mock).to be_valid
          end
        end
      end
    end

    context 'methods' do
      describe '#dynamic?' do
        let(:body_type) { nil }

        subject { FactoryGirl.build(:mock, body_type: body_type).dynamic? }

        context 'with static body type' do
          let(:body_type) { Duckrails::Mock::SCRIPT_TYPE_STATIC }

          it { should be false }
        end

        context 'with embedded ruby body type' do
          let(:body_type) { Duckrails::Mock::SCRIPT_TYPE_EMBEDDED_RUBY }

          it { should be true }
        end
      end
    end

    context 'callbacks' do
      describe '#after_save' do
        let(:mock) { FactoryGirl.build(:mock) }

        before do
          expect(Duckrails::Router).to receive(:register_mock).with(mock).once
        end

        it 'registers the mock' do
          expect(mock.save).to be true
        end
      end

      describe '#after_destroy' do
        let(:mock) { FactoryGirl.create(:mock) }

        before do
          expect(Duckrails::Router).to receive(:unregister_mock).with(mock).once
        end

        it 'registers the mock' do
          expect(mock.destroy).to eq mock
        end
      end
    end

    context 'CRUD' do
      it 'should save mocks' do
        mock = FactoryGirl.build :mock

        expect{ mock.save }.to change(Mock, :count).from(0).to(1)
      end

      it 'should update mocks' do
        mock = FactoryGirl.create :mock

        mock.name = 'Another Default mock'
        expect(mock.save).to be true

        mock.reload
        expect(mock.name).to eq 'Another Default mock'
      end

      it 'should destroy mocks' do
        mock = FactoryGirl.create :mock

        expect{ mock.destroy }.to change(Mock, :count).from(1).to(0)
      end

      it 'should save headers' do
        mock = FactoryGirl.build :mock, headers: [ FactoryGirl.build(:header) ]

        expect{ mock.save }.to change(Header, :count).from(0).to(1)

        mock.reload
        expect(mock.headers.size).to eq 1
      end
    end
  end
end
