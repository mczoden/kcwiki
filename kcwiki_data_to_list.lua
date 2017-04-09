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


function ship_type_id_to_string (index)
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


function ship_speed_id_to_string (index)
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


function ship_range_id_to_string (index)
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


function get_single_string_data (data)
  local msg = ''

  if type(data) ~= 'string' then
    msg = msg .. string.format('原始数据中定义了非字符串类型：%s\n',
                               type(data))
  end

  return msg == '', tostring(data), msg
end


function get_single_number_data (data, restrict)
  local msg = ''
  local v = nil
  local is_number = true
  local ret = ''

  if type(restrict) ~= 'table' then
    restrict = {}
  end

  if type(data) == 'string' then
    v = tonumber(data)
    if v == nil then
      is_number = false
      msg = msg .. string.format('出现字符串：%s\n', data)
    else
      is_number = true
    end
  elseif type(data) == 'number' then
    is_number = true
  else -- data is not number or interger
    is_number = false
    msg = msg .. string.format('可能是一个非法类型：%s', type(data))
  end

  if is_number then
    v = tonumber(data)

    if not is_interger_number(v) and not result.allow_decimal then
      msg = msg .. string.format('出现小数：%s\n', tostring(v))
    end

    if v < 0 and then
      msg = msg .. string.format('出现负数：%s\n', tostring(v))
    end
  end

  return msg == '', tostring(data), msg
end


function fillin_init_lv99_data (data)
  local status1, ret1, msg1 = get_single_number_data(data[INIT])
  local status99, ret99, msg99 = get_single_number_data(data[LV99])

  return status1 and status99, {ret1, ret99}, msg1 .. msg99
end


function ship_data_parser (wiki_id, ship_data)
  local ship = {
    wiki_id = wiki_id
  }

  local t = {
    {
      key = 'zh_name',
      zh_key = '中文名',
      data = ship_data['中文名'],
      handler = function (data)
        local status, ret, msg = get_single_string_data(data)

        if status == false or ret == '' or ret == 'nil' then
          error_msg('[%s]\n', wiki_id)
          error_msg('非法中文名，程序退出\n')
          os.exit(-1)
        end

        return true, ret, ''
      end
    },
    {
      key = 'class',
      zh_key = '级别',
      data = ship_data['级别'],
      handler = function (data)
        local class = ''
        local status, ret, msg = get_single_string_data(data[1])

        if status == false or ret == '' or ret == 'nil' then
          error_msg('[%s %s]\n', wiki_id, ship.zh_name)
          error_msg('非法的级别名，程序退出\n')
          os.exit(-1)
        end
        class = ret

        status, ret, msg = get_single_number_data(data[2])
        if not is_interger_number(tonumber(ret)) or tonumber(ret) < 0 then
          error_msg('[%s %s]\n', wiki_id, ship.zh_name)
          error_msg('非法的舰番号：%s\n', tostring(ret))
          error_msg('程序退出\n')
          os.exit(-1)
        end
        if tonumber(ret) > 0 then
          class = class .. ret .. '号'
        end

        return true, class, ''
      end
    },
    {
      key = 'hp',
      zh_key = '耐久',
      data = ship_data['数据']['耐久'],
      handler = fillin_init_lv99_data
    },
    {
      key = 'firepower',
      zh_key = '火力',
      data = ship_data['数据']['火力'],
      handler = fillin_init_lv99_data
    },
    {
      key = 'armor',
      zh_key = '装甲',
      data = ship_data['数据']['装甲'],
      handler = fillin_init_lv99_data
    },
    {
      key = 'torpedo',
      zh_key = '雷装',
      data = ship_data['数据']['雷装'],
      handler = fillin_init_lv99_data
    },
    {
      key = 'evasion',
      zh_key = '回避',
      data = ship_data['数据']['回避'],
      handler = fillin_init_lv99_data
    },
    {
      key = 'aa',
      zh_key = '对空',
      data = ship_data['数据']['对空'],
      handler = fillin_init_lv99_data
    },
    {
      key = 'asw',
      zh_key = '对潜',
      data = ship_data['数据']['对潜'],
      handler = fillin_init_lv99_data
    },
    {
      key = 'los',
      zh_key = '索敌',
      data = ship_data['数据']['索敌'],
      handler = fillin_init_lv99_data
    },
    {
      key = 'luck',
      zh_key = '运',
      data = ship_data['数据']['运'],
      handler = fillin_init_lv99_data
    },
    {
      key = 'fuel',
      zh_key = '燃料',
      data = ship_data['消耗']['燃料'],
      handler = get_single_number_data
    },
    {
      key = 'ammo',
      zh_key = '燃料',
      data = ship_data['消耗']['弹药'],
      handler = get_single_number_data
    },
    {
      key = 'type',
      zh_key = '舰种',
      data = ship_data['舰种'],
      handler = ship_type_id_to_string
    },
    {
      key = 'speed',
      zh_key = '速力',
      data = ship_data['数据']['速力'],
      handler = ship_speed_id_to_string
    },
    {
      key = 'range',
      zh_key = '射程',
      data = ship_data['数据']['射程'],
      handler = ship_range_id_to_string
    },
    {
      key = 'aircraft',
      zh_key = '搭载',
      data = ship_data['装备']['搭载'],
      handler = function (data)
        local no_error = true 
        local total_msg = ''
        local aircraft = 0

        for _, v in ipairs(data) do
          local status, ret, msg = get_single_number_data(v)
          if status == false then
            if ret ~= '-1' then
              no_error = false
              total_msg = total_msg .. msg
            end
            ret = '0'
          end
          aircraft = aircraft + tonumber(ret)
        end

        return no_error, tostring(aircraft), total_msg
      end
    }
  }
  for i in ipairs(t) do
    local status, ret, msg = t[i].handler(t[i].data)
    if status == false then
      error_msg('[%s %s]\n%s\n%s', wiki_id, ship.zh_name, t[i].zh_key, msg)
    end
    ship[t[i].key] = ret
  end

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
