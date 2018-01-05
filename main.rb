require 'uri'
require 'net/http'
require 'json'

class Main
  @git_lab_url='http://192.168.249.38/api/v4'
  @git_lab_group='/groups/150'
  @private_token='eEssGaZRwHvBbonfzQkb'
  @states=['opened', 'closed']
  @labels=['1 Private Beta', '2 Public Beta', '3 Low', '4 Awaiting priority', 'No Label']

  def self.get_method(uri)
    url = URI(uri)
    http = Net::HTTP.new(url.host, url.port)

    request = Net::HTTP::Get.new(url)
    request["private-token"] = @private_token

    http.request(request)
  end

  def self.get_open_close_rate
    create_file("open_close_rate")
    write_file("open_close_rate","event,date,project_id")

    issues = "/issues?per_page=100&page="
    sort = "&sort=asc"

    for i in 1..5
      response = get_method(@git_lab_url+@git_lab_group+issues+i.to_s+sort)
      res = JSON.parse(response.body)
      res.each do |line|
        state = line['state']
        created_at = line['created_at']
        project_id = line['project_id'].to_s

        write_file("open_close_rate","opened,"+created_at[0...10]+","+project_id)

        if state == "closed"
          updated_on = line['updated_at']
          write_file("open_close_rate","closed,"+updated_on[0...10]+","+project_id)
        end
      end
    end

  end

  def self.get_issue_by_state
    @states.each do |state|
      response = get_method(@git_lab_url + @git_lab_group + "/issues?state="+state)
      puts state + " issues: " + response['x-total']
    end
  end

  def self.get_group_open_issues_by_label
    create_file("group_open_issues_by_label")
    write_file("group_open_issues_by_label","label,open defects")

    @labels.each do |label|
      label.gsub! ' ', '%20'
      uri = @git_lab_url + @git_lab_group + "/issues?state=opened&labels="+label
      response = get_method(uri)

      if response
        label.gsub! '%20', ' '
        str = label + "," + response['x-total']
        write_file("group_open_issues_by_label",str)
      end
    end

  end

  def self.get_project_defects
    create_file("project_defects")
    response = get_method(@git_lab_url + @git_lab_group).body
    proj = JSON.parse(response)['projects']

    write_file("project_defects", "label,project,open,closed")

    @labels.each do |label|
      proj.each do |p|
        label.gsub! ' ', '%20'

        open_uri = @git_lab_url + "/projects/"+p['id'].to_s+"/issues?state=opened&labels="+label
        open_response = get_method(open_uri)

        closed_uri = @git_lab_url + "/projects/"+p['id'].to_s+"/issues?state=closed&labels="+label
        closed_response = get_method(closed_uri)

        label.gsub! '%20', ' '
        str = label + "," + p['name'].to_s+"," + open_response['x-total'] + "," + closed_response['x-total']

        write_file("project_defects", str)

      end
    end
  end

  def self.create_file(name)
    File.open("results/"+name+".txt","w+")
  end

  def self.write_file(name,value)
    File.open("results/"+name+".txt", "a+") do |line |
      line.puts value
    end
  end

  get_project_defects
  get_open_close_rate
end