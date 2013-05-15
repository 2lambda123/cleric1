require 'spec_helper'

describe 'Command line' do
  let(:cli_command) { '' }
  let(:cli_help) { `./bin/cleric #{cli_command}` }

  context 'when invoked without arguments' do
    it 'shows the available commands' do
      cli_help.should include('cleric help [COMMAND]')
    end
  end

  it 'has a "auth" command' do
    cli_help.should include('cleric auth')
  end
  it 'has a "repo [COMMAND]" command' do
    cli_help.should include('cleric repo [COMMAND]')
  end

  context 'under the "repo" command' do
    let(:cli_command) { 'repo' }
    it 'has a "create <name>" command' do
      cli_help.should include('cleric repo create <name>')
    end
  end
end

module Cleric
  describe CLI do
    let(:config) { mock('Config') }
    let(:agent) { mock('GitHub').as_null_object }

    before(:each) do
      CLIConfigurationProvider.stub(:new) { config }
      GitHubAgent.stub(:new) { agent }
    end

    shared_examples :github_agent_user do
      it 'creates a configured GitHub agent' do
        GitHubAgent.should_receive(:new).with(config)
      end
    end

    describe '#auth' do
      after(:each) { subject.auth }

      include_examples :github_agent_user
      it 'tells the agent to create an authorization token' do
        agent.should_receive(:create_authorization)
      end
    end

    describe Repo do
      subject(:repo) { Cleric::Repo.new }

      describe '#create' do
        let(:name) { 'example_name' }
        let(:console) { mock(ConsoleAnnouncer) }
        let(:hipchat) { mock(HipChatAnnouncer) }
        let(:manager) { mock(RepoManager).as_null_object }

        before(:each) do
          CLIConfigurationProvider.stub(:new) { config }
          ConsoleAnnouncer.stub(:new) { console }
          HipChatAnnouncer.stub(:new) { hipchat }
          RepoManager.stub(:new) { manager }
          repo.stub_chain(:options, :[]) { '1234' }
        end
        after(:each) { repo.create(name) }

        it 'creates a console announcer' do
          ConsoleAnnouncer.should_receive(:new).with($stdout)
        end
        it 'creates a HipChat console decorating the console announcer' do
          HipChatAnnouncer.should_receive(:new).with(config, console)
        end
        include_examples :github_agent_user
        it 'creates a repo manager configured with the agent' do
          RepoManager.should_receive(:new).with(agent, hipchat)
        end
        it 'delegates creation to the manager' do
          manager.should_receive(:create).with(name, '1234')
        end
      end
    end
  end
end
