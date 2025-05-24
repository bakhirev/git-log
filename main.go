package assayo

import (
 "fmt"
 "os"
 "os/exec"
 "path/filepath"
)

func showMessage(message string) {
 for _, arg := range os.Args {
  if arg == "--debug" {
   fmt.Println("Assayo: " + message)
   break
  }
 }
}

func getSaveLogCommand(fileName string) string {
 raw := "--raw --numstat"
 for _, arg := range os.Args {
  if arg == "--no-file" {
   raw = ""
   break
  }
 }
 return fmt.Sprintf("git --no-pager log %s --oneline --all --reverse --date=iso-strict --pretty=format:\"%%ad>%%aN>%%aE>%%s\" > %s", raw, fileName)
}

func Assayo() error {
 // folder, when library was saved
 sourceDir := "../pkg/mod/github/bakhirev/git-log@v0.0.3/assayo"
 sourcePath := filepath.Dir(os.Args[0])

 // folder, when user run library
 distDir := "assayo"
 distPath, _ := os.Getwd()

 // 1. Copy folder ./assayo from package to ./assayo in project
 source := filepath.Join(sourcePath, sourceDir)
 target := filepath.Join(distPath, distDir)
 command := exec.Command("cp", "-r", source, target)
 if err := command.Run(); err != nil {
  fmt.Println("Error copying directory:", err)
  return err
 }
 showMessage("directory with HTML report was created")

 // 2. Run 'git log' and save output in file ./assayo/log.txt
 showMessage("reading git log was started")
 fileName := filepath.Join(distPath, distDir, "log.txt")
 commandStr := getSaveLogCommand(fileName)
 command = exec.Command("bash", "-c", commandStr)
 if err := command.Run(); err != nil {
  fmt.Println("Error saving git log:", err)
  return err
 }
 showMessage("the file with git log was saved")

 // 3. Replace symbols in ./assayo/log.txt
 content, err := os.ReadFile(fileName)
 if err != nil {
  fmt.Println("Error reading file:", err)
  return err
 }
 newContent := string(content)
 newContent = "" + newContent + ");\nr(f`"
 if err := os.WriteFile(fileName, []byte("R(f`"+newContent+"`);"), 0644); err != nil {
  fmt.Println("Error writing file:", err)
  return err
 }

 return nil
}

func Init() {
 Assayo()
}

func Main() {
 Assayo()
}
