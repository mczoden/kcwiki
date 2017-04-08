local orig_data = require('wiki_orig_shipdata')
local string = {
  match = string.match,
  format = string.format,
  sub = string.sub,
  len = string.len
}
local math = {
  floor = math.floor,
}


local INIT = 1
local LV99 = 2


function error_msg (...)
  io.stderr:write(string.format(...))
end


function is_interger_number (n)
  return type(n) == 'number' and n == math.floor(n)
end


function is_normal_wiki_id (wiki_id)
  -- Normal wiki ID: 001, 002, ..., Mist01, Mist02...
  -- Else: 001a, 002a...
  return string.match(wiki_id, '^%d+$') or string.match(wiki_id, 'Mist%d+$')
end


function ship_type_id_to_string (ship_type_id)
  local tbl = {
    '海防舰',
    '驱逐舰',
    '轻巡洋舰',
    '重雷装巡洋舰',
    '重巡洋舰',
    '航空巡洋舰',
    '轻空母',
    '巡洋战舰',
    '战舰',
    '航空战舰',
    '正规空母',
    '超弩建战舰',
    '潜水舰',
    '潜水空母',
    '补给舰',
    '水上机母舰',
    '扬陆舰',
    '装甲空母',
    '工作舰',
    '潜水空母',
    '练习巡洋舰',
    '补给舰'
  }

  return tbl[ship_type_id]
end


function ship_speed_id_to_string (ship_speed_id)
  local tbl = {}

  tbl[0] = '陆上基地'
  tbl[5] = '低速'
  tbl[10] = '高速'

  return tbl[ship_speed_id]
end


function ship_range_id_to_string (ship_range_id)
  local tbl = {
    '短',
    '中',
    '长',
    '超长'
  }
  tbl[0] = '无'

  return tbl[ship_range_id]
end


function check_data_validity (wiki_id, init_or_lv99)
  local ship_data = orig_data.shipDataTb[wiki_id]
  io.stderr:write(string.format("%s %s\n", wiki_id, ship_data['中文名']))
  
  local string_data = {
    ['中文名'] = ship_data['中文名'],
    ['舰型'] = ship_data['级别'][1]
  }
  for key in pairs(string_data) do
    local value = string_data[key]
    if type(value) ~= 'string' or
        string.len(value) == 0 then
        io.stderr:write(string.format('非法的%s：%s\n', key, tostring(value)))
        io.stderr:write('必须是字符串\n')
      return
    end
  end

  local positive_interger_data = {
    ['舰番号'] = ship_data['级别'][2],
    ['耐久'] = ship_data['数据']['耐久'][init_or_lv99],
    ['燃料'] = ship_data['消耗']['燃料'],
    ['弹药'] = ship_data['消耗']['弹药'],
    ['舰种'] = ship_data['舰种']
  }
  for key in pairs(positive_interger_data) do
    local value = positive_interger_data[key]
      if not is_interger_number(value) or value <= 0 then 
      io.stderr:write(string.format('非法的%s：%s\n', key, tostring(value)))
      io.stderr:write('必须是正整数\n')
      return
    end
  end

  local natural_data = {
    ['火力'] = ship_data['数据']['火力'][init_or_lv99],
    ['雷装'] = ship_data['数据']['雷装'][init_or_lv99],
    ['对空'] = ship_data['数据']['对空'][init_or_lv99],
    ['对潜'] = ship_data['数据']['对潜'][init_or_lv99],
    ['索敌'] = ship_data['数据']['索敌'][init_or_lv99],
    ['运'] = ship_data['数据']['运'][init_or_lv99],
    ['装甲'] = ship_data['数据']['装甲'][init_or_lv99],
    ['回避'] = ship_data['数据']['回避'][init_or_lv99],
    ['速力'] = ship_data['数据']['速力'],
    ['射程'] = ship_data['数据']['射程']
  }
  for key in pairs(natural_data) do
    local value = natural_data[key]
    if not is_interger_number(value) or value < 0 then
      io.stderr:write(string.format('非法的%s：%s\n', key, tostring(value)))
      io.stderr:write('必须是自然数\n')
      return
    end
  end

  local enumeration_data = {
    ['舰种'] = {
      value = ship_data['舰种'],
      convert_handler = ship_type_id_to_string
    },
    ['速力'] = {
      value = ship_data['数据']['速力'],
      convert_handler = ship_speed_id_to_string
    },
    ['射程'] = {
      value = ship_data['数据']['射程'],
      convert_handler = ship_range_id_to_string
    }
  }
  for key in pairs(enumeration_data) do
    local item = enumeration_data[key]
    if not pcall(item.convert_handler, item.value) then
      io.stderr:write(string.format('%s使用了非法的枚举值：%d\n',
                                    key, item.value))
      return
    end
  end

  for _, v in ipairs(ship_data['装备']['搭载']) do
    if not is_interger_number(v) then
      io.stderr:write(string.format('使用了非法的搭载值：%s\n',
                                    tostring(value)))
      return
    end
  end
end


function get_single_interger_data (from)
  local msg = ''
  local v = nil
  local is_number = true
  local ret = ''

  is_number = true

  if type(from) == 'string' then
    v = tonumber(from)
    if v == nil then
      is_number = false
      msg = msg .. string.format('出现字符串：%s\n', from)
    else
      is_number = true
    end
  elseif type(from) == 'number' then
    is_number = true
  else -- from is not number or interger
    is_interger_number = false
    msg = msg .. string.format('可能是一个非法类型：%s', type(from))
  end

  if is_number then
    v = tonumber(from)

    if not is_interger_number(v) then
      msg = msg .. string.format('出现小数：%s\n', tostring(v))
    end

    if v < 0 then
      msg = msg .. string.format('出现负数：%s\n', tostring(v))
    end
  end

  return msg == '', tostring(from), msg
end


function fillin_init_lv99_data (to, from)
  local status1, status99 = true, true
  local msg1, msg99 = '', '' 

  status1, to[INIT], msg1 = get_single_interger_data(from[INIT])
  status99, to[LV99], msg99 = get_single_interger_data(from[LV99])

  return status1 and status99, msg1 .. msg99
end


function ship_data_parser (wiki_id, ship_data)
  local ship = {}
  local k = nil
  local v = nil

  ship.wiki_id = wiki_id

  v = ship_data['中文名']
  if type(v) ~= 'string' or string.len(v) == 0 then
    error_msg('[%s]\n', wiki_id)
    error_msg('非法的中文名：%s\n', tostring(v))
    error_msg('必须是字符串\n')
    return
  end
  ship.zh_name = v

  v = ship_data['级别'][1]
  if type(v) ~= 'string' or string.len(v) == 0 then
    error_msg('[%s %s]\n', wiki_id, ship.zh_name)
    error_msg('非法的级别名：%s\n', tostring(v))
    error_msg('必须是字符串\n')
    return
  end
  ship.class = v

  v = tonumber(ship_data['级别'][2])
  if not is_interger_number(v) or v < 0 then
    error_msg('[%s %s]\n', wiki_id, ship.zh_name)
    error_msg('非法的舰番号：%s\n', tostring(v))
    error_msg('必须是非负整数\n')
    return
  end
  if v > 0 then
    ship.class = ship.class .. tostring(v) .. '号'
  end

  ship.hp = {}
  ship.firepower = {}
  ship.armor = {}
  ship.torpedo = {}
  ship.evasion = {}
  ship.aa = {}
  ship.asw = {}
  ship.los = {}
  ship.luck = {}
  local t = {
    ['耐久'] = {
      to = ship.hp,
      from = ship_data['数据']['耐久']
    },
    ['火力'] = {
      to = ship.firepower,
      from = ship_data['数据']['火力']
    },
    ['装甲'] = {
      to = ship.armor,
      from = ship_data['数据']['装甲']
    },
    ['雷装'] = {
      to = ship.torpedo,
      from = ship_data['数据']['雷装']
    },
    ['回避'] = {
      to = ship.evasion,
      from = ship_data['数据']['回避']
    },
    ['对空'] = {
      to = ship.aa,
      from = ship_data['数据']['对空']
    },
    ['对潜'] = {
      to = ship.asw,
      from = ship_data['数据']['对潜']
    },
    ['索敌'] = {
      to = ship.los,
      from = ship_data['数据']['索敌']
    },
    ['运'] = {
      to = ship.luck,
      from = ship_data['数据']['运']
    }
  }
  for k, v in pairs(t) do
    local status, msg = fillin_init_lv99_data(v.to, v.from)
    if status == false then
      error_msg('[%s %s]\n%s\n%s', wiki_id, ship.zh_name, k, msg)
    end
  end

  status, ship.fuel, msg = get_single_interger_data(ship_data['消耗']['燃料'])
  if status == false then
    error_msg('[%s %s]\n%s\n%s', wiki_id, ship.zh_name, '燃料', msg)
  end
  status, ship.ammo, msg = get_single_interger_data(ship_data['消耗']['弹药'])
  if status == false then
    error_msg('[%s %s]\n%s\n%s', wiki_id, ship.zh_name, '弹药', msg)
  end

  local index = ship_data['舰种']
  ship.type = ship_type_id_to_string(tonumber(index))
  if ship.type == nil then
    error_msg('[%s %s]\n', wiki_id, ship.zh_name)
    error_msg('%s\n使用了非法的枚举值：%s\n', '舰种', tostring(index))
    ship.type = ''
  end

  index = ship_data['数据']['速力']
  ship.speed = ship_speed_id_to_string(tonumber(index))
  if ship.speed== nil then
    error_msg('[%s %s]\n', wiki_id, ship.zh_name)
    error_msg('%s\n使用了非法的枚举值：%s\n', '速力', tostring(index))
    ship.speed= ''
  end

  index = ship_data['数据']['射程']
  ship.range = ship_range_id_to_string(tonumber(index))
  if ship.range == nil then
    error_msg('[%s %s]\n', wiki_id, ship.zh_name)
    error_msg('%s\n使用了非法的枚举值：%s\n', '射程', tostring(index))
    ship.range = ''
  end

  ship.aircraft = 0
  local tmp = 0
  for _, v in ipairs(ship_data['装备']['搭载']) do
    status, tmp, msg = get_single_interger_data(v)
    if status == false then
      if tmp ~= '-1' then
        error_msg('[%s %s]\n', wiki_id, ship.zh_name)
        error_msg('搭载出现了非法值：%s\n', tostring(v))
      end
      tmp = '0'
    end
    ship.aircraft = ship.aircraft + tonumber(tmp)
  end
  ship.aircraft = tostring(ship.aircraft)

  return ship
end


function data_to_list (ship, init_or_lv99)
  local result = ''
  local item_suffix = is_normal_wiki_id(ship.wiki_id) and '' or '2'

  if is_normal_wiki_id(ship.wiki_id) then
    result = result .. '{{舰娘列表\n'
    result = result .. string.format('\t|编号 = %s\n', ship.wiki_id)
  end
  result = result .. string.format('\t|名字%s = %s\n',
                                   item_suffix, ship.zh_name)
  if is_normal_wiki_id(ship.wiki_id) then
    result = result .. string.format('\t|级别 = %s\n', ship.class)
    result = result .. string.format('\t|类型 = %s\n', ship.type)
  end

  result = result .. string.format('\t|火力%s = %s\n',
                                   item_suffix, ship.firepower[init_or_lv99])
  result = result .. string.format('\t|雷装%s = %s\n',
                                   item_suffix, ship.torpedo[init_or_lv99])
  result = result .. string.format('\t|对空%s = %s\n',
                                   item_suffix, ship.aa[init_or_lv99])
  result = result .. string.format('\t|对潜%s = %s\n',
                                   item_suffix, ship.asw[init_or_lv99])
  result = result .. string.format('\t|索敌%s = %s\n',
                                   item_suffix, ship.los[init_or_lv99])
  result = result .. string.format('\t|运%s = %s\n',
                                   item_suffix, ship.luck[init_or_lv99])
  result = result .. string.format('\t|耐久%s = %s\n',
                                   item_suffix, ship.hp[init_or_lv99])
  result = result .. string.format('\t|装甲%s = %s\n',
                                   item_suffix, ship.armor[init_or_lv99])
  result = result .. string.format('\t|回避%s = %s\n',
                                   item_suffix, ship.evasion[init_or_lv99])

  result = result .. string.format('\t|搭载%s = %s\n',
                                   item_suffix, ship.aircraft)
  result = result .. string.format('\t|速力%s = %s\n',
                                   item_suffix, ship.speed)
  result = result .. string.format('\t|射程%s = %s\n',
                                   item_suffix, ship.range)
  result = result .. string.format('\t|燃料%s = %s\n',
                                   item_suffix, ship.fuel)
  result = result .. string.format('\t|弹药%s = %s\n',
                                   item_suffix, ship.ammo)
  local remark = init_or_lv99 == LV99 and 'Lv99' or ''
  result = result .. string.format('\t|备注%s = %s\n',
                                   item_suffix, remark)

  return (result .. '}}\n')
end


function main ()
  local wiki_id_list = {}
  local init_ship_list_string = ''
  local lv99_ship_list_string = ''
  local ship_data_table = orig_data.shipDataTb
  local ship = nil

  for id in pairs(ship_data_table) do
    table.insert(wiki_id_list, id)
  end

  table.sort(wiki_id_list)
  for _, wiki_id in ipairs(wiki_id_list) do
    if not is_normal_wiki_id(wiki_id) then
      --
      -- Kcwiki ID such as 001a.
      -- As the last ID is 001, need to delete '}}\n' in the end.
      init_ship_list_string = string.sub(init_ship_list_string, 1, -4) .. '\n'
      lv99_ship_list_string = string.sub(lv99_ship_list_string, 1, -4) .. '\n'
    end

    ship = ship_data_parser(wiki_id, orig_data.shipDataTb[wiki_id])
    init_ship_list_string = init_ship_list_string ..
                            data_to_list(ship, INIT)
    lv99_ship_list_string = lv99_ship_list_string ..
                            data_to_list(ship, LV99)
  end

  print('<!-- 如果您熟悉lua和python，可参考该脚本生成页面代码')
  print('https://github.com/mczoden/kcwiki')
  print('同时也欢迎您对脚本提出意见和建议，谢谢 -->\n')
  print('<tabber>初始数据={{舰娘列表/页首}}')
  print(init_ship_list_string)
  print('{{页尾|html}}')
  print('|-|满级数据={{舰娘列表/页首}}')
  print(lv99_ship_list_string)
  print('{{页尾|html}}')
  print('</tabber>')
  print('[[en:Ship list]]')
  print('[[ko:함선목록]]')
end

main()
