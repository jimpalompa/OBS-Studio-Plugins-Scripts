obs = obslua

g_channel_url = ""
g_source_name1 = "" -- Alphabet only
g_source_name2 = ""
g_source_name3 = ""
g_source_name4 = ""
g_source_name5 = ""

function get_video_id()
  local handle = io.popen("curl -s "..g_channel_url)
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
  if g_channel_url == "" then
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
  print(g_channel_url)
  print(video_id)

  source_name_list = {
    g_source_name1,
    g_source_name2,
    g_source_name3,
    g_source_name4,
    g_source_name5
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

function script_update(settings)
  g_channel_url = obs.obs_data_get_string(settings, "channel_url")
  g_source_name1 = obs.obs_data_get_string(settings, "source_name1")
  g_source_name2 = obs.obs_data_get_string(settings, "source_name2")
  g_source_name3 = obs.obs_data_get_string(settings, "source_name3")
  g_source_name4 = obs.obs_data_get_string(settings, "source_name4")
  g_source_name5 = obs.obs_data_get_string(settings, "source_name5")
end

function script_properties()
  local props = obs.obs_properties_create()
  obs.obs_properties_add_text(props, "channel_url", "Channel URL", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_text(props, "source_name1", "Source 1", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_text(props, "source_name2", "Source 2", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_text(props, "source_name3", "Source 3", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_text(props, "source_name4", "Source 4", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_text(props, "source_name5", "Source 5", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_button(props, "button", "Update chat URL", button)
  return props
end

function load()
  print("Updating YouTube chat URLs")
  update_live_url()
  obs.remove_current_callback()
end

function on_event(event)
  if event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTING then
    print("Updating YouTube chat URLs in 60 seconds..")
    obs.timer_add(load, 60000)
  end
end

function script_load(settings)
  obs.obs_frontend_add_event_callback(on_event)
end
