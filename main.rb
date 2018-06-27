require 'uri'
require 'net/http'
require 'json'

class Main
  @git_lab_url='http://192.168.249.38/api/v4'
  @git_lab_group='/groups/150'
  @private_token='eEssGaZRwHvBbonfzQkb'
  @states=['opened', 'closed']
  @labels=['0 Urgent','1 High', '2 Medium', '3 Low', '4 Awaiting priority', 'No Label']
  @projects = Hash.new

  def self.get_method(uri)
    #get call to the speified uri, using the private token in the header
    url = URI(uri)
    http = Net::HTTP.new(url.host, url.port)

    request = Net::HTTP::Get.new(url)
    request["private-token"] = @private_token

    http.request(request)
  end

  def self.get_defect_data
    #create a results file
    create_file("data")
    #write heading lines
    header="id,project,label,state,created_at,closed_on"
    write_file("data", header)

    issues = "/issues?per_page=100&page="

    #5 is the hardcoded number of pages... we could make this more dynamic
    @labels.each do |label|
      for i in 1..5
        #get the pages of results, and write out their created on date
        label.gsub! ' ', '%20'
        response = get_method(@git_lab_url+@git_lab_group+issues+i.to_s+"&labels="+label)
        res = JSON.parse(response.body)
        res.each do |line|
          id = line['id'].to_s
          p_id = line['project_id']
          p_name = @projects[p_id].to_s
          state = line['state'].to_s
          created_at = line['created_at'].to_s
          if state == "closed"
            closed_on = line['updated_at'].to_s
          else
            closed_on = ''
          end
          label.gsub! '%20', ' '
          #[0...10] truncates the string to be just the date
          str = id+","+p_name+","+label+","+state+","+created_at[0...10]+","+closed_on[0...10]
          write_file("data", str)
        end
      end
    end

  end

  def self.get_accessibility_defects
    label = 'Accessibility'
    #create a results file
    create_file("accessibility")
    #write heading lines
    header="id,project,label,state,created_at,closed_on"
    write_file("accessibility", header)

    issues = "/issues?per_page=100&page="

    #5 is the hardcoded number of pages... we could make this more dynamic
      for i in 1..5
        #get the pages of results, and write out their created on date
        response = get_method(@git_lab_url+@git_lab_group+issues+i.to_s+"&labels="+label)
        res = JSON.parse(response.body)
        res.each do |line|
          id = line['id'].to_s
          p_id = line['project_id']
          p_name = @projects[p_id].to_s
          state = line['state'].to_s
          created_at = line['created_at'].to_s
          if state == "closed"
            closed_on = line['updated_at'].to_s
          else
            closed_on = ''
          end
          label.gsub! '%20', ' '
          #[0...10] truncates the string to be just the date
          str = id+","+p_name+","+label+","+state+","+created_at[0...10]+","+closed_on[0...10]
          write_file("accessibility", str)
        end
      end
  end

  def self.create_file(name)
    File.open("results/"+name+".txt", "w+")
  end

  def self.write_file(name, value)
    File.open("results/"+name+".txt", "a+") do |line|
      line.puts value
    end
  end

  def self.get_project_names
    response = get_method(@git_lab_url + @git_lab_group).body
    proj = JSON.parse(response)['projects']

    proj.each do |p|
      @projects[p['id']] = p['name']
    end
  end

  def self.get_count_of_scenarios
    result = `grep -R "^[^#]*Scenario" ../../llc/beta/dev-env/apps/acceptance-tests/ | wc -l`
    puts "Acceptance Test Scenarios: " + result
  end

  get_project_names
  get_defect_data
  get_accessibility_defects
  # get_count_of_scenarios

end