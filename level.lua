import_prefix = ... and (...):match("(.-)[^%.]+$") or ""

require(import_prefix .. "class")

local levels = {}

local Level = class(function(self, initial_room, level_length, level_array)
	self.number_in_a_line = level_length
	self.datas = level_array
	self.room = initial_room
end)

local function initialize_levels()
	levels[1] = Level(28, 7, {[-6] = {},                                                                                                              [-5] = {},                                           [-4] = {},                                                        [-3] = {},                                           [-2] = {},                                                        [-1] = {},                                                         [0] = {},
	                          {exit = true, dir_exit = "left",            down = true,                               door = true, dir_door = "left"}, {                                     right = true}, {           down = true, left = true, right = true},              {                        left = true, right = true}, {                        left = true, right = true},              {                        left = true, right = true, sword = true}, {           down = true, left = true},
	                          {                                up = true,              right = true, monster = true},                                 {           down = true, left = true, right = true}, {up = true,              left = true, right = true},              {                        left = true},               {up = true, down = true},                                         {           down = true,              right = true},               {up = true,              left = true},
	                          {                                           down = true, right = true},                                                 {up = true,              left = true},               {},                                                               {           down = true,              right = true}, {up = true,              left = true},                            {up = true, down = true,              right = true},               {           down = true, left = true},
	                          {                                up = true,              right = true},                                                 {                        left = true, right = true}, {                        left = true, right = true, key = true},  {up = true,              left = true, right = true}, {                        left = true, right = true, trap = true}, {up = true,              left = true, right = true},               {up = true,              left = true},
	                          {},                                                                                                                     {},                                                  {},                                                               {},                                                  {},                                                               {},                                                                {}}
	)
	levels[2] = Level(23, 7, {[-6] = {},                                                                             [-5] = {},                                           [-4] = {},                                                          [-3] = {},                                                                                                                   [-2] = {},                                                                                             [-1] = {},                                                           [0] = {},
	                          {           right = true,                             door = true, dir_door = "down"}, {           down = true, left = true},               {           down = true,              right = true},                {exit = true, dir_exit = "up",                         left = true,                           door = true, dir_door = "up"}, {},                                                                                                    {           down = true,                            monster = true}, {},
	                          {up = true, right = true,                 key = true, door = true, dir_door = "up"},   {up = true, down = true, left = true, right = true}, {up = true,              left = true},                              {                                                                   right = true},                                           {           down = true, left = true, right = true, sword = true},                                     {up = true, down = true, left = true, right = true},                 {left = true, trap = true},
	                          {},                                                                                    {up = true, down = true,              right = true}, {                        left = true, right = true},                {                                         down = true, left = true, right = true, key = true},                               {up = true,              left = true, right = true},                                                   {up = true, down = true, left = true},                               {},
	                          {},                                                                                    {up = true, down = true,              right = true}, {                        left = true},                              {                              up = true,                           right = true},                                           {                        left = true, right = true},                                                   {up = true, down = true, left = true},                               {},
	                          {           right = true, monster = true},                                             {up = true,              left = true, right = true}, {                        left = true, right = true, redkey = true}, {                                                      left = true, right = true},                                           {up = true,              left = true,               sword = true, reddoor = true, dir_reddoor = "up"}, {up = true,                           right = true},                 {left = true, trap = true},
	                          {},                                                                                    {},                                                  {},                                                                 {},                                                                                                                          {},                                                                         {},                                                                                             {}}
	)
	levels[-1] = Level(4, 2, {[-1] = {},                                                                                                                                                                   [0] = {},
	                          {exit = true, dir_exit = "left",                 reddoor = true, dir_reddoor = "left", right = true, grave = true, deadlygrave = true, keyneeded = "key", exitdir = "down"}, {           down = true,             graveorig = true},
	                          {                                redkey = true},                                                                                                                             {up = true,              key = true},
	                          {},                                                                                                                                                                          {}}
	)
	levels[-2] = Level(4, 7, {[-1] = {},                                                                                              [0] = {},
	                          {exit = true, dir_exit = "left", reddoor = true, dir_reddoor = "left", door = true, dir_door = "left"}, {graveorig = true, down = true},
	                          {},                                                                                                     {up = true, key = true, redkey = true},
	                          {},                                                                                                     {}}
	)
end

function get_levels()
	return levels
end

function get_active_level()
	local levels = get_levels()
	return levels[2]
end

initialize_levels()
