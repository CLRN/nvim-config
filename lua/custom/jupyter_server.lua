local async = require "plenary.async"
local Job = require "plenary.job"
local curl = require "plenary.curl"
local Websocket = require("websocket").Websocket
local Opcodes = require "websocket.types.opcodes"

local host = "localhost"
local random = math.random

local function uuid()
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  return string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
    return string.format("%x", v)
  end)
end

local token = uuid()

local function create_kernel()
  -- start jupyter server
  local process_set, process_get = async.control.channel.oneshot()
  local server_process = Job:new {
    command = "/usr/local/bin/jupyter",
    args = { "notebook", "--no-browser" },
    -- cwd = "/usr/bin",
    env = { ["JUPYTER_TOKEN"] = token },
    on_stderr = function(err, line)
      local port = string.match(line, "http://localhost:([0-9]+)/")
      if port then
        process_set(port)
      else
        vim.notify(line, vim.log.levels.DEBUG)
      end
    end,
  }

  server_process:add_on_exit_callback(function(job, code, signal)
    vim.notify("Jupyter server finished with code " .. code .. " and signal " .. signal)
  end)
  server_process:start()

  vim.notify(string.format("Started jupyter server with pid %d", server_process.pid))

  local port = process_get()

  vim.notify("Jupyter server is running on port " .. port)

  local kernel_set, kernel_get = async.control.channel.oneshot()
  vim.schedule(function()
    local kernels_response = curl.request {
      url = string.format("http://%s:%d/api/kernels?token=%s", host, port, token),
      method = "post",
      accept = "application/json",
    }
    assert(kernels_response.status == 201)
    local body = vim.json.decode(kernels_response.body)
    kernel_set(body.id)
  end)

  local kernel_id = kernel_get()
  vim.notify("Kernel is ready, id: " .. kernel_id)

  return port, kernel_id, server_process
end

---@param args { on_kernel_status: function, on_error: function, on_cell_status: function, on_output: function }
local function start_jupyter(args)
  local port, kernel_id, kernel_process = create_kernel()
  local sock = Websocket:new {
    host = host,
    port = port,
    path = string.format("/api/kernels/%s/channels?token=%s", kernel_id, token),
  }

  local session = uuid()

  local function send(code)
    local msg_id = uuid()
    local hdr = {
      msg_id = msg_id,
      username = "neovim",
      session = session,
      msg_type = "execute_request",
      version = "5.0",
    }

    local msg = {
      header = hdr,
      parent_header = hdr,
      metadata = { cellId = uuid() },
      channel = "shell",
      content = { code = code, silent = false },
    }
    vim.schedule(function()
      sock:send_text(vim.json.encode(msg))
    end)

    return msg_id
  end

  sock:add_on_connect(function()
    vim.notify("Connected to jupyter channel on " .. host .. ":" .. port)
  end)

  sock:add_on_message(function(frame)
    vim.schedule(function()
      if frame.opcode == Opcodes.TEXT then
        local body = vim.json.decode(frame.payload)
        if body.msg_type == "status" then
          vim.notify("The kernel is " .. body.content.execution_state)
          args.on_kernel_status(body.content.execution_state)

          if body.content.execution_state == "idle" then
            -- TODO: check if queing is needed here or we can just send all requests and let them queue on the server
          end
        elseif body.msg_type == "error" then
          vim.notify("Error " .. table.concat(body.content.traceback, "\n"))
          args.on_error(body.parent_header.msg_id, body.content.traceback)
        elseif body.msg_type == "execute_reply" then
          vim.notify("The execution is finished with " .. body.content.status)
          args.on_cell_status(body.parent_header.msg_id, body.content.status)
        elseif body.msg_type == "stream" then
          vim.notify("Output to " .. body.content.name .. " is " .. body.content.text)
          args.on_output(body.parent_header.msg_id, body.content.text)
        elseif body.msg_type == "execute_input" then
          args.on_cell_status(body.parent_header.msg_id, "running")
          vim.notify "The execution has started"
        else
          vim.print(body)
        end
      end
    end)
  end)

  sock:connect()

  return {
    send = send,
    stop = function()
      kernel_process:shutdown(0, 9)
    end,
  }
end

return start_jupyter
