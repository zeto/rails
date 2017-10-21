# frozen_string_literal: true

require "test_helper"
require "database/setup"

class ActiveStorage::AttachmentsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup { @user = User.create!(name: "DHH") }

  teardown { ActiveStorage::Blob.all.each(&:purge) }

  test "attach existing blob" do
    @user.avatar.attach create_blob(filename: "funky.jpg")
    assert_equal "funky.jpg", @user.avatar.filename.to_s
  end

  test "attach existing sgid blob" do
    @user.avatar.attach create_blob(filename: "funky.jpg").signed_id
    assert_equal "funky.jpg", @user.avatar.filename.to_s
  end

  test "attach new blob from a Hash" do
    @user.avatar.attach io: StringIO.new("STUFF"), filename: "town.jpg", content_type: "image/jpg"
    assert_equal "town.jpg", @user.avatar.filename.to_s
  end

  test "attach new blob from an UploadedFile" do
    file = file_fixture "racecar.jpg"
    @user.avatar.attach Rack::Test::UploadedFile.new file
    assert_equal "racecar.jpg", @user.avatar.filename.to_s
  end

  test "replace attached blob" do
    @user.avatar.attach create_blob(filename: "funky.jpg")

    perform_enqueued_jobs do
      assert_no_difference -> { ActiveStorage::Blob.count } do
        @user.avatar.attach create_blob(filename: "town.jpg")
      end
    end

    assert_equal "town.jpg", @user.avatar.filename.to_s
  end

  test "replace attached blob unsuccessfully" do
    @user.avatar.attach create_blob(filename: "funky.jpg")

    perform_enqueued_jobs do
      assert_raises do
        @user.avatar.attach nil
      end
    end

    assert_equal "funky.jpg", @user.reload.avatar.filename.to_s
    assert ActiveStorage::Blob.service.exist?(@user.avatar.key)
  end

  test "access underlying associations of new blob" do
    @user.avatar.attach create_blob(filename: "funky.jpg")
    assert_equal @user, @user.avatar_attachment.record
    assert_equal @user.avatar_attachment.blob, @user.avatar_blob
    assert_equal "funky.jpg", @user.avatar_attachment.blob.filename.to_s
  end

  test "purge attached blob" do
    @user.avatar.attach create_blob(filename: "funky.jpg")
    avatar_key = @user.avatar.key

    @user.avatar.purge
    assert_not @user.avatar.attached?
    assert_not ActiveStorage::Blob.service.exist?(avatar_key)
  end

  test "purge attached blob later when the record is destroyed" do
    @user.avatar.attach create_blob(filename: "funky.jpg")
    avatar_key = @user.avatar.key

    perform_enqueued_jobs do
      @user.destroy

      assert_nil ActiveStorage::Blob.find_by(key: avatar_key)
      assert_not ActiveStorage::Blob.service.exist?(avatar_key)
    end
  end

  test "find with attached blob" do
    records = %w[alice bob].map do |name|
      User.create!(name: name).tap do |user|
        user.avatar.attach create_blob(filename: "#{name}.jpg")
      end
    end

    users = User.where(id: records.map(&:id)).with_attached_avatar.all

    assert_equal "alice.jpg", users.first.avatar.filename.to_s
    assert_equal "bob.jpg", users.second.avatar.filename.to_s
  end


  test "attach existing blobs" do
    @user.highlights.attach create_blob(filename: "funky.jpg"), create_blob(filename: "wonky.jpg")

    assert_equal "funky.jpg", @user.highlights.first.filename.to_s
    assert_equal "wonky.jpg", @user.highlights.second.filename.to_s
  end

  test "attach new blobs" do
    @user.highlights.attach(
      { io: StringIO.new("STUFF"), filename: "town.jpg", content_type: "image/jpg" },
      { io: StringIO.new("IT"), filename: "country.jpg", content_type: "image/jpg" })

    assert_equal "town.jpg", @user.highlights.first.filename.to_s
    assert_equal "country.jpg", @user.highlights.second.filename.to_s
  end

  test "find attached blobs" do
    @user.highlights.attach(
      { io: StringIO.new("STUFF"), filename: "town.jpg", content_type: "image/jpg" },
      { io: StringIO.new("IT"), filename: "country.jpg", content_type: "image/jpg" })

    highlights = User.where(id: @user.id).with_attached_highlights.first.highlights

    assert_equal "town.jpg", highlights.first.filename.to_s
    assert_equal "country.jpg", highlights.second.filename.to_s
  end

  test "access underlying associations of new blobs" do
    @user.highlights.attach(
      { io: StringIO.new("STUFF"), filename: "town.jpg", content_type: "image/jpg" },
      { io: StringIO.new("IT"), filename: "country.jpg", content_type: "image/jpg" })

    assert_equal @user, @user.highlights_attachments.first.record
    assert_equal @user.highlights_attachments.collect(&:blob).sort, @user.highlights_blobs.sort
    assert_equal "town.jpg", @user.highlights_attachments.first.blob.filename.to_s
  end


  test "purge attached blobs" do
    @user.highlights.attach create_blob(filename: "funky.jpg"), create_blob(filename: "wonky.jpg")
    highlight_keys = @user.highlights.collect(&:key)

    @user.highlights.purge
    assert_not @user.highlights.attached?
    assert_not ActiveStorage::Blob.service.exist?(highlight_keys.first)
    assert_not ActiveStorage::Blob.service.exist?(highlight_keys.second)
  end

  test "purge attached blobs later when the record is destroyed" do
    @user.highlights.attach create_blob(filename: "funky.jpg"), create_blob(filename: "wonky.jpg")
    highlight_keys = @user.highlights.collect(&:key)

    perform_enqueued_jobs do
      @user.destroy

      assert_nil ActiveStorage::Blob.find_by(key: highlight_keys.first)
      assert_not ActiveStorage::Blob.service.exist?(highlight_keys.first)

      assert_nil ActiveStorage::Blob.find_by(key: highlight_keys.second)
      assert_not ActiveStorage::Blob.service.exist?(highlight_keys.second)
    end
  end
end
