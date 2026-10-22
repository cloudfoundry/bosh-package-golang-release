require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "pathname"
require "tmpdir"
require "uri"

class BumpDepsTest < Minitest::Test
  SCRIPT = File.expand_path("../bump-deps.sh", __dir__)

  def setup
    @root = Pathname(Dir.mktmpdir("bump-deps-test"))
    @proxy = @root / "proxy"
    @repo = @root / "input_repo"
    @repo.mkpath
    (@root / "output_repo").mkpath
    @env = {
      "GOTOOLCHAIN" => "local", "GOWORK" => "off",
      "GOENV" => "off", "GOFLAGS" => "", "GOSUMDB" => "off", "GOPRIVATE" => "",
      "GONOPROXY" => "none", "GOPROXY" => URI::Generic.build(scheme: "file", path: @proxy.to_s).to_s,
      "GOMODCACHE" => (@root / "modcache").to_s,
      "GOCACHE" => (@root / "buildcache").to_s,
      "GO_PACKAGE" => "", "SOURCE_PATH" => "", "GOOS_LIST" => "linux,windows",
      "DESIRED_GO_MAJOR_MINOR" => "", "BUMP_TEST_DEPS" => "",
      "GIT_USER_NAME" => "Test", "GIT_USER_EMAIL" => "test@example.com",
      "GIT_COMMIT_MESSAGE_SUFFIX" => "", "GIT_CONFIG_GLOBAL" => File::NULL,
      "GIT_CONFIG_NOSYSTEM" => "1", "GIT_TERMINAL_PROMPT" => "0"
    }
    version, = run_command("go", "version")
    match = version.match(/go1\.(\d+)\./)
    skip "requires a released Go 1.25+ compiler" unless match && match[1].to_i >= 25

    @minor = "1.#{match[1].to_i - 1}"
    @patch = "#{@minor}.9"
    toolchain = @proxy / "golang.org/toolchain/@v"
    toolchain.mkpath
    releases = ["v0.0.1-go#{@minor}.0.linux-amd64", "v0.0.1-go#{@patch}.linux-amd64"]
    (toolchain / "list").write(releases.join("\n") + "\n")
    releases.each do |release|
      (toolchain / "#{release}.info").write(JSON.generate(
        "Version" => release, "Time" => "2025-01-01T00:00:00Z"
      ))
    end
  end

  def teardown
    return unless @root&.exist?

    FileUtils.chmod_R("u+w", @root)
    FileUtils.remove_entry(@root)
  end

  def test_accepts_dependency_requiring_previous_minor_patch
    publish("example.com/dep", "v1.0.0", "#{@minor}.0")
    publish("example.com/dep", "v1.1.0", @patch)
    prepare_repo
    assert_bump_succeeds
  end

  def test_upgrades_test_dependencies_of_dependencies
    [["v1.0.0", "#{@minor}.0"], ["v1.1.0", @patch]].each do |version, go_version|
      publish("example.com/testdep", version, go_version)
    end
    publish("example.com/dep", "v1.0.0", "#{@minor}.0")
    publish("example.com/dep", "v1.1.0", "#{@minor}.0", files: {
      "dep.go" => "package dep\n",
      "dep_test.go" => "package dep\nimport _ \"example.com/testdep\"\n"
    }, requires: "\nrequire example.com/testdep v1.0.0\n")
    prepare_repo
    assert_bump_succeeds
    assert_includes (@root / "output_repo/go.mod").read, "example.com/testdep v1.1.0"
  end

  def test_upgrades_legacy_tools
    assert_tool_upgrade(:legacy)
  end

  def test_upgrades_declared_tools
    assert_tool_upgrade(:directive)
  end

  def test_rejects_dependency_requiring_next_minor
    publish("example.com/dep", "v1.0.0", "#{@minor}.0")
    next_minor = "1.#{@minor.split(".")[1].to_i + 1}.0"
    publish("example.com/dep", "v1.1.0", next_minor)
    prepare_repo
    output, status = run_command("bash", SCRIPT, check: false)
    refute status.success?, output
    assert_includes output, "requires go@#{next_minor}"
    commits, = run_command("git", "rev-list", "--count", "HEAD", cwd: @root / "output_repo")
    assert_equal "1", commits.strip
  end

  private

  def run_command(*args, cwd: @root, check: true)
    output, status = Open3.capture2e(@env, *args, chdir: cwd)
    flunk "#{args.inspect} failed:\n#{output}" if check && !status.success?
    [output, status]
  end

  def publish(mod, version, go_version, files: {"dep.go" => "package dep\n"}, requires: "")
    directory = @proxy / mod / "@v"
    directory.mkpath
    go_mod = "module #{mod}\n\ngo #{go_version}\n#{requires}"
    (directory / "#{version}.mod").write(go_mod)
    (directory / "#{version}.info").write(JSON.generate(
      "Version" => version, "Time" => "2025-01-01T00:00:00Z"
    ))
    (directory / "list").open("a") { |listing| listing.puts(version) }
    archive_root = @root / "archives"
    {"go.mod" => go_mod}.merge(files).each do |name, contents|
      file = archive_root / "#{mod}@#{version}" / name
      file.dirname.mkpath
      file.write(contents)
    end
    run_command("zip", "-qr", (directory / "#{version}.zip").to_s,
      "#{mod}@#{version}", cwd: archive_root)
  end

  def prepare_repo(tool_mode: nil)
    (@repo / "go.mod").write(<<~MOD)
      module example.com/app

      go #{@minor}.0

      require example.com/dep v1.0.0
    MOD
    (@repo / "app.go").write("package app\nimport _ \"example.com/dep\"\n")
    if tool_mode
      tools = @repo / "tools"
      tools.mkpath
      (tools / "tools.go").write("package tools\nimport _ \"example.com/tool\"\n")
      (@repo / "go.mod").open("a") do |go_mod|
        go_mod.puts("require example.com/tool v1.0.0")
        go_mod.puts("tool example.com/tool") if tool_mode == :directive
      end
    end
    run_command("go", "mod", "tidy", cwd: @repo)
    run_command("git", "init", "-q", cwd: @repo)
    run_command("git", "add", ".", cwd: @repo)
    run_command("git", "-c", "user.name=Test", "-c", "user.email=test@example.com",
      "commit", "-qm", "Initial fixture", cwd: @repo)
  end

  def assert_bump_succeeds
    run_command("bash", SCRIPT)
    output = @root / "output_repo"
    go_mod = (output / "go.mod").read
    assert_includes go_mod, "go #{@patch}\n"
    assert_includes go_mod, "example.com/dep v1.1.0"
    status, = run_command("git", "status", "--porcelain", cwd: output)
    assert_empty status
    commits, = run_command("git", "rev-list", "--count", "HEAD", cwd: output)
    assert_equal "2", commits.strip
  end

  def assert_tool_upgrade(mode)
    publish("example.com/dep", "v1.0.0", "#{@minor}.0")
    publish("example.com/dep", "v1.1.0", "#{@minor}.0")
    publish("example.com/tool", "v1.0.0", "#{@minor}.0")
    publish("example.com/tool", "v1.1.0", @patch)
    prepare_repo(tool_mode: mode)
    assert_bump_succeeds
    assert_includes (@root / "output_repo/go.mod").read, "example.com/tool v1.1.0"
  end
end
