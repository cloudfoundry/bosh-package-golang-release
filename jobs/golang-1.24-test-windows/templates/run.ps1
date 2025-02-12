try {
  Write-Host "Testing compile compatibility"
  & "C:\var\vcap\packages\golang-1.24-windows-test\bin\test.exe"

  Write-Host "Testing runtime compatibility"
  . C:\var\vcap\packages\golang-1.24-windows\bosh\runtime.ps1
  go run C:\var\vcap\packages\golang-1.24-windows-test\test.go
} catch {
  Write-Host "$_.Exception.Message"
  Exit 1
}

Exit 0
