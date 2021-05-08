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
	{Text: "remove", Description: "Romve Network Slice yaml"},
	{Text: "list", Description: "List Network Slice yaml"},
	{Text: "apply", Description: "Apply Network Slice to Core Network"},
	{Text: "delete", Description: "Delete Network Slice from Core Network"},
	{Text: "info", Description: "List Network Slice info"},
	{Text: "status", Description: "List Network Slice status"},
	{Text: "help", Description: "Command Detail"},
	{Text: "exit", Description: "Exit free5gc-nssmf-cli"},
}

var sliceSuggestions = []prompt.Suggest{}

var emptySuggestions = []prompt.Suggest{}

var deployedSliceSuggestions = []prompt.Suggest{}

func list_reload() {
	sliceSuggestions = []prompt.Suggest{}
	input_cmd := "cd network-slice && ls | grep 0x"
	out, err := exec.Command("/bin/sh", "-c", input_cmd).Output()
    if string(out) == "" {
        return
	}
	slices := strings.Split(string(out), "\n")
	for i := 0; i < len(slices)-1; i++ {
		slice := slices[i]
		sst := slice[2:4]
		sd := slice[4:]
		des := "sst: " + sst + ", sd: " + sd
		//fmt.Println(des)
		sliceSuggestions = append(sliceSuggestions, prompt.Suggest{Text: slices[i], Description: des})
	}
	if err != nil {
		fmt.Printf("Got error: %s\n", err.Error())
	}
}

func deployed_slice_reload() {
	deployedSliceSuggestions = []prompt.Suggest{}
	input_cmd := "shell-script/slice-deployed.sh"
	out, err := exec.Command("/bin/sh", "-c", input_cmd).Output()
	slices := strings.Split(string(out), " ")
	if slices[0] == "\n" {
		return
	}
	for i := 0; i < len(slices); i++ {
		slice := slices[i]
		sst := slice[2:4]
		sd := slice[4:]
		des := "sst: " + sst + ", sd: " + sd
		//fmt.Println(des)
		deployedSliceSuggestions = append(deployedSliceSuggestions, prompt.Suggest{Text: slices[i], Description: des})
	}
	if err != nil {
		fmt.Printf("Got error: %s\n", err.Error())
	}
}

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
		if len(blocks) != 5 {
            fmt.Printf("Input format: create 0x{sst}{sd} gnb_ip gnb_n3_ip ngci")
			return
		}
        arg := blocks[1] + " " + blocks[2] + " " + blocks[3] + " " + blocks[4]
		slice_cmd := "shell-script/slice-create.sh " + arg
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
	case "remove":
		if len(blocks) == 1 {
			return
		}
		slice_cmd := "shell-script/slice-recycle.sh " + blocks[1]
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
		input_cmd := "cd network-slice && ls | grep 0x"
		out, err := exec.Command("/bin/sh", "-c", input_cmd).Output()
                if string(out) == "" {
                        return
                }
		slices := strings.Split(string(out), "\n")
		for i := 0; i < len(slices)-1; i++ {
			slice := slices[i]
			sst := slice[2:4]
			sd := slice[4:]
			des := "sst: " + sst + ", sd: " + sd
			fmt.Println(des)
			//applySuggestions = append(applySuggestions, prompt.Suggest{Text: slices[i], Description: des})
		}

		//fmt.Printf(test[1])
		if err != nil {
			fmt.Printf("Got error: %s\n", err.Error())
		}
		return
	case "apply":
		if len(blocks) == 1 {
			return
		}
		slice_cmd := "shell-script/slice-apply.sh " + blocks[1]
		input_cmd := slice_cmd
		cmd := exec.Command("/bin/sh", "-c", input_cmd)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			fmt.Printf("Got error: %s\n", err.Error())
		}
		deployed_slice_reload()
		return
	case "delete":
		if len(blocks) == 1 {
			return
		}
		slice_cmd := "shell-script/slice-delete.sh " + blocks[1]
		input_cmd := slice_cmd
		cmd := exec.Command("/bin/sh", "-c", input_cmd)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			fmt.Printf("Got error: %s\n", err.Error())
		}
		deployed_slice_reload()
		return
	case "info":
		slice_cmd := "shell-script/slice-info.sh "
		input_cmd := slice_cmd
		cmd := exec.Command("/bin/sh", "-c", input_cmd)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			fmt.Printf("Got error: %s\n", err.Error())
		}
		return
	case "status":
		slice_cmd := "shell-script/slice-status.sh "
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
		deployed_slice_reload()
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
		if v == "apply" || v == "remove" {
			return prompt.FilterHasPrefix(sliceSuggestions, w, true)
		}
		if v == "create" || v == "info" || v == "list" || v == "help" || v == "exit" {
			return prompt.FilterHasPrefix(emptySuggestions, w, true)
		}
		if v == "delete" {
			return prompt.FilterContains(deployedSliceSuggestions, w, true)
		}
	}
	//if w == "" {
	//	return []prompt.Suggest{}
	//}
	return prompt.FilterHasPrefix(suggestions, w, true)
}

func main() {

	list_reload()
	deployed_slice_reload()
	p := prompt.New(
		Executor,
		Completer,
		prompt.OptionPrefix("free5gc-nssmf-cli"+" >> "),
		prompt.OptionTitle("free5gc-nssmf-cli"),
	)
	p.Run()
}
