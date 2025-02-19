--- Rust language actions

local M = {}

-- Frontend  - options displayed on telescope
M.options = {
  { text = "1 - Build and run program", value = "option1" },
  { text = "2 - Build program", value = "option2" },
  { text = "3 - Run program", value = "option3" },
  { text = "4 - Build solution", value = "option4" },
  { text = "", value = "separator" },
  { text = "5 - Cargo build and run", value = "option5" },
  { text = "6 - Cargo build", value = "option6" },
  { text = "7 - Cargo run", value = "option7" },
  { text = "", value = "separator" },
  { text = "8 - Cargo build --all and run", value = "option8" },
  { text = "9 - Cargo build --all", value = "option9" },
  { text = "", value = "separator" },
  { text = "10 - Run Makefile", value = "option10" }
}

-- Backend - overseer tasks performed on option selected
function M.action(selected_option)
  local utils = require("compiler.utils")
  local overseer = require("overseer")
  local entry_point = utils.os_path(vim.fn.getcwd() .. "/main.rs")           -- working_directory/main.rs
  local output_dir = utils.os_path(vim.fn.getcwd() .. "/bin/")               -- working_directory/bin/
  local output = utils.os_path(vim.fn.getcwd() .. "/bin/program")            -- working_directory/bin/program
  local arguments = "-D warnings -g"                                         -- arguments can be overriden in .solution
  local final_message = "--task finished--"

  if selected_option == "option1" then
    local task = overseer.new_task({
      name = "- Rust compiler",
      strategy = { "orchestrator",
        tasks = {{ "shell", name = "- Build & run program → " .. entry_point,
          cmd = "rm -f " .. output ..  " || true" ..                                    -- clean
                " && mkdir -p " .. output_dir ..                                        -- mkdir
                " && rustc " .. entry_point .. " -o " .. output .. " " .. arguments ..  -- compile
                " && " .. output ..                                                     -- run
                " && echo " .. entry_point ..                                           -- echo
                " && echo '" .. final_message .. "'"
        },},},})
    task:start()
    vim.cmd("OverseerOpen")
  elseif selected_option == "option2" then
    local task = overseer.new_task({
      name = "- Rust compiler",
      strategy = { "orchestrator",
        tasks = {{ "shell", name = "- Build program → " .. entry_point,
          cmd = "rm -f " .. output ..  " || true" ..                                    -- clean
                " && mkdir -p " .. output_dir ..                                        -- mkdir
                " && rustc " .. entry_point .. " -o " .. output .. " " .. arguments ..  -- compile
                " && echo " .. entry_point ..                                           -- echo
                " && echo '" .. final_message .. "'"
        },},},})
    task:start()
    vim.cmd("OverseerOpen")
  elseif selected_option == "option3" then
    local task = overseer.new_task({
      name = "- Rust compiler",
      strategy = { "orchestrator",
        tasks = {{ "shell", name = "- Run program → " .. entry_point,
            cmd = output ..                                                  -- run
                " && echo " .. output ..                                     -- echo
                " && echo '" .. final_message .. "'"
        },},},})
    task:start()
    vim.cmd("OverseerOpen")
  elseif selected_option == "option4" then
    local entry_points
    local task = {}
    local tasks = {}
    local executables = {}

    -- if .solution file exists in working dir
    local solution_file = utils.get_solution_file()
    if solution_file then
      local config = utils.parse_solution_file(solution_file)

      for entry, variables in pairs(config) do
        if entry == "executables" then goto continue end
        entry_point = utils.os_path(variables.entry_point)
        output = utils.os_path(variables.output)
        output_dir = utils.os_path(output:match("^(.-[/\\])[^/\\]*$"))
        arguments = variables.arguments or arguments --roptional
        task = { "shell", name = "- Build program → " .. entry_point,
          cmd = "rm -f " .. output ..  " || true" ..                                    -- clean
                " && mkdir -p " .. output_dir ..                                        -- mkdir
                " && rustc " .. entry_point .. " -o " .. output .. " " .. arguments ..  -- compile
                " && echo " .. entry_point ..                                           -- echo
                " && echo '" .. final_message .. "'"
        }
        table.insert(tasks, task) -- store all the tasks we've created
        ::continue::
      end

      local solution_executables = config["executables"]
      if solution_executables then
        for entry, executable in pairs(solution_executables) do
          task = { "shell", name = "- Run program → " .. executable,
            cmd = executable ..                                                         -- run
                  " && echo " .. executable ..                                          -- echo
                  " && echo '" .. final_message .. "'"
          }
          table.insert(executables, task) -- store all the executables we've created
        end
      end

      task = overseer.new_task({
        name = "- Rust compiler", strategy = { "orchestrator",
          tasks = {
            tasks,        -- Build all the programs in the solution in parallel
            executables   -- Then run the solution executable(s)
          }}})
      task:start()
      vim.cmd("OverseerOpen")

    else -- If no .solution file
      -- Create a list of all entry point files in the working directory
      entry_points = utils.find_files(vim.fn.getcwd(), "main.rs")

      for _, entry_point in ipairs(entry_points) do
        entry_point = utils.os_path(entry_point)
        output_dir = utils.os_path(entry_point:match("^(.-[/\\])[^/\\]*$") .. "bin")      -- entry_point/bin
        output = utils.os_path(output_dir .. "/program")                                  -- entry_point/bin/program
        task = { "shell", name = "- Build program → " .. entry_point,
          cmd = "rm -f " .. output ..  " || true" ..                                     -- clean
                " && mkdir -p " .. output_dir ..                                         -- mkdir
                " && rustc " .. entry_point .. " -o " .. output .. " " .. arguments ..   -- compile
                " && echo " .. entry_point ..                                            -- echo
                " && echo '" .. final_message .. "'"
        }
        table.insert(tasks, task) -- store all the tasks we've created
      end

      task = overseer.new_task({ -- run all tasks we've created in parallel
        name = "- Rust compiler", strategy = { "orchestrator", tasks = tasks }
      })
      task:start()
      vim.cmd("OverseerOpen")
    end
  elseif selected_option == "option5" then
    local task = overseer.new_task({
      name = "- Rust compiler",
      strategy = { "orchestrator",
        tasks = {{ "shell", name = "- Cargo build & run → " .. "Cargo.toml",
          cmd = "cargo build " ..                                                       -- compile
                " && cargo run" ..                                                      --run
                " && echo '" .. final_message .. "'"                                    -- echo
        },},},})
    task:start()
    vim.cmd("OverseerOpen")
  elseif selected_option == "option6" then
    local task = overseer.new_task({
      name = "- Rust compiler",
      strategy = { "orchestrator",
        tasks = {{ "shell", name = "- Cargo build → " .. "Cargo.toml",
          cmd = "cargo build " ..                                                       -- compile
                " && echo '" .. final_message .. "'"                                    -- echo
        },},},})
    task:start()
    vim.cmd("OverseerOpen")
  elseif selected_option == "option7" then
    local task = overseer.new_task({
      name = "- Rust compiler",
      strategy = { "orchestrator",
        tasks = {{ "shell", name = "- Cargo run → " .. "Cargo.toml",
          cmd = "cargo run " ..                                                        -- run
                " && echo '" .. final_message .. "'"                                   -- echo
        },},},})
    task:start()
    vim.cmd("OverseerOpen")
  elseif selected_option == "option8" then
    local task = overseer.new_task({
      name = "- Rust compiler",
      strategy = { "orchestrator",
        tasks = {{ "shell", name = "- Cargo build --all & run → " .. "Cargo.toml",
          cmd = "cargo build --all " ..                                                -- compile
                " && cargo run" ..
                " && echo '" .. final_message .. "'"                                   -- echo
        },},},})
    task:start()
    vim.cmd("OverseerOpen")
  elseif selected_option == "option9" then
    local task = overseer.new_task({
      name = "- Rust compiler",
      strategy = { "orchestrator",
        tasks = {{ "shell", name = "- Cargo build --all → " .. "Cargo.toml",
          cmd = "cargo build --all" ..                                                 -- compile
                " && echo '" .. final_message .. "'"                                   -- echo
        },},},})
    task:start()
    vim.cmd("OverseerOpen")
  elseif selected_option == "option10" then
    require("compiler.languages.make").run_makefile()                        -- run
  end
end

return M

