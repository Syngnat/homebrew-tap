# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "open3"
require "tmpdir"

class RenderGonaviPackageTest < Minitest::Test
  SCRIPT = File.expand_path("../script/render-gonavi-package", __dir__).freeze

  def render(*arguments)
    Open3.capture3(
      { "GONAVI_TAP_ROOT" => @tap_root },
      SCRIPT,
      *arguments,
    )
  end

  def setup
    @temporary_directory = Dir.mktmpdir("gonavi-tap-test")
    @tap_root = File.join(@temporary_directory, "tap")
  end

  def teardown
    FileUtils.remove_entry(@temporary_directory)
  end

  def test_renders_source_build_formula
    stdout, stderr, status = render("formula", "1.2.3", "a" * 64)

    assert_predicate status, :success?, stderr
    assert_equal File.join(@tap_root, "Formula", "gonavi.rb"), stdout.strip

    formula = File.read(stdout.strip)
    assert_includes formula, "/refs/tags/v1.2.3.tar.gz"
    assert_includes formula, "depends_on \"go\" => :build"
    assert_includes formula, "ENV[\"CGO_ENABLED\"] = \"0\""
    refute_includes formula, "ldflags = \"-s -w"
    assert_includes formula, "\"./cmd/gonavi\""
    assert_includes formula, "(testpath/\"data\").to_s"
  end

  def test_renders_notarized_asset_cask_without_shared_data_zap
    stdout, stderr, status = render("cask", "1.2.3", "b" * 64, "c" * 64)

    assert_predicate status, :success?, stderr

    cask = File.read(stdout.strip)
    assert_includes cask, "GoNavi-\#{version}-MacOS-\#{arch}.dmg"
    assert_includes cask, "app \"GoNavi.app\""
    refute_includes cask, "~/.gonavi"
    refute_includes cask, "zap"
  end

  def test_rejects_unstable_version
    _stdout, stderr, status = render("formula", "1.2.3-beta.1", "a" * 64)

    refute_predicate status, :success?
    assert_includes stderr, "stable x.y.z"
    refute File.exist?(File.join(@tap_root, "Formula", "gonavi.rb"))
  end

  def test_rejects_malformed_checksum
    _stdout, stderr, status = render("formula", "1.2.3", "TODO")

    assert_equal 2, status.exitstatus
    assert_includes stderr, "Usage:"
    refute File.exist?(File.join(@tap_root, "Formula", "gonavi.rb"))
  end
end
