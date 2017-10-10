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

-- Macro for restrict of function get_single_number_data
-- all number
local NUM_ALL = {
  positive = true,
  zero = true,
  negative = true
}
-- positive only
local NUM_POS = {
  positive = true
}
-- not negative
local NUM_NONEG= {
  positive = true,
  zero = true
}


local function error_msg (...)
  io.stderr:write(string.format(...))
end


local function is_interger_number (n)
  return type(n) == 'number' and n == math.floor(n)
end


local function is_no_remodel_wiki_id (wiki_id)
  -- Normal wiki ID: 001, 002, ..., Mist01, Mist02...
  -- Else: 001a, 002a...
  return string.match(wiki_id, '^%d%d%d$') or string.match(wiki_id, 'Mist%d+$')
end

local function is_wiki_id (wiki_id)
  print(wiki_id)
  return string.match(wiki_id, '^%d%d%da?$') or string.match(wiki_id, 'Mist%d+$')
end


local function ship_type_id_to_string (index)
  local t = {
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

  value = t[tonumber(index)]
  if value then
    return true, value, ''
  else
    return false, '', string.format('使用了非法的枚举值：%s\n',
                                    tostring(index))
  end
end


local function ship_speed_id_to_string (index)
  local t = {}

  t[0] = '陆上基地'
  t[5] = '低速'
  t[10] = '高速'

  value = t[tonumber(index)]
  if value then
    return true, value, ''
  else
    return false, '', string.format('使用了非法的枚举值：%s\n',
                                    tostring(index))
  end
end


local function ship_range_id_to_string (index)
  local t = {
    '短',
    '中',
    '长',
    '超长'
  }
  t[0] = '无'

  value = t[tonumber(index)]
  if value then
    return true, value, ''
  else
    return false, '', string.format('使用了非法的枚举值：%s\n',
                                    tostring(index))
  end
end


local function get_single_string_data (data)
  local msg = ''

  if type(data) ~= 'string' then
    msg = msg .. string.format('原始数据中定义了非字符串类型：%s\n',
                               type(data))
  end

  return msg == '', tostring(data), msg
end


local function get_single_number_data (data, restrict)
  local msg = ''
  local v = nil
  local is_number = true
  local ret = ''

  if type(restrict) ~= 'table' then
    restrict = NUM_ALL
  end

  local n = tonumber(data)
  if not n then
    return false, tostring(n), string.format('出现非数字：%s\n',
                                                 tostring(n))
  end

  if not is_interger_number(n) then
    return false, n, string.format('出现小数：%f\n', n)
  end

  if n < 0 and not restrict.negative then
    return false, n, string.format('出现负数：%d\n', n)
  end

  if n == 0 and not restrict.zero then
    return false, n, string.format('出现0\n')
  end

  if n > 0 and not restrict.positive then
    return false, n, string.format('出现正数：%d\n', n)
  end

  return true, n, ''
end


local function fillin_init_lv99_data (data, restrict)
  local status1, ret1, msg1 = get_single_number_data(data[INIT], restrict)
  local status99, ret99, msg99 = get_single_number_data(data[LV99], restrict)

  return status1 and status99, {ret1, ret99}, msg1 .. msg99
end


local function ship_data_parser (wiki_id, ship_data)
  local ship = {
    wiki_id = wiki_id
  }
  local st, ret, msg
  local prompt = string.format('[%s]\n', wiki_id)

  repeat
    st, ret, msg = get_single_string_data(ship_data['中文名'])
    if not st or ret == '' then
      prompt = prompt .. '非法中文名\n' .. msg
      break
    end
    ship.zh_name = ret

    prompt = string.format('[%s %s]\n', wiki_id, ret)

    local class = ''
    st, ret, msg = get_single_string_data(ship_data['级别'][1])
    if not st or ret == '' then
      prompt = prompt .. '非法的级别名\n' .. msg
      break
    end
    class = ret
    st, ret, msg = get_single_number_data(ship_data['级别'][2], NUM_NONEG)
    if not st then
      prompt = prompt .. '非法的舰番号\n' .. msg
      break
    end
    if ret > 0 then
      class = class .. tostring(ret) .. '号'
    end
    ship.class = class

    st, ret, msg = fillin_init_lv99_data(ship_data['数据']['耐久'], NUM_POS)
    if not st then
      prompt = prompt .. '耐久\n' .. msg
      break
    end
    ship.hp = ret

    st, ret, msg = fillin_init_lv99_data(ship_data['数据']['火力'], NUM_NONEG)
    if not st then
      prompt = prompt .. '火力\n' .. msg
      break
    end
    ship.firepower = ret

    st, ret, msg = fillin_init_lv99_data(ship_data['数据']['装甲'], NUM_NONEG)
    if not st then
      prompt = prompt .. '装甲\n' .. msg
      break
    end
    ship.armor = ret

    st, ret, msg = fillin_init_lv99_data(ship_data['数据']['雷装'], NUM_NONEG)
    if not st then
      prompt = prompt .. '雷装\n' .. msg
      break
    end
    ship.torpedo = ret

    st, ret, msg = fillin_init_lv99_data(ship_data['数据']['回避'], NUM_NONEG)
    if not st then
      prompt = prompt .. '回避\n' .. msg
      break
    end
    ship.evasion = ret

    st, ret, msg = fillin_init_lv99_data(ship_data['数据']['对空'], NUM_NONEG)
    if not st then
      prompt = prompt .. '对空\n' .. msg
      break
    end
    ship.aa = ret

    st, ret, msg = fillin_init_lv99_data(ship_data['数据']['对潜'], NUM_NONEG)
    if not st then
      prompt = prompt .. '对潜\n' .. msg
      break
    end
    ship.asw = ret

    st, ret, msg = fillin_init_lv99_data(ship_data['数据']['索敌'], NUM_NONEG)
    if not st then
      prompt = prompt .. '索敌\n' .. msg
      break
    end
    ship.los = ret

    st, ret, msg = fillin_init_lv99_data(ship_data['数据']['运'], NUM_NONEG)
    if not st then
      prompt = prompt .. '运\n' .. msg
      break
    end
    ship.luck = ret

    st, ret, msg = get_single_number_data(ship_data['消耗']['燃料'], NUM_POS)
    if not st then
      prompt = prompt .. '燃料\n' .. msg
      break
    end
    ship.fuel = ret

    st, ret, msg = get_single_number_data(ship_data['消耗']['弹药'], NUM_POS)
    if not st then
      prompt = prompt .. '弹药\n' .. msg
      break
    end
    ship.ammo = ret

    st, ret, msg = ship_type_id_to_string(ship_data['舰种'])
    if not st then
      prompt = prompt .. '舰种\n' .. msg
      break
    end
    ship.type = ret

    st, ret, msg = ship_speed_id_to_string(ship_data['数据']['速力'])
    if not st then
      prompt = prompt .. '速力\n' .. msg
      break
    end
    ship.speed = ret

    st, ret, msg = ship_range_id_to_string(ship_data['数据']['射程'])
    if not st then
      prompt = prompt .. '射程\n' .. msg
      break
    end
    ship.range = ret

    local has_error = false
    local aircraft = 0
    for _, v in ipairs(ship_data["装备"]["搭载"]) do
      st, ret, msg = get_single_number_data(v, NUM_NONEG)
      if not st and ret ~= -1 then
        prompt = prompt .. '搭载\n' .. msg
        has_error = true
        break
      end
      if ret == -1 then
        ret = 0
      end
      aircraft = aircraft + ret
    end
    if has_error then
      break
    end
    ship.aircraft = aircraft

    return ship
  until false -- repeat statement, to implement goto flow

  -- get here means has error
  error_msg(prompt)
  os.exit(-1)
end


local function data_to_list (ship, init_or_lv99)
  local result = ''
  local item_suffix = is_no_remodel_wiki_id(ship.wiki_id) and '' or '2'

  if is_no_remodel_wiki_id(ship.wiki_id) then
    result = result .. '{{舰娘列表\n'
    result = result .. string.format('\t|编号 = %s\n', ship.wiki_id)
  end
  result = result .. string.format('\t|名字%s = %s\n',
                                   item_suffix, ship.zh_name)
  if is_no_remodel_wiki_id(ship.wiki_id) then
    result = result .. string.format('\t|级别 = %s\n', ship.class)
    result = result .. string.format('\t|类型 = %s\n', ship.type)
  end

  result = result .. string.format('\t|火力%s = %d\n',
                                   item_suffix, ship.firepower[init_or_lv99])
  result = result .. string.format('\t|雷装%s = %d\n',
                                   item_suffix, ship.torpedo[init_or_lv99])
  result = result .. string.format('\t|对空%s = %d\n',
                                   item_suffix, ship.aa[init_or_lv99])
  result = result .. string.format('\t|对潜%s = %d\n',
                                   item_suffix, ship.asw[init_or_lv99])
  result = result .. string.format('\t|索敌%s = %d\n',
                                   item_suffix, ship.los[init_or_lv99])
  result = result .. string.format('\t|运%s = %d\n',
                                   item_suffix, ship.luck[init_or_lv99])
  result = result .. string.format('\t|耐久%s = %d\n',
                                   item_suffix, ship.hp[init_or_lv99])
  result = result .. string.format('\t|装甲%s = %d\n',
                                   item_suffix, ship.armor[init_or_lv99])
  result = result .. string.format('\t|回避%s = %d\n',
                                   item_suffix, ship.evasion[init_or_lv99])

  result = result .. string.format('\t|搭载%s = %d\n',
                                   item_suffix, ship.aircraft)
  result = result .. string.format('\t|速力%s = %s\n',
                                   item_suffix, ship.speed)
  result = result .. string.format('\t|射程%s = %s\n',
                                   item_suffix, ship.range)
  result = result .. string.format('\t|燃料%s = %d\n',
                                   item_suffix, ship.fuel)
  result = result .. string.format('\t|弹药%s = %d\n',
                                   item_suffix, ship.ammo)
  local remark = init_or_lv99 == LV99 and 'Lv99' or ''
  result = result .. string.format('\t|备注%s = %s\n',
                                   item_suffix, remark)

  return (result .. '}}\n')
end


local function main ()
  local wiki_id_list = {}
  local init_ship_list_string = ''
  local lv99_ship_list_string = ''
  local ship_data_table = orig_data.shipDataTb
  local ship = nil

  for id in pairs(ship_data_table) do
    if is_wiki_id(id) then
      table.insert(wiki_id_list, id)
    end
  end

  table.sort(wiki_id_list)
  for _, wiki_id in ipairs(wiki_id_list) do
    if not is_no_remodel_wiki_id(wiki_id) then
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
