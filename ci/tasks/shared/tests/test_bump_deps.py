"""Run with Python 3 and Go 1.25+; all modules come from a temporary file proxy."""

import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest
import zipfile


SCRIPT = Path(__file__).resolve().parents[1] / "bump-deps.sh"


class BumpDepsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.proxy = self.root / "proxy"
        self.repo = self.root / "input_repo"
        self.repo.mkdir()
        (self.root / "output_repo").mkdir()
        self.env = dict(os.environ, GOTOOLCHAIN="local", GOWORK="off",
                        GOENV="off", GOFLAGS="", GOSUMDB="off", GOPRIVATE="",
                        GONOPROXY="none", GOPROXY=self.proxy.as_uri(),
                        GOMODCACHE=str(self.root / "modcache"),
                        GOCACHE=str(self.root / "buildcache"),
                        GO_PACKAGE="", SOURCE_PATH="", GOOS_LIST="linux,windows",
                        DESIRED_GO_MAJOR_MINOR="", BUMP_TEST_DEPS="",
                        GIT_USER_NAME="Test", GIT_USER_EMAIL="test@example.com",
                        GIT_COMMIT_MESSAGE_SUFFIX="", GIT_CONFIG_GLOBAL=os.devnull,
                        GIT_CONFIG_NOSYSTEM="1", GIT_TERMINAL_PROMPT="0")
        version = self.run_command("go", "version").stdout
        match = re.search(r"go1\.(\d+)\.", version)
        if not match or int(match[1]) < 25:
            self.skipTest("requires a released Go 1.25+ compiler")
        self.minor = f"1.{int(match[1]) - 1}"
        self.patch = f"{self.minor}.9"
        toolchain = self.proxy / "golang.org/toolchain/@v"
        toolchain.mkdir(parents=True)
        releases = [f"v0.0.1-go{self.minor}.0.linux-amd64",
                    f"v0.0.1-go{self.patch}.linux-amd64"]
        (toolchain / "list").write_text("\n".join(releases) + "\n")
        for release in releases:
            (toolchain / f"{release}.info").write_text(json.dumps({
                "Version": release, "Time": "2025-01-01T00:00:00Z"}))

    def run_command(self, *args, cwd=None, check=True):
        result = subprocess.run(args, cwd=cwd or self.root, env=self.env,
                                text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT)
        if check and result.returncode:
            self.fail(f"{args} failed:\n{result.stdout}")
        return result

    def publish(self, module, version, go_version, files=None, requires=""):
        directory = self.proxy / module / "@v"
        directory.mkdir(parents=True, exist_ok=True)
        go_mod = f"module {module}\n\ngo {go_version}\n{requires}"
        (directory / f"{version}.mod").write_text(go_mod)
        (directory / f"{version}.info").write_text(json.dumps({
            "Version": version, "Time": "2025-01-01T00:00:00Z"}))
        with (directory / "list").open("a") as listing:
            listing.write(version + "\n")
        with zipfile.ZipFile(directory / f"{version}.zip", "w") as archive:
            for name, contents in dict({"go.mod": go_mod}, **(files or {
                    "dep.go": "package dep\n"})).items():
                archive.writestr(f"{module}@{version}/{name}", contents)

    def prepare_repo(self, tool_mode=None):
        (self.repo / "go.mod").write_text(
            f"module example.com/app\n\ngo {self.minor}.0\n"
            "\nrequire example.com/dep v1.0.0\n")
        (self.repo / "app.go").write_text(
            'package app\nimport _ "example.com/dep"\n')
        if tool_mode:
            tools = self.repo / "tools"
            tools.mkdir()
            (tools / "tools.go").write_text(
                'package tools\nimport _ "example.com/tool"\n')
            with (self.repo / "go.mod").open("a") as go_mod:
                go_mod.write("require example.com/tool v1.0.0\n")
                if tool_mode == "directive":
                    go_mod.write("tool example.com/tool\n")
        self.run_command("go", "mod", "tidy", cwd=self.repo)
        self.run_command("git", "init", "-q", cwd=self.repo)
        self.run_command("git", "add", ".", cwd=self.repo)
        self.run_command("git", "-c", "user.name=Test", "-c",
                         "user.email=test@example.com", "commit", "-qm",
                         "Initial fixture", cwd=self.repo)

    def assert_bump_succeeds(self):
        self.run_command("bash", str(SCRIPT))
        output = self.root / "output_repo"
        go_mod = (output / "go.mod").read_text()
        self.assertIn(f"go {self.patch}\n", go_mod)
        self.assertIn("example.com/dep v1.1.0", go_mod)
        self.assertEqual(self.run_command("git", "status", "--porcelain",
                                         cwd=output).stdout, "")
        self.assertEqual(self.run_command("git", "rev-list", "--count", "HEAD",
                                         cwd=output).stdout.strip(), "2")

    def test_accepts_dependency_requiring_previous_minor_patch(self):
        self.publish("example.com/dep", "v1.0.0", f"{self.minor}.0")
        self.publish("example.com/dep", "v1.1.0", self.patch)
        self.prepare_repo()
        self.assert_bump_succeeds()

    def test_upgrades_test_dependencies_of_dependencies(self):
        for version, go_version in [("v1.0.0", f"{self.minor}.0"),
                                    ("v1.1.0", self.patch)]:
            self.publish("example.com/testdep", version, go_version)
        self.publish("example.com/dep", "v1.0.0", f"{self.minor}.0")
        self.publish("example.com/dep", "v1.1.0", f"{self.minor}.0", {
            "dep.go": "package dep\n",
            "dep_test.go": 'package dep\nimport _ "example.com/testdep"\n',
        }, "\nrequire example.com/testdep v1.0.0\n")
        self.prepare_repo()
        self.assert_bump_succeeds()
        self.assertIn("example.com/testdep v1.1.0",
                      (self.root / "output_repo/go.mod").read_text())

    def assert_tool_upgrade(self, mode):
        self.publish("example.com/dep", "v1.0.0", f"{self.minor}.0")
        self.publish("example.com/dep", "v1.1.0", f"{self.minor}.0")
        self.publish("example.com/tool", "v1.0.0", f"{self.minor}.0")
        self.publish("example.com/tool", "v1.1.0", self.patch)
        self.prepare_repo(tool_mode=mode)
        self.assert_bump_succeeds()
        self.assertIn("example.com/tool v1.1.0",
                      (self.root / "output_repo/go.mod").read_text())

    def test_upgrades_legacy_tools(self):
        self.assert_tool_upgrade("legacy")

    def test_upgrades_declared_tools(self):
        self.assert_tool_upgrade("directive")

    def test_rejects_dependency_requiring_next_minor(self):
        self.publish("example.com/dep", "v1.0.0", f"{self.minor}.0")
        next_minor = f"1.{int(self.minor.split('.')[1]) + 1}.0"
        self.publish("example.com/dep", "v1.1.0", next_minor)
        self.prepare_repo()
        result = self.run_command("bash", str(SCRIPT), check=False)
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn(f"requires go@{next_minor}", result.stdout)
        self.assertEqual(self.run_command(
            "git", "rev-list", "--count", "HEAD",
            cwd=self.root / "output_repo").stdout.strip(), "1")


if __name__ == "__main__":
    unittest.main()
