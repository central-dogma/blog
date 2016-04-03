require "json"
require "active_support/core_ext/hash"
require "yaml"
require "fileutils"
require "reverse_markdown"

require 'active_support/core_ext/hash/conversions'

class Hash
  def to_xml(options = {})
    require 'xmlsimple'
    options.delete(:builder)
    options.delete(:skip_instruct)
    options.delete(:dasherize)
    options.delete(:skip_types)

    options[:Indent] = ' '*options.delete(:indent) unless options[:indent].nil?
    options[:RootName] = options.delete(:root)

    XmlSimple.xml_out(self, options)
  end

  class << self
    def from_xml(xml, disallowed_types = nil)
      require 'xmlsimple'
      XmlSimple.xml_in(xml, KeepRoot: true, SuppressEmpty: true, KeyToSymbol: false, ForceArray: false)
    end
  end
end


data = Hash.from_xml(File.read("pages.xml"))

#puts data.to_yaml

pages = data["rss"]["channel"]["item"]

page_hash = {}

pages.select {|x| x["status"]=="publish"}.each do |page|
	page_hash[ page["post_id"] ] = page
end

parents = {}

page_hash.each do |_,page|
	path = page["post_name"]

	if page["post_parent"] != "0"
		parents[page["post_parent"]] = page_hash[page["post_parent"]]["post_name"]
		path = page_hash[page["post_parent"]]["post_name"] + "/" + path
	end

	page["path"] = path
end

parents.each do |_,parent|
	FileUtils.mkdir_p "../pages/#{parent}"
end

page_hash.each do |_,page|

	#puts page["path"]
	content = page["encoded"]

	front_matter = {}
	front_matter["title"] = page["title"]
	front_matter["author"] = page["creator"].gsub("admin", "astrobunny")
	front_matter["imported"] = true
	front_matter["create_time"] = Time.parse(page["post_date"]).to_i

	content.gsub! /\[album id=[0-9]+\]/, ""
	content.gsub! /\[child-pages depth="[0-9]" title_li=""\]/, ""



	gallery_matcher = /\[nggallery id=(?<gallerynum>[0-9]+)\]/.match(page["encoded"])
	if gallery_matcher
		content = ""
		gallery_hash = {
			"3" => "hinagiku"
		}
		front_matter["gallery"]  = gallery_hash[ gallery_matcher[:gallerynum] ]
	end

	doc = front_matter.to_yaml.gsub("---\n", '')

	doc += "---\n"


	content = content.gsub(/src\="((https?:\/\/(www.)?astrobunny.net\/images\/)|(\.\.\/images\/))/, "src=\"wp-images/")

	if /\<pre/.match(content) == nil
		#content = content.gsub("\n", "<br />")
	end

	#doc += ReverseMarkdown.convert(content)
	doc += content

	File.write("../pages/#{page["path"]}.md", doc);

	#puts page["post_id"]
	#puts Time.parse(page["post_date"]).to_i
	#puts page["title"]
	#puts page["creator"]
end


Dir["*.xml"].each do |xml|
	data = Hash.from_xml(File.read(xml))

	posts = data["rss"]["channel"]["item"]
	posts.
	select {|x| x["status"]=="publish"}.
	select {|x| x["post_type"]=="post"}.
	each do |post|

		front_matter = {}
		front_matter["title"] = post["title"]
		front_matter["author"] = post["creator"].gsub("admin", "astrobunny")
		front_matter["imported"] = true
		front_matter["create_time"] = Time.parse(post["post_date"]).to_i

		if post["category"].is_a? Array
			front_matter["tags"] = []
			front_matter["category"] = ""

			post["category"].each do |cat|
				if cat["domain"] == "category"
					front_matter["category"] = cat["content"]
				else
					front_matter["tags"] << cat["content"].downcase
				end
			end
		else
			front_matter["category"] = post["category"]["content"]
			front_matter["tags"] = []
		end

		date_stamp = Time.parse(post["post_date"]).strftime("%Y-%m-%d")
		post_filename = "#{date_stamp}-#{post["post_name"]}.md"

		doc = front_matter.to_yaml.gsub("---\n", '')

		doc += "---\n"

		content = post["encoded"]

		if /\<pre/.match(content) == nil
			content = content.gsub("\n", "<br />")
		end

		#if post["title"] == "Kotomi post"
		#	puts content.inspect
		#end

		content = content.gsub(/src *\= *\"((https?:\/\/(www.)?astrobunny.net\/images\/)|(\.\.\/images\/))/i, "src=\"wp-images/")
		content = content.gsub(/src *\= *\"https?:\/\/(www.)?astrobunny.net\/wp-content\/uploads\//i, "src=\"wp-uploads/")

		content = content.gsub(/href *\= *\"((https?:\/\/(www.)?astrobunny.net\/images\/)|(\.\.\/images\/))/i, "href=\"/images/wp-images/")
		content = content.gsub(/href *\= *\"https?:\/\/(www.)?astrobunny.net\/wp-content\/uploads\//i, "href=\"/images/wp-uploads/")

		doc += ReverseMarkdown.convert(content)

		#puts post.to_yaml
		#puts post_filename
		File.write("../posts/#{post_filename}", doc);

	end

end