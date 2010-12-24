require 'rubygems'
require 'mechanize'
require 'hpricot'
require 'logger'
require 'date'


mechanize = Mechanize.new { |a| a.log = Logger.new("mech.log")}
doc = Nokogiri::XML(mechanize.get("https://expedia-1.itransition.corp/code/cru/rssReviewFilter?moderator=a.shestakov&state=Review&orRoles=false&complete=true&filter=custom&FEAUTH=a.shestakov:658:96d60ce723ca1702d187d99ab1b2eb17").body)

result = "||Author||Items||Time||\n" + doc.xpath("//item").map {|item|
  {:author => item.xpath("author").text,
   :title => item.xpath("title").text,
   :link => item.xpath("link").text,
   :date => item.xpath("pubDate").text}
}.group_by {|item|
  item[:author]
}.sort {|entry1, entry2|
  entry2[1].length <=> entry1[1].length
}.map {|author, items|
  items = items.sort_by {|item| -1 * (Date.today - Date.parse(item[:date])).to_i}
  "|#{author}|" + items.inject("") {|s, item| s + "[#{item[:title]}|#{item[:link]}]\n"}[0..-2] + "|" + items.inject("") {|s, item| s + "#{(Date.today - Date.parse(item[:date])).to_i.to_s} days\n"}[0..-2] + "|\n"
}.join

mechanize.get('https://expedia-1.itransition.corp/wiki/').form_with(:name => "loginform") do |login_form|
  login_form.os_username = ARGV[0]
  login_form.os_password = ARGV[1]
end.submit

mechanize.get("https://expedia-1.itransition.corp/wiki/pages/editpage.action?pageId=8225692").form_with(:name => "editpageform") do |edit_form|
  edit_form.content = result
end.submit

