
require "redcarpet"

class GlobalSettings

	def api_url
		ENV["ASTROBUNNY_API_URL"] || "http://localhost:3000"
	end
end

def button_link(title, icon_sym, dest)
	a class: "btn btn-block", href: "#{dest}" do
		icon icon_sym
		text " #{title}"
	end
end

def sidebar_widget(title, options={}, &block)
	h3 "#{title}"
	min_height = options[:min_height] || 100
	div class:"widget-content", style: "min-height: #{min_height}px;" do
		instance_eval(&block) if block
	end
end

def slug(title)
	title.downcase.gsub(/[^0-9a-zA-Z]+/, "-")
end

def post_index_page(posts, title, primary_page_path, page_path_prefix=primary_page_path, options={})

	count = 0
	slices = posts.each_slice(10).to_a
	slices.each do |post_set|

		path = "#{page_path_prefix}"
		root_path = path
		path += "/page-#{count}" if count > 0
		path = primary_page_path if count == 0

		current_count = count

		current_page_options = options.clone

		cache_has_expired = false
		if options[:post_is_expired_proc]
			post_set.each do |post_file|
				cache_has_expired |= options[:post_is_expired_proc].call(post_file)

				#if post_file.include? "kotomi-post"
				#	puts "EXPIRED: #{options[:post_is_expired_proc].call(post_file)}"
				#	puts "CACHE: #{cache_has_expired}"
				#end
			end
		end
		current_page_options[:cache_expired] = cache_has_expired

		blog_page "#{title}", path, current_page_options do

			post_set.each do |post_file|
				render_post_summary(post_file)
			end

			div class:"page-nav" do
				span class:"previous-entries" do
					a "Older Entries", href: "/#{root_path}/page-#{current_count + 1}"
				end if current_count < slices.length - 1

				span class:"next-entries" do
					a "Newer Entries", href: "/#{root_path}/page-#{current_count - 1}" if current_count != 1
					a "Newer Entries", href: "/#{primary_page_path}" if current_count == 1
				end if current_count > 0
			end
		end

		count += 1
	end
end

def render_post_summary(post_file)
	post_name = post_file.sub(/^posts\//, "").sub(/.md$/, "").sub("-","/").sub("-","/").sub("-","/")
	yml = YAML.load_file post_file
	excerpt = render(post_file).split(/(&lt;!--more--&gt;)|(<!--more-->)/)[0]
	has_more = render(post_file).split(/(&lt;!--more--&gt;)|(<!--more-->)/).length > 1
	post_summary(yml["title"], post_name, excerpt, yml["category"], nil, yml["author"], yml["tags"], has_more, yml["create_time"].to_i)
end

def calendar_widget(time, options={})

	request_css "css/calendar.css"
	sidebar_widget "Calendar" do
		div class: "calendar" do


			firstday = Time.new(time.year,time.month,1)
			lastday = Time.new(time.year,time.month + 1,1) - 24 if time.month < 12
			lastday = Time.new(time.year + 1,1,1) - 24 if time.month == 12
			first_day_of_week = firstday.wday % 7

			month_has_posts = false

			day_array = (1..first_day_of_week).map {|x| "&nbsp;"} + 
				(firstday.day..lastday.day).map do |x|
					daysig = "#{Time.new(time.year,time.month,x).strftime("%Y/%m/%d")}"
					if options[:days][daysig]
						month_has_posts = true
					end
					"#{x}"
				end

			day_array += (1..(7-day_array.length % 7)).map {|x| "&nbsp;"}

			if month_has_posts
				a time.strftime("%B %Y"), href: "#{time.strftime("/%Y/%m/")}"
			else
				text time.strftime("%B %Y")
			end

			div class: "month" do
				div class: "week-header" do
					"SMTWTFS".split("").each {|day| div day, class: "day" }
				end

				day_array.each_slice(7).each do |week|
					div class: "week" do
						week.each do |day|
							daysig = ""
							if day.to_i > 0
								daysig = "#{Time.new(time.year,time.month,day.to_i).strftime("%Y/%m/%d")}"
							end
							if options[:days][daysig]
								div class: "day" do 
									a day, href: "/#{daysig}"
								end
							else
								div day, class: "day"
							end
						end
					end
				end

			end

			div class: "month" do
				div class: "month-link" do
					a "« #{Time.new(time.year, options[:prev_month]).strftime("%B")}", class: "prev-month" if options[:prev_month]
					a "#{Time.new(time.year, options[:next_month]).strftime("%B")} »", class: "next-month" if options[:next_month]
				end
			end
		end
	end
end

def render_post(content, post_name, pic, author, tags, more, &block)

	div class:"post" do

		if pic
			p do
				image "#{pic}"
			end
		end

		text content
		br
		a "Continue reading »", href:"/#{post_name}" if more

		instance_eval(&block) if block
		
		p class:"submeta" do 
			text "written by "
			strong "#{author}"
			text " \\\\ "

			comma = false
			tags.each do |x|
				if comma 
					text ", "
				end
				a "#{x}", href: "/tags/#{slug(x)}"
				comma = true
			end

		end

	end
end

def post_title(title, post_name, signature, category, time_int)
	time = Time.at(time_int)
	div class:"postinfo" do

		div class:"date" do
			span "#{time.strftime("%b")}", class:"month"
			span "#{time.strftime("%d")}", class:"day"
		end

		div class:"postdata" do 
			div class:"title" do
				a href:"/#{post_name}" do 
					h2 "#{title}", style: "margin-bottom: 2px"
				end

				a "#{category}", class:"category", href: "/categories/#{slug(category)}"
				a "Write a comment", id:"#{slug(post_name)}_comment_count", class:"mini-add-comment", href:"/#{post_name}#comments"

				on_page_load <<-SCRIPT
					api_get_comment_count("#{GlobalSettings.new.api_url}", #{signature.inspect}, function(count)
					{
						if (count == 1)
						{
							$("##{slug(post_name)}_comment_count").text(count + " comment");
						}
						else if (count != 0)
						{
							$("##{slug(post_name)}_comment_count").text(count + " comments");
						}
					})

				SCRIPT
			end
		end
	end
end

def page_title(title)
	div class:"postinfo" do
		div class:"postdata" do 
			div class:"pagetitle" do
				h2 "#{title}", style: "margin-bottom: 2px"

				a "Add Comment", class:"mini-add-comment", href:"#comments"
			end
		end
	end
end


def render(md_file)

	meta = YAML.load_file(md_file)
	renderer = Redcarpet::Render::HTML.new()
	markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true)
	content = File.read(md_file).split("---", 2)[1]

	page_title = CGI::escape_html meta["title"]

	rendered = markdown.render(content)

	# remove unwanted spacing
	rendered.gsub!(/<p> *&nbsp; *<\/p>/, "")

	# make images responsive
	rendered.gsub!(/<img src="(.+?)"/, '<img class="img-responsive" src="/images/\\1"')

	count = 0
	rendered.gsub!(/alt ?= ?"(.+?)"/) do
		count +=1
		"alt='Picture #{count} in [#{page_title}]'"
	end

	count = 0
	rendered.gsub!(/title ?= ?"(.+?)"/) do
		count +=1
		"title='Picture #{count} in [#{page_title}]'"
	end

	count = 0

	description_list = {}

	rendered.gsub!(/href="\/images/) do |match|
		count +=1

		substr = rendered[Regexp.last_match.offset(0)[1]..-1]
		subcontent_match = /<p>(?<content>.+?)<a/m.match(substr)

		if subcontent_match == nil or subcontent_match[:content].include?("/images/")
			subcontent_match = /<p>(?<content>.+?)<\/p>/m.match(substr) 
		end

		if subcontent_match == nil or subcontent_match[:content].include?("written by")
			subcontent_match = /<p>(?<content>.+?)<br/m.match(substr) 
		end

		if subcontent_match != nil and subcontent_match[:content].include?("img-responsive")
			subcontent_match = /<p>(?<content>.+?)<img class="img-respon/m.match(substr) 
		end

#		puts <<-ASD
#****************
##{substr}
#----------------
##{subcontent_match}
#****************
#		ASD

		subcontent = ""
		if subcontent_match
			subcontent = subcontent_match[:content]
			subcontent.gsub!("'",'&quot;')
			subcontent.gsub!("&lt;!--more--&gt;", "")
			subcontent.gsub!("<!--more-->", "")
		end

		sig = SecureRandom.hex 
		description_list[sig] = subcontent

		"class='picture_link' title='Picture #{count} in [#{page_title}]' data-description='#{sig}' data-gallery='' href=\"/images"

	end

	description_list.each do |num, desc|
		rendered.sub!("data-description='#{num}'", "data-description='#{desc}'")
	end
	
	rendered
end


def gen_comment_section(signature, title)

	signature = URI.escape(signature, /\W/)
	on_page_load <<-SCRIPT
refresh_comments();
	SCRIPT

	write_script_once <<-SCRIPT

var comment_count = 0;
function add_comment(comment_info)
{
	comment_count += 1;

	$("#commentstitle").text(comment_count + " comment" + (comment_count != 1 ? "s" : ""));

	content = "<li>"

	if (comment_count % 2 == 0)
	{
		content = "<li class='alt'>"
	}
	content += comment_count + ". "

	if (comment_info["url"] && comment_info["url"].length != 0)
	{
		content += '<cite><a href="' + comment_info["url"] + '">'
	}
	else
	{
		content += '<cite><a>'
	}

	content += comment_info["name"]
	content += "</a></cite>"

	content += " says:"
	content += "<br />"

	var date = new Date(0);
	date.setUTCSeconds(comment_info["time"]);

	content += "<small><a>"
	content += date
	content += "</a></small>"
	content += "<p>"
	content += comment_info["comment"];
	content += "</p>"
	content += "</li>"
	$("#post_comment_list").append(content);
}

function clear_comments()
{
	comment_count = 0;
	$("#post_comment_list").empty();
}

function send_comment(data)
{
	data.title = #{title.inspect};
	$.ajax({
		method: "POST",
		url: "#{GlobalSettings.new.api_url}/comments/#{signature}/as_guest.json",
		data: data
	})
	.done(function(msg) {
		refresh_comments();
		$("#comment_form")[0].reset();

	})
	.fail(function(err) {
		display_alert("Comment", err.responseJSON.error)
		console.log(err.responseJSON.error)
	});
}

function send_comment_authed(data)
{
	var store = new Persist.Store('bunnylabs_user_data');
	data.title = #{title.inspect};
	$.ajax({
		method: "POST",
		url: "#{GlobalSettings.new.api_url}/comments/#{signature}/as_user.json?api_key=" + store.get('api_key'),
		data: data
	})
	.done(function(msg) {
		refresh_comments();
		$("#comment_form")[0].reset();

	})
	.fail(function(err) {
		display_alert("Comment", err.responseJSON.error)
		console.log(err.responseJSON.error)
	});
}

function refresh_comments()
{
	$("#commentstitle").text("Loading comments...");
	$("#comment_form").hide();
	clear_comments()
	$.ajax({
		method: "GET",
		url: "#{GlobalSettings.new.api_url}/comments/#{signature}.json"
	})
	.done(function(msg) {

		$("#commentstitle").text("No comments");
		var i=0;
		for(i=0;i<msg.length;i++)
		{
			add_comment(msg[i]);
		}
		$("#comment_form").show();
	})
	.fail(function(error) {
		console.log("Failed to get comments");
		$("#commentstitle").text("Weird. Somehow the comments could not be loaded.");
		$("#comment_form").hide();
	});
}

	SCRIPT

	a name: "comments" do end
	h3 "No comments", id:"commentstitle"

	ol id: "post_comment_list", class: "commentlist" do
	end


	div class:"unauthenticated_items" do
		wform id:"comment_form" do
			h3 "Write a comment", id:"commentsrespond"
			small "Logging in allows you to edit/delete your comments"
			br
			br
			textfield "name", placeholder: "Name"
			textfield "url", placeholder: "Website"
			textfield "email", placeholder: "E-mail (will not be published)"
			textfield "comment", "Comment", rows: 5, autocomplete: "off", autocapitalize: "on"
			submit "Send Comment", style: "info" do
				script <<-SCRIPT
					send_comment(data)
				SCRIPT
			end
		end
	end

	div class:"authenticated_items" do
		wform id:"comment_form_authed" do
			h3 id:"commentsrespond" do
				text "Write a comment as "
				span "__", class: "var_username"
			end
			br
			textfield "comment", "Comment", rows: 5, autocomplete: "off", autocapitalize: "on"
			submit "Send Comment", style: "info" do
				script <<-SCRIPT
					send_comment_authed(data)
				SCRIPT
			end
		end
	end
end

def pipify(text)
	text.downcase.gsub(/[\/]/, "|")
end

def page_content(title, page_name, content, pic, author, tags, &block)
	page_title(title)

	render_post(content, "", pic, author, tags, false, &block)

	gen_comment_section("page:#{pipify(page_name)}", title)
end

def post_summary(title, post_name, excerpt, category, pic, author, tags, more, time_int)
	post_title(title, post_name, "post:#{pipify(post_name)}", category, time_int)
	render_post(excerpt, post_name, pic, author, tags, more)
end

def post_content(title, post_name, excerpt, category, pic, author, tags, time_int)
	post_title(title, post_name, "post:#{pipify(post_name)}", category, time_int)
	render_post(excerpt, post_name, pic, author, tags, false)

	gen_comment_section("post:#{pipify(post_name)}", title)
end

def standard_page(title, path="", options={}, &block)

	nonnav_page path, "#{title} - あstろぶんy’s　ぶぉg", cache_file: path.gsub("/", "__"), cache_expired: options[:cache_expired] do

		request_css "css/plugins/blueimp/css/blueimp-gallery.min.css"
		request_js "js/plugins/blueimp/jquery.blueimp-gallery.min.js"
		request_css "css/astrobunny.css"
		request_js "js/astrobunny.js"
		request_js "js/persist-all-min.js"

		background do
			div id: "blogbg" do

				div id: "blogbgtitle" do
					image "theme/main-bg.jpg", id: "blogbgimage"
				end
			end
		end

		top do

			modal "page_modal" do
				header do 
					h4 "MSG_PAGE_MODAL_TITLE", id: "page_modal_title"
				end

				body do
					p "MSG_PAGE_MODAL_MESSAGE", id: "page_modal_message"
				end
			end

			div class: "container" do

				row do
					col 12 do
						form id:"searchform" do 
							input type: "text", id: "searchtext"
							input type: "submit", id: "searchsubmit"
						end
					end
				end
			end
		end

		row do
			col 12 do
				div id: "blogtitlespace" do
				end
			end
		end

		instance_eval(&block)
	end
end

def admin_page(page_title, path, &block) 

	single_page(page_title, path) do

		on_page_load <<-SCRIPT

			$('.preauthenticated_items').css('display', '');
			$('.unauthenticated_items').css('display', 'none');
			$('.authenticated_items').css('display', 'none');
			$('.admin_items').css('display', 'none');
			api_get_is_admin("#{GlobalSettings.new.api_url}", 
				function()
				{
					console.log("isadmin")
					$('.preauthenticated_items').css('display', 'none');
					$('.unauthenticated_items').css('display', 'none');
					$('.authenticated_items').css('display', '');
					$('.admin_items').css('display', '');
				},
				function()
				{
					$('.preauthenticated_items').css('display', 'none');
					$('.unauthenticated_items').css('display', '');
					location.href = "/";
				});

		SCRIPT

		div class:"preauthenticated_items" do
			p "Loading..."
		end

		div class:"unauthenticated_items" do
			icon :"minus-circle"
		end

		div class:"admin_items" do
			instance_eval(&block)
		end
	end

end

def authed_single_page(page_title, path, &block) 

	single_page(page_title, path) do

		on_page_load <<-SCRIPT
			check_logged_in("#{GlobalSettings.new.api_url}",
				function()
				{

				},
				function()
				{
					location.href = "/user/login";
				}
			);
		SCRIPT

		div class:"preauthenticated_items" do
			p "Checking if you are logged in..."
		end

		div class:"unauthenticated_items" do
			p "You are not logged in. Please log in", style: "font-color: red;"
		end

		div class:"authenticated_items" do
			instance_eval(&block)
		end
	end

end

def single_page(page_title, path, &block)

	standard_page "#{page_title}", "#{path}", cache_expired: true do

		row do
			col 2, md: 1, sm: 0, xs: 0 do
			end

			col 8, md: 10, sm: 12, xs: 12 do
				div do 
					div id: "blognav" do
						ul do
							li menuitem_options do
								a "Home", href: "/"
							end
						end
					end

					ibox do 
						title "#{page_title}"

						instance_eval(&block)
					end
				end
			end

			col 2, md: 1, sm: 0, xs: 0 do
			end
		end

	end
end

def blog_page(title, path="", options={}, &block)

	standard_page(title, path, options) do

		row do
			col 3, xs: 0 do
				div class:"blogsidebar" do

					sidebar_widget "User Panel", min_height: 260 do

						div class: "authenticated_items", id: "userform", style: "display: none" do
							p id: "userform_welcome" do 
								text "Welcome back, "
								span "__", class: "var_username"
							end
							button_link "View Profile", :user, "/user/profile"
							button_link "View Comments", :comments, "/user/comments"
							div class: "admin_items" do
								button_link "Administration Panel", :university, "/admin"
							end
							br
							block_button :"sign-out", "Log out", style: :warning do
								script <<-SCRIPT
									logout("#{GlobalSettings.new.api_url}");
								SCRIPT
							end
						end

						div class: "unauthenticated_items", id: "loginform", style: "display: none" do
							wform do
								p "Login to edit your comments"
								textfield "email", placeholder: "E-mail"
								passwordfield "password", placeholder: "Password"

								submit :"sign-in", "Login", block: true, style: :info do
									script <<-SCRIPT
										login("#{GlobalSettings.new.api_url}", "localhost:4567",  data);
									SCRIPT
								end
								button_link " Register", :"user-plus", "/user/register"
								button_link " Forgot My Password", :"question", "/user/forgotpass"
							end
						end

						on_page_load <<-SCRIPT
							check_logged_in("#{GlobalSettings.new.api_url}");
						SCRIPT

					end

					sidebar_widget "Archives" do
						ul do
							options[:months].each do |month,posts|
								time = Time.parse(month)
								li do 
									a "#{time.strftime("%B %Y")}", href: "/#{month}"
									text " (#{posts.length})"
								end
							end
						end
					end

				end
			end

			col 6, sm: 9, xs: 12 do
				div do 
					div id: "blognav" do

						pages = options[:pages] ||  [ {name: "Home", path: "/"} ]

						ul do
							pages.each do |page|

								menuitem_options = {}

								if page[:name] == title
									menuitem_options[:class] = "page_item current_page_item"
								end

								li menuitem_options do
									a "#{page[:name]}", href: "#{page[:path]}"
								end
							end
						end
					end

					div id: "blogcontent" do

						div id:"lightBoxGallery", class:"lightBoxGallery" do
							instance_eval(&block) if block
						end

						#a href:"#{images[index]}", title: "#{title}", :"data-gallery"=> "" do
						#	img src:"#{thumbnails[index]}", style: "margin: 5px;"
						#end

						div id:"blueimp-gallery", class:"blueimp-gallery" do
							div class:"slides" do end
							h3 class:"title" do end
							p class:"description" do end
							a "‹", class:"prev" 
							a "›", class:"next" 
							a "×", class:"close"
							a class:"play-pause" do end
							ol class:"indicator" do end
						end
					end

					write_script_once <<-SCRIPT					
$('#blueimp-gallery').on('slide', function (event, index, slide) {
    $(this).children('.description')
        .html($('#lightBoxGallery .picture_link').eq(index).data('description'));
});
					SCRIPT

					div id: "footer" do
						text "Copyright © 2007-2016 astrobunny.net"
					end
				end
			end

			col 3, sm: 0, xs: 0 do
				div class:"blogsidebar" do
					calendar_time = options[:calendar_time] || Time.now
					calendar_widget(calendar_time, days: options[:days])

					sidebar_widget "Tags" do
						tags = options[:tags]
						max = tags[0][:count]+1
						min = tags[49][:count]

						max_font_size = 24
						min_font_size = 7

						(0...50).
							map{|index| tags[index]}.
							sort_by{|t| t[:tag]}.
							each do |tag_count|
								size = (tag_count[:count]*1.0 - min*1.0) / (max*1.0 - min*1.0) * (max_font_size - min_font_size) + min_font_size
								a tag_count[:tag], style: "font-size: #{size}pt", href: "/tags/#{slug(tag_count[:tag])}"
								text " "
							end
					end

					sidebar_widget "Categories" do
						ul do
							options[:categories].
								map{|cat_name,posts| {name:cat_name, posts: posts}}.
								sort_by{|x| x[:name]}.
								each do |cat|
									li do 
										a "#{cat[:name]}", href: "/categories/#{slug(cat[:name])}"
										text " (#{cat[:posts].length})"
									end
								end
						end
					end
				end
			end
		end
	end
end


