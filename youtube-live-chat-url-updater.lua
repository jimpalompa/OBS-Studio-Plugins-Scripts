obs = obslua

j_channel_url = ""
j_delay_seconds = 30
j_source_name_1 = ""
j_source_name_2 = ""
j_source_name_3 = ""
j_source_name_4 = ""
j_source_name_5 = ""

function get_video_id()
  local handle = io.popen("curl -s "..j_channel_url)
  local stdout = handle:read("*a")
  result = string.match(stdout, "\"videoRenderer\":{\"videoId\":\"[^\"]+\"")
  if result == nil then
    result = string.match(stdout, "\"gridVideoRenderer\":{\"videoId\":\"[^\"]+\"")
  end
  if result ~= nil then
    result = string.match(result, ":\"[^\"]+\"")
    result = string.gsub(result, ":", "")
    result = string.gsub(result, "\"", "")
  end
  return result
end

function confirm_curl()
  local handle = io.popen("curl --version ")
  local result = handle:read("*a")
  if result == "" then
    print("Error: curl command is not found")
    return false
  end
  return true
end

function update_live_url()
  if j_channel_url == "" then
    print("Error: Channel URL is not set")
    return
  end

  video_id = get_video_id()
  if video_id == nil then
    if confirm_curl() then
      print("Error: Video ID was not found")
    end
    return
  end
  print(j_channel_url)
  print(video_id)

  source_name_list = {
    j_source_name_1,
    j_source_name_2,
    j_source_name_3,
    j_source_name_4,
    j_source_name_5
  }

  for i = 1, #source_name_list do
    source_name = source_name_list[i]
    if source_name ~= "" then
      source = obs.obs_get_source_by_name(source_name)
      if source ~= nil then
        settings = obs.obs_source_get_settings(source)
        obs.obs_data_set_string(settings, "url", "https://www.youtube.com/live_chat?v="..video_id)
        obs.obs_source_update(source, settings)
        obs.obs_source_release(source)
      end
    end
  end
end

function button(props, p)
  update_live_url()
  return false
end

function script_defaults(settings)
  obs.obs_data_set_default_string(settings, "channel_url", "https://www.youtube.com/@Example_Handle/streams")
  obs.obs_data_set_default_int(settings, "delay_seconds", 30)
  obs.obs_data_set_default_string(settings, "source_name_1", "Example source name")
end

function script_update(settings)
  j_channel_url = obs.obs_data_get_string(settings, "channel_url")
  j_delay_seconds = obs.obs_data_get_int(settings, "delay_seconds")
  j_delay_milliseconds = (obs.obs_data_get_int(settings, "delay_seconds") * 1000)
  j_source_name_1 = obs.obs_data_get_string(settings, "source_name_1")
  j_source_name_2 = obs.obs_data_get_string(settings, "source_name_2")
  j_source_name_3 = obs.obs_data_get_string(settings, "source_name_3")
  j_source_name_4 = obs.obs_data_get_string(settings, "source_name_4")
  j_source_name_5 = obs.obs_data_get_string(settings, "source_name_5")
end

function script_properties()
  local props = obs.obs_properties_create()
  obs.obs_properties_add_text(props, "channel_url", "Channel URL", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_int(props, "delay_seconds", "Update delay (s)", 0, 3600, 1)
  obs.obs_properties_add_text(props, "source_name_1", "Source 1", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_text(props, "source_name_2", "Source 2", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_text(props, "source_name_3", "Source 3", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_text(props, "source_name_4", "Source 4", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_text(props, "source_name_5", "Source 5", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_button(props, "button", "Update chat URL", button)
  return props
end

function on_event(event)
  if event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTING then
    print("Updating YouTube chat URLs in " .. j_delay_seconds .. " seconds..")
    obs.timer_add(load, j_delay_milliseconds)
  end
end

function load()
  print("Updating YouTube chat URLs")
  update_live_url()
  obs.remove_current_callback()
end

function script_load(settings)
  obs.obs_frontend_add_event_callback(on_event)
end
