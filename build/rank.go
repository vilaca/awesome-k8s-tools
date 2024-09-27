package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	var concatenatedText string
	position := 1
	for scanner.Scan() {
		line := scanner.Text()
		items := strings.Fields(line)
		if len(items) < 7 {
			fmt.Fprintln(os.Stderr, "error: incorrect format.")
			os.Exit(1)
		}
		archived, _ := strconv.ParseBool(items[2])
		if archived {
			continue
		}
		stars, _ := strconv.Atoi(items[0])
		if stars < 2 {
			continue
		}
		forks, _ := strconv.Atoi(items[1])
		repo := items[4]
		desc := ""
		for i := 7; i < len(items); i++ {
			if desc != "" {
				desc += " "
			}
			desc += items[i]
		}
		concatenatedText += fmt.Sprintf("|%d|[**%s**](https://github.com/vilaca/%s)<br>%s|%d|%d|\n", position, repo, repo, desc, stars, forks)
		position += 1
	}
	if err := scanner.Err(); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
	fmt.Println("### Hi there 👋")
	fmt.Println("These are my most popular repositories ranked by the amount of stars awarded:<br>")
	fmt.Println("| |Repository|Stars|Forks|")
	fmt.Println("|:---:|:---|:---:|:---:|")
	fmt.Println(concatenatedText)
	now := time.Now()
	day := now.Day()
	month := now.Month()
	year := now.Year()
	date := fmt.Sprintf("%d/%s/%d", day, month, year)
	fmt.Printf("<sub>This list is compiled automatically using Go, Github Actions and the Github API and was last updated on %s.</sub>\n", date)
}
