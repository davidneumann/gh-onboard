#!/bin/bash

# This script will
# * Repos
#   - Get the 10 most recent repos
#   - Get the 10 repos with most issues
# * For each repo
#   - Get the 3 latest issues
#   - Get the 3 issues (open or closed) with most messages
#   - Get the 3 latest PRs
#   - Get the 3 PRs with the most messages
#   - Get the 3 PRs with the most reviews

# You as the user can then
# * Review
#   - Take all 240ish urls and review them to learn how this org tracks bugs and implements changes.
#     Later versions of me can worry about how they use things like Jira.
#     Make sure you can contribute in the same form and function as established team members.
#   - Get top 4 PR contributors
#   - Get top 4 issue contributors
# * Bonus
#   - Clone those 20 repos and grep all their files to make a frequency count of all external modules

ORG_NAME=""
if [ $# -eq 1 ]; then
	ORG_NAME=$1
else
	echo "Running with your user account. Pass in an org name as the first argument to run for that org."
fi

# Create the output directory it does not exist
rm -rf output
mkdir -p output
rm -rf ./tmp/
mkdir -p ./tmp/

# Get all respos with details we care about
echo "Getting repo list for $ORG_NAME"
gh repo list --json name,description,updatedAt,url $ORG_NAME >output/repos.json

echo -e "\nGetting top 10 repos by last updated"
mlr --json sort -r updatedAt output/repos.json | mlr --json head -n 10 | jq '.[].url' -r >tmp/top10repos.txt

# Use jq to iterate over every url in output/respos.json and get their issue count
#gh issue list -R url --json number | jq '.[0].number'
echo -e "\nGetting top 10 repos by issue count"
rm -f output/issue_counts.txt
for url in $(jq -r '.[].url' output/repos.json); do
	# Remove output/issue_counts.txt if it exists
	count=$(gh issue list -R $url --json number | jq '.[0].number')
	re='^[+-]?[0-9]+([.][0-9]+)?$'
	if [[ $count =~ $re ]]; then
		echo "$url $count"
		echo "$url $count" >>output/issue_counts.txt
	else
		echo "$url 0"
	fi
done
sort -k 2r output/issue_counts.txt | head -n 10 | cut -d' ' -f1 >tmp/top10issues.txt
rm -f output/issue_counts.txt

echo -e "\nGetting top 10 repos by PR count"
rm -f output/pr_counts.txt
for url in $(jq -r '.[].url' output/repos.json); do
	# Remove output/issue_counts.txt if it exists
	count=$(gh pr list -R $url --json number -s all | jq '.[0].number')
	re='^[+-]?[0-9]+([.][0-9]+)?$'
	if [[ $count =~ $re ]]; then
		echo "$url $count"
		echo "$url $count" >>output/pr_counts.txt
	else
		echo "$url 0"
	fi
done
sort -k 2r output/pr_counts.txt | head -n 10 | cut -d' ' -f1 >tmp/top10prs.txt
rm -f output/pr_counts.txt

# For each url in output/top10repos.json and otuput/top10issues.txt
# Combine the two sources of urls
cat tmp/top10repos.txt tmp/top10issues.txt tmp/top10prs.txt | sort | uniq >output/top30repos.txt
count=0
for url in $(cat output/top30repos.txt); do
	# Get the 3 latest issues
	# Get the 3 issues (open or closed) with most messages
	echo -e "\nGetting issues for $url"
	rm -f tmp/orig.json
	rm -f tmp/issues.json
	rm -f tmp/top_3_issues.csv
	rm -f tmp/last_3_issues.csv
	gh issue list -R $url --json updatedAt,url,number,comments,title,body,author >tmp/orig.json
	mlr --json put '$commentCount = length($comments)' tmp/orig.json | mlr --json put -s fromUrl=$url '$repo=@fromUrl' | mlr --json cut -f comments,body -x >tmp/issues.json
	mlr --json sort -nr commentCount tmp/issues.json | mlr --json head -n 3 >tmp/top_3_issues.json
	mlr --json sort -r number tmp/issues.json | mlr --json head -n 3 >tmp/last_3_issues.json
	mlr --json cat tmp/top_3_issues.json tmp/last_3_issues.json | mlr --json uniq -a >tmp/issues_$count.json

	# Get the 3 latest PRs
	# Get the 3 PRs with the most messages
	echo "Getting closed PRs for $url"
	gh pr list -R $url -s closed --json updatedAt,url,title,state,reviews,comments,author,additions,closed,number >tmp/prs_orig.json
	mlr --json put '$reviewCount=length($reviews);$commentCount=length($comments)' then cut -f reviews,comments -x tmp/prs_orig.json >tmp/prs.json
	mlr --json sort -nr reviewCount tmp/prs.json | mlr --json head -n 3 >tmp/top_3_reviews_prs.json
	mlr --json sort -nr commentCount tmp/prs.json | mlr --json head -n 3 >tmp/top_3_comments_prs.json
	mlr --json sort -r number tmp/prs.json | mlr --json then head -n 3 >tmp/last_3_prs.json
	mlr --json cat tmp/top_3_reviews_prs.json tmp/top_3_comments_prs.json tmp/last_3_prs.json | mlr --json uniq -a >tmp/prs_$count.json

	count=$((count + 1))
done

echo -e "\nMaking final list of issues to reveiw in output/issues.csv"
mlr --j2c cat then put '$author_name=$author.name;$author_login=$author.login' then cut -f author -x then unsparsify then uniq -a tmp/issues_* >output/issues.csv

echo "Making final list of PRs to reveiw in output/prs.csv"
mlr --j2c cat then put '$author_name=$author.name;$author_login=$author.login' then cut -f author,reviews,comments -x then unsparsify then uniq -a tmp/prs_*.json >output/prs.csv

rm -rf ./tmp/
