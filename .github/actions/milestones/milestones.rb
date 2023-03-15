#!/usr/bin/env ruby
# In dev run like: docker run --env GITHUB_TOKEN --env INTERVAL $(docker build -q -f Dockerfile .)
# Optionally set env var INTERVAL to "weekly" or "monthly", or it runs based on current date.

require "octokit"
require "active_support"
require "active_support/core_ext"

$client = Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])
$client.auto_paginate = true
REPO = "github/support-console-ops"

Time.zone = "Wellington"
$today = Date.current

$milestones = $client.milestones(REPO, {state: 'open'})

def weekly
  this_week = $today.cweek
  last_week = $today.prev_week.cweek

  $old_milestone = $milestones.select{ |m| m.title == "#{$today.year}-W%02d" % last_week }.first
  $new_milestone = $client.create_milestone(REPO, "#{$today.year}-W%02d" % this_week, {
    due_on: $today.end_of_week.strftime("%Y-%m-%dT07:00:00Z")
  })
end

def monthly
  last_month = ($today.prev_month).strftime("%B %Y")
  $old_milestone = $milestones.select{ |m| m.title == last_month }.first
  new_month = ($today).strftime("%B %Y")
  $new_milestone = $client.create_milestone(REPO, new_month.to_s, {
    due_on: $today.end_of_month.strftime("%Y-%m-%dT07:00:00Z")
  })
end

def update_issues
  issues = $client.issues(REPO, {milestone: $old_milestone.number})
  issues.each do |issue|
    $client.update_issue(REPO, issue.number, {milestone: $new_milestone.number})
  end
  $client.update_milestone(REPO, $old_milestone.number, {state: "closed"})
end

case ENV['INPUT_INTERVAL']
when "weekly"
  weekly
  update_issues
when "monthly"
  monthly
  update_issues
else
  if Time.current.wday == 1
    puts "Monday. Running weekly milestone task..."
    weekly
    update_issues
  end

  if Time.current.day == 1
    puts "First of month. Running monthly task..."
    monthly
    update_issues
  end
end



