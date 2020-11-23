# frozen_string_literal: true

require 'spec_helper'

describe 'mellon::config' do
  let(:title) { 'mysite' }
  let(:params) do
    { sp_metadata: 'foobar',
      idp_metadata: 'foobar',
      sp_private_key: 'foobar',
      sp_cert: 'foobar',
      melloncond: :undef,
      mellonsetenvnoprefix: :undef,
      ignore_location: :undef,
      ignore_location_ip: :undef
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:pre_condition) { 'include ::apache' }
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
