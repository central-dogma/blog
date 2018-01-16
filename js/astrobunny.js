function getParameterByName(name, url)
{
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, " "));
}

function call_api(endpoint, path, method, body, success_func, fail_func)
{
	var store = new Persist.Store('bunnylabs_user_data');

	$.ajax({
		url: endpoint + path + "?api_key=" + store.get('api_key'),
		method: method,
		data: body

	}).done(function(thing) {

		if (success_func)
		{
			success_func(thing);
		}

	}).fail(function(thing) {
		
		if (fail_func)
		{
			fail_func(thing);
		}
	});
}

function api_get(endpoint, path, success_func, error_func)
{
	call_api(endpoint, path, "GET", null, success_func, error_func)
}

function api_post(endpoint, path, body, success_func, error_func)
{
	call_api(endpoint, path, "POST", body, success_func, error_func)
}

function api_patch(endpoint, path, body, success_func, error_func)
{
	call_api(endpoint, path, "PATCH", body, success_func, error_func)
}

function api_delete(endpoint, path, body, success_func, error_func)
{
	call_api(endpoint, path, "DELETE", body, success_func, error_func)
}

function set_api_key(domain, api_key)
{
	var store = new Persist.Store('bunnylabs_user_data', {
		about: 'BunnyLabs User Data Store',
		domain: domain
	});
	store.set('api_key', api_key);
}

function login(endpoint, domain, data, success_func)
{
	$.ajax({
		url: endpoint + "/sessions",
		method: "POST",
		data: { email: data.email, password: data.password }

	}).done(function(thing) {
		console.log("success");
		set_api_key(domain, thing.api_key);
		check_logged_in(endpoint);

		if (success_func)
		{
			success_func();
		}

	}).fail(function(thing) {

		display_alert("Failed to Log In", thing.responseJSON.error)
		console.log(thing);
		$('#failed').modal('show');
		check_logged_in(endpoint);
	});
}

function get_api_key()
{
	var store = new Persist.Store('bunnylabs_user_data');
	return store.get('api_key');
}

function logout(endpoint)
{
	var store = new Persist.Store('bunnylabs_user_data');
	$.ajax({
		url: endpoint + "/sessions/" + store.get('api_key'),
		method: "DELETE"
	})

	store.set('api_key', "");
	check_logged_in(endpoint);
}

function api_get_username(endpoint, success_func, fail_func)
{
	api_get(endpoint, "/self/username", 
		function(result)
		{
			return success_func(result.username);
		},

		function(error)
		{
			return fail_func(error.responseJSON);
		}
	);
}

function api_post_registration(endpoint, data, success_func, fail_func)
{
	api_post(endpoint, "/users", data,
		function(result)
		{
			return success_func();
		},

		function(error)
		{
			return fail_func(error.responseJSON);
		}
	);
}

function api_post_forgot(endpoint, data, success_func, fail_func)
{
	api_post(endpoint, "/users/forgot", data,
		function(result)
		{
			return success_func();
		},

		function(error)
		{
			return fail_func(error.responseJSON);
		}
	);
}

function api_post_reset(endpoint, data, success_func, fail_func)
{
	api_post(endpoint, "/users/resetpassword", data,
		function(result)
		{
			return success_func();
		},

		function(error)
		{
			return fail_func(error.responseJSON);
		}
	);
}

function api_change_password(endpoint, data, success_func, fail_func)
{
	api_patch(endpoint, "/users/password", data,
		function(result)
		{
			return success_func();
		},

		function(error)
		{
			return fail_func(error.responseJSON);
		}
	);
}

function api_post_validation(domain, endpoint, data, success_func, fail_func)
{
	api_post(endpoint, "/users/validate", data,
		function(result)
		{
			set_api_key(domain, result.api_key);
			return success_func(result);
		},

		function(error)
		{
			return fail_func(error.responseJSON);
		}
	);
}

function api_get_comments(endpoint, success_func, fail_func)
{
	api_post(endpoint, "/comments", data,
		function(result)
		{
			return success_func(result.result);
		},

		function(error)
		{
			return fail_func(error.responseJSON);
		}
	);
}

function api_get_comment_count(endpoint, signature, success_func, fail_func)
{
	api_get(endpoint, "/comments/" + signature + "/count",
		function(result)
		{
			if (success_func)
			{
				return success_func(result.count);
			}
		},

		function(error)
		{
			if (fail_func)
			{
				return fail_func(error.responseJSON);
			}
		}
	);
}

function api_get_is_admin(endpoint, success_func, fail_func)
{
	api_get(endpoint, "/admin/self",
		function(result)
		{
			if (success_func)
			{
				return success_func();
			}
		},

		function(error)
		{
			if (fail_func)
			{
				return fail_func();
			}
		}
	);
}

function check_logged_in(endpoint, success_func, fail_func)
{
	$('.preauthenticated_items').css('display', '');
	$('.unauthenticated_items').css('display', 'none');
	$('.authenticated_items').css('display', 'none');
	$('.admin_items').css('display', 'none');

	api_get_username(endpoint,
		function(username)
		{
			$('.preauthenticated_items').css('display', 'none');
			$('.unauthenticated_items').css('display', 'none');
			$('.authenticated_items').css('display', '');
			$('.var_username').text(username);
			console.log("logged in: " + username)

			api_get_is_admin(endpoint, 
				function()
				{
					console.log("isadmin")
					$('.admin_items').css('display', '');
				});

			if (success_func)
			{
				success_func();
			}
		},

		function(error)
		{
			$('.preauthenticated_items').css('display', 'none');
			$('.authenticated_items').css('display', 'none');
			$('.unauthenticated_items').css('display', '');
			$('.var_username').text("## please log in ##");
			console.log(error);

			if (fail_func)
			{
				fail_func();
			}
		}
	);
}


function display_alert(title, message)
{
	$('#page_modal_title').text(title);
	$('#page_modal_message').text(message);
	$('#page_modal').modal('show');
}

