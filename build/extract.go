package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
)

type RepoInfo struct {
	StargazersCount int    `json:"stargazers_count"`
	Description     string `json:"description"`
}

func getRepoInfo(repo string, token string) (RepoInfo, error) {
	url := fmt.Sprintf("https://api.github.com/repos/%s", repo)
	fmt.Println(url)
	client := &http.Client{}
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return RepoInfo{}, err
	}

	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := client.Do(req)
	if err != nil {
		return RepoInfo{}, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return RepoInfo{}, fmt.Errorf("failed to fetch repo: %s, status: %s", repo, resp.Status)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return RepoInfo{}, err
	}

	var repoInfo RepoInfo
	err = json.Unmarshal(body, &repoInfo)
	if err != nil {
		return RepoInfo{}, err
	}

	return repoInfo, nil
}

func main() {

	token := os.Getenv("PAT")

	file, err := os.Open("data/repos")
	if err != nil {
		fmt.Println("Error opening file:", err)
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		fields := strings.Split(scanner.Text(), "/")
		owner := strings.TrimSpace(fields[3])
		repo := strings.TrimSpace(fields[4])
		if repo == "" || owner == "" {
			continue
		}
		info, err := getRepoInfo(fmt.Sprintf("%s/%s", owner, repo), token)
		if err != nil {
			fmt.Printf("Error fetching repo: %v\n", err)
			continue
		}

		fmt.Printf("%d,%s,%s\n", info.StargazersCount, repo, info.Description)
	}

	if err := scanner.Err(); err != nil {
		fmt.Println("Error reading file:", err)
	}
}
