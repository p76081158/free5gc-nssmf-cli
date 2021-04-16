package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	prompt "github.com/c-bata/go-prompt"
)

var suggestions = []prompt.Suggest{
	// Command
	{Text: "create", Description: "Create Network Slice yaml"},
	{Text: "list", Description: "List Network Slice"},
	{Text: "apply", Description: "Apply Network Slice to Core Network"},
	{Text: "delete", Description: "Delete Network Slice from Core Network"},
	{Text: "remove", Description: "Romve Network Slice yaml"},
	{Text: "help", Description: "Command Detail"},
	{Text: "exit", Description: "Exit free5gc-nssmf-cli"},
}

var applySuggestions = []prompt.Suggest{}

func list_reload() {
	applySuggestions = []prompt.Suggest{}
	input_cmd := "cd network-slice && ls"
	out, err := exec.Command("/bin/sh", "-c", input_cmd).Output()
	slices := strings.Split(string(out), "\n")
	for i := 0; i < len(slices)-1; i++ {
		slice := slices[i]
		sst := slice[2:4]
		sd := slice[4:]
		des := "sst: " + sst + ", sd: " + sd
		fmt.Println(des)
		applySuggestions = append(applySuggestions, prompt.Suggest{Text: slices[i], Description: des})
	}
}

var deleteSuggestions = []prompt.Suggest{}

func Executor(in string) {
	in = strings.TrimSpace(in)
	if in == "" {
		return
	} else if in == "quit" || in == "exit" {
		fmt.Println("Bye!")
		os.Exit(0)
		return
	}

	blocks := strings.Split(in, " ")
	switch blocks[0] {
	case "create":
		slice_cmd := "shell-script/slice-create.sh " + blocks[1]
		input_cmd := slice_cmd
		cmd := exec.Command("/bin/sh", "-c", input_cmd)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			fmt.Printf("Got error: %s\n", err.Error())
		}
		list_reload()
		return
	case "list":
		input_cmd := "cd network-slice && ls"
		out, err := exec.Command("/bin/sh", "-c", input_cmd).Output()
		slices := strings.Split(string(out), "\n")
		for i := 0; i < len(slices)-1; i++ {
			slice := slices[i]
			sst := slice[2:4]
			sd := slice[4:]
			des := "sst: " + sst + ", sd: " + sd
			fmt.Println(des)
			applySuggestions = append(applySuggestions, prompt.Suggest{Text: slices[i], Description: des})
		}

		//fmt.Printf(test[1])
		if err != nil {
			fmt.Printf("Got error: %s\n", err.Error())
		}
		return
	case "apply":
		slice_cmd := "shell-script/slice-apply.sh " + blocks[1]
		input_cmd := slice_cmd
		cmd := exec.Command("/bin/sh", "-c", input_cmd)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			fmt.Printf("Got error: %s\n", err.Error())
		}
		return
	case "delete":
		slice_cmd := "shell-script/slice-delete.sh " + blocks[1]
		input_cmd := slice_cmd
		cmd := exec.Command("/bin/sh", "-c", input_cmd)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			fmt.Printf("Got error: %s\n", err.Error())
		}
		return
	case "remove":
		slice_cmd := "shell-script/slice-recycle.sh " + blocks[1]
		input_cmd := slice_cmd
		cmd := exec.Command("/bin/sh", "-c", input_cmd)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			fmt.Printf("Got error: %s\n", err.Error())
		}
		return
	case "help":
		//slice_cmd := "shell-script/slice-recycle.sh " + blocks[1]
		//input_cmd := slice_cmd
		//cmd := exec.Command("/bin/sh", "-c", input_cmd)
		cmd := exec.Command("/bin/sh", "-c", "ls")
		//output, _ := cmd.CombinedOutput()
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			fmt.Printf("Got error: %s\n", err.Error())
		}
		//test := strings.Split(string(output), " ")
		//fmt.Printf(string(output))

		return
	}
}

func Completer(in prompt.Document) []prompt.Suggest {
	a := in.TextBeforeCursor()
	split := strings.Split(a, " ")
	w := in.GetWordBeforeCursor()
	if len(split) > 1 {
		v := split[0]
		if v == "apply" {
			return prompt.FilterHasPrefix(applySuggestions, w, true)
		}
	}
	//if w == "" {
	//	return []prompt.Suggest{}
	//}
	return prompt.FilterHasPrefix(suggestions, w, true)
}

func main() {

	p := prompt.New(
		Executor,
		Completer,
		prompt.OptionPrefix("free5gc-nssmf-cli"+" >> "),
		prompt.OptionTitle("free5gc-nssmf-cli"),
	)
	p.Run()
}
