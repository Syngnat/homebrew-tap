# frozen_string_literal: true

require "open3"
require "tmpdir"

class RenderGonaviPackageTest
  SCRIPT = File.expand_path("../script/render-gonavi-package", __dir__).freeze

  def initialize
    @assertions = 0
  end

  def run
    test_renders_source_build_formula
    test_renders_notarized_asset_cask_without_shared_data_zap
    test_rejects_unstable_version
    test_rejects_malformed_checksum
    puts "#{@assertions} assertions passed"
  end

  private

  def with_temporary_tap
    Dir.mktmpdir("gonavi-tap-test") do |temporary_directory|
      @tap_root = File.join(temporary_directory, "tap")
      yield
    ensure
      @tap_root = nil
    end
  end

  def render(*arguments)
    Open3.capture3(
      { "GONAVI_TAP_ROOT" => @tap_root },
      SCRIPT,
      *arguments,
    )
  end

  def assert(condition, message)
    @assertions += 1
    raise message unless condition
  end

  def assert_includes(content, expected)
    assert(content.include?(expected), "expected #{content.inspect} to include #{expected.inspect}")
  end

  def refute_includes(content, expected)
    assert(content.index(expected).nil?, "expected #{content.inspect} not to include #{expected.inspect}")
  end

  def test_renders_source_build_formula
    with_temporary_tap do
      stdout, stderr, status = render("formula", "1.2.3", "a" * 64)

      assert(status.success?, stderr)
      assert(stdout.strip == File.join(@tap_root, "Formula", "gonavi.rb"), "unexpected Formula path")

      formula = File.read(stdout.strip)
      assert_includes formula, "/refs/tags/v1.2.3.tar.gz"
      assert_includes formula, "depends_on \"go\" => :build"
      assert_includes formula, "ENV[\"CGO_ENABLED\"] = \"0\""
      refute_includes formula, "ldflags = \"-s -w"
      assert_includes formula, "\"./cmd/gonavi\""
      assert_includes formula, "(testpath/\"data\").to_s"
    end
  end

  def test_renders_notarized_asset_cask_without_shared_data_zap
    with_temporary_tap do
      stdout, stderr, status = render("cask", "1.2.3", "b" * 64, "c" * 64)

      assert(status.success?, stderr)

      cask = File.read(stdout.strip)
      assert_includes cask, "GoNavi-\#{version}-MacOS-\#{arch}.dmg"
      assert_includes cask, "app \"GoNavi.app\""
      refute_includes cask, "~/.gonavi"
      refute_includes cask, "zap"
    end
  end

  def test_rejects_unstable_version
    with_temporary_tap do
      _stdout, stderr, status = render("formula", "1.2.3-beta.1", "a" * 64)

      assert(!status.success?, "unstable version unexpectedly succeeded")
      assert_includes stderr, "stable x.y.z"
      assert(!File.exist?(File.join(@tap_root, "Formula", "gonavi.rb")), "Formula was unexpectedly written")
    end
  end

  def test_rejects_malformed_checksum
    with_temporary_tap do
      _stdout, stderr, status = render("formula", "1.2.3", "TODO")

      assert(status.exitstatus == 2, "malformed checksum returned #{status.exitstatus}")
      assert_includes stderr, "Usage:"
      assert(!File.exist?(File.join(@tap_root, "Formula", "gonavi.rb")), "Formula was unexpectedly written")
    end
  end
end

RenderGonaviPackageTest.new.run
