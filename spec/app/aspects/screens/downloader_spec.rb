# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Aspects::Screens::Downloader do
  using Refinements::Pathname

  subject(:downloader) { described_class.new settings:, client: }

  include_context "with main application"

  let(:client) { HTTP }

  describe "#call" do
    it "creates root directory when it doesn't exist" do
      temp_dir.rmdir
      downloader.call "https://usetrmnl.com/assets/mashups.png", "abc/test.png"

      expect(temp_dir.join("abc").exist?).to be(true)
    end

    it "downloads file" do
      downloader.call "https://usetrmnl.com/assets/mashups.png", "abc/test.png"
      expect(temp_dir.join("abc/test.png").exist?).to be(true)
    end

    it "marks downloaded file older than oldest file" do
      temp_dir.join("abc/test.txt").make_ancestors.write("test").touch Time.new(2000, 1, 1, 0, 0, 0)
      downloader.call "https://usetrmnl.com/assets/mashups.png", "abc/test.png"

      expect(temp_dir.join("abc/test.png").mtime.year).to eq(1999)
    end

    it "answers nested output path" do
      result = downloader.call "https://usetrmnl.com/assets/mashups.png", "abc/test.png"
      expect(result).to be_success(temp_dir.join("abc/test.png"))
    end

    it "answers non-nested output path" do
      result = downloader.call "https://usetrmnl.com/assets/mashups.png", "test.png"
      expect(result).to be_success(temp_dir.join("test.png"))
    end

    it "answers failure when image can't be downloaded" do
      code = downloader.call("https://test.io/bogus.png", "bogus.png").alt_map { it.status.code }
      expect(code).to be_failure(404)
    end
  end
end
