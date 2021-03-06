require 'rails_helper'

RSpec.describe 'duckrails/mocks/index.html.erb', type: :view do
  let(:with_mocks) { false }
  let(:per_page) { nil }
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    3.times do |i|
      FactoryGirl.create(:mock, name: "Mock-#{i + 1}", route_path: "/duck/#{i}")
    end if with_mocks

    assign :mocks, Duckrails::Mock.page(0).per(per_page)

    render
  end

  subject { page }

  context 'content' do
    it { should have_css 'h1', text: t(:mocks) }
    it { should have_css 'p.page-guide', text: t(:mocks_index_page_guide) }

    context 'without mocks' do
      it { should have_css '.alert-box.warning', text: t(:no_mocks_warning) }
      it { should_not have_css 'table.mocks' }
    end

    context 'with mocks' do
      let(:per_page) { 10 }
      let(:with_mocks) { true }

      it { should_not have_css '.alert-box.warning', text: t(:no_mocks_warning) }

      context 'table' do
        subject { page.find 'table.mocks' }

        it { should have_css 'thead th', text: t(:mock_name) }
        it { should have_css 'thead th', text: t(:mock_method) }
        it { should have_css 'thead th', text: t(:mock_route) }
        it { should have_css 'thead th', text: t(:mock_actions) }

        it 'should display all mocks' do
          mocks = Duckrails::Mock.all

          expect(subject).to have_css 'tbody tr', count: mocks.size

          mocks.each do |mock|
            expect(subject).to have_css "tbody tr[data-mock-id='#{mock.id}'] td", text: mock.name
            expect(subject).to have_css "tbody tr[data-mock-id='#{mock.id}'] td", text: mock.request_method
            expect(subject).to have_css "tbody tr[data-mock-id='#{mock.id}'] td", text: mock.route_path
            expect(subject).to have_css "tbody tr[data-mock-id='#{mock.id}'] td.actions a[href='#{view.edit_duckrails_mock_path(mock)}']"
            expect(subject).to have_css "tbody tr[data-mock-id='#{mock.id}'] td.actions a[href='#{view.duckrails_mock_path(mock)}'][data-method='delete']"
          end
        end
      end

      context 'without pagination' do
        it { should_not have_css 'nav.pagination' }
      end

      context 'with pagination' do
        let(:per_page) { 2 }

        it { should have_css 'nav.pagination'}
      end
    end

    context 'actions' do
      it { should have_css "a[href='#{new_duckrails_mock_path}']", text: t(:create_new_mock) }
    end
  end
end
