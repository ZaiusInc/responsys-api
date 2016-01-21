require "spec_helper.rb"
require "responsys/api/client"

describe Responsys::Member do

  before(:all) do
    @email = DATA[:users][:user1][:EMAIL_ADDRESS]
    @riid = DATA[:users][:user1][:RIID]
    @list = Responsys::Api::Object::InteractObject.new(DATA[:folder],DATA[:lists][:list1][:name])
  end

  context "New member" do
    before(:each) do
      @new_user_email = DATA[:users][:new_user4][:EMAIL_ADDRESS]
      @client = Responsys::Api::Client.new
      @member = Responsys::Member.new(@new_user_email, nil, @client)
    end

    it "should call mergeListMembers" do
      expect(@client).to receive(:merge_list_members_riid).with(@list, kind_of(Responsys::Api::Object::RecordData), kind_of(Responsys::Api::Object::ListMergeRule))
      @member.add_to_list(@list)
    end

  end

  context "Subscribing" do

    before(:each) do
      @member = Responsys::Member.new(@email)
      @query_column = Responsys::Api::Object::QueryColumn.new("EMAIL_ADDRESS")
    end

    it "should check the user is present in the list" do
      expect(@member).to receive(:present_in_list?).with(@list, true)

      @member.subscribe(@list)
    end

    it "should check the user has subscribed" do
      VCR.use_cassette("member/has_subscribed") do
        expect(@member.subscribed?(@list)).to eq(true)
      end
    end

  end

  context "Existing member" do

    it "should be ok, the email is present" do
      VCR.use_cassette("member/present1") do
        member_without_riid = Responsys::Member.new(@email)
        bool = member_without_riid.present_in_list?(@list)

        expect(bool).to eq(true)
      end
    end

    it "should be ok, the email and riid is present" do
      VCR.use_cassette("member/present2") do
        member_with_riid = Responsys::Member.new(@email, @riid)
        bool = member_with_riid.present_in_list?(@list)

        expect(bool).to eq(true)
      end
    end

    it "should fail, the email is not present" do
      VCR.use_cassette("member/present3") do
        member_with_fake_email = Responsys::Member.new("thisemailis@notpresent.com")
        bool = member_with_fake_email.present_in_list?(@list)

        expect(bool).to eq(false)
      end
    end

    it "should fail, the email is present but not the riid" do
      VCR.use_cassette("member/present4") do
        member_with_fake_riid = Responsys::Member.new(@email, "000001")
        bool = member_with_fake_riid.present_in_list?(@list)

        expect(bool).to eq(false)
      end
    end

    it "should return the record_not_found code message" do
      VCR.use_cassette("member/present5") do
        member_with_fake_riid = Responsys::Member.new(@email, "000001")
        response = member_with_fake_riid.subscribed?(@list)

        expect(response[:error][:code]).to eq("record_not_found")
      end
    end

  end

  context "Get profile extension data" do

    before(:all) do
      @profile_extension = Responsys::Api::Object::InteractObject.new(DATA[:folder], DATA[:pets][:pet1][:name])
      @member_without_riid = Responsys::Member.new(@email)
      @member_with_riid = Responsys::Member.new(@email, @riid)
      @fields = %w(RIID_ MONTHLY_PURCH)
    end

    it "should set the status to failure if no riid provided" do
      VCR.use_cassette("member/retrieve_profile_extension_fail") do
        response = @member_without_riid.retrieve_profile_extension(@profile_extension, @fields)

        expect(response[:status]).to eq("failure")
      end
    end

    it "should set a i18n message in the response if no riid provided" do
      VCR.use_cassette("member/retrieve_profile_extension_fail") do
        response = @member_without_riid.retrieve_profile_extension(@profile_extension, @fields)

        expect(response[:error][:message]).to eq(Responsys::Helper.get_message("member.riid_missing"))
      end
    end

    it "should set the status to ok" do
      VCR.use_cassette("member/retrieve_profile_extension") do
        response = @member_with_riid.retrieve_profile_extension(@profile_extension, @fields)

        expect(response[:status]).to eq("ok")
      end
    end

  end

  context "Disabled GEM" do
    before(:all) do
      Responsys.configure { |config| config.settings[:enabled] = false }
    end

    after(:all) do
      Responsys.configure { |config| config.settings[:enabled] = true }
    end

    it "should not make any call" do
      email = DATA[:users][:user1][:EMAIL_ADDRESS]
      list = Responsys::Api::Object::InteractObject.new(DATA[:folder],DATA[:lists][:list1][:name])
      query_column = Responsys::Api::Object::QueryColumn.new("EMAIL_ADDRESS")

      expect_any_instance_of(Responsys::Api::SessionPool).to_not receive(:with)
      expect(Responsys::Member.new(email).subscribe(list)).to eq("disabled")
    end
  end
end