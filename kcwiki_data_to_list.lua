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

  if tbl[ship_type_id] == nil then
    error('')
  else
    return tbl[ship_type_id]
  end
end


function ship_speed_id_to_string (ship_speed_id)
  local tbl = {}

  tbl[0] = '陆上基地'
  tbl[5] = '低速'
  tbl[10] = '高速'

  if tbl[ship_speed_id] == nil then
    error('')
  else
    return tbl[ship_speed_id]
  end
end


function ship_range_id_to_string (ship_range_id)
  local tbl = {
    '短',
    '中',
    '长',
    '超长'
  }
  tbl[0] = '无'

  if tbl[ship_range_id] == nil then
    error('')
  else
    return tbl[ship_range_id]
  end
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

function data_to_list (wiki_id, init_or_lv99)
  local ship_data = orig_data.shipDataTb[wiki_id]
  local result = ''
  local item_suffix = is_normal_wiki_id(wiki_id) and '' or '2'

  if is_normal_wiki_id(wiki_id) then
    result = result .. '{{舰娘列表\n'
    result = result .. string.format('\t|编号 = %s\n', wiki_id)
  end
  result = result .. string.format('\t|名字%s = %s\n',
                                   item_suffix, ship_data['中文名'])
  if is_normal_wiki_id(wiki_id) then
    result = result .. string.format('\t|级别 = %s%d号\n',
                                     ship_data['级别'][1],
                                     tonumber(ship_data['级别'][2]))
    result = result .. string.format('\t|类型 = %s\n',
                                     ship_type_id_to_string(ship_data['舰种']))
  end

  result = result .. string.format('\t|火力%s = %d\n',
                                   item_suffix,
                                   ship_data['数据']['火力'][init_or_lv99])
  result = result .. string.format('\t|雷装%s = %d\n',
                                   item_suffix,
                                   ship_data['数据']['雷装'][init_or_lv99])
  result = result .. string.format('\t|对空%s = %d\n',
                                   item_suffix,
                                   ship_data['数据']['对空'][init_or_lv99])
  result = result .. string.format('\t|对潜%s = %d\n',
                                   item_suffix,
                                   ship_data['数据']['对潜'][init_or_lv99])
  result = result .. string.format('\t|索敌%s = %d\n',
                                   item_suffix,
                                   ship_data['数据']['索敌'][init_or_lv99])
  result = result .. string.format('\t|运%s = %d\n',
                                   item_suffix,
                                   ship_data['数据']['运'][init_or_lv99])
  result = result .. string.format('\t|耐久%s = %d\n',
                                   item_suffix,
                                   ship_data['数据']['耐久'][init_or_lv99])
  result = result .. string.format('\t|装甲%s = %d\n',
                                   item_suffix,
                                   ship_data['数据']['装甲'][init_or_lv99])
  result = result .. string.format('\t|回避%s = %d\n',
                                   item_suffix,
                                   ship_data['数据']['回避'][init_or_lv99])

  local ship_carrying = 0
  for _, v in ipairs(ship_data['装备']['搭载']) do
    if v < 0 then
      v = 0
    end
    ship_carrying = ship_carrying + v
  end

  result = result .. string.format('\t|搭载%s = %d\n',
                                   item_suffix,
                                   ship_carrying)
  result = result .. string.format('\t|速力%s = %s\n',
                                   item_suffix,
                                   ship_speed_id_to_string(ship_data['数据']['速力']))
  result = result .. string.format('\t|射程%s = %s\n',
                                   item_suffix,
                                   ship_range_id_to_string(ship_data['数据']['射程']))
  result = result .. string.format('\t|燃料%s = %d\n',
                                   item_suffix,
                                   ship_data['消耗']['燃料'])
  result = result .. string.format('\t|弹药%s = %d\n',
                                   item_suffix,
                                   ship_data['消耗']['弹药'])
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
    if not pcall(function ()
        init_ship_list_string = init_ship_list_string ..
                                data_to_list(wiki_id, INIT)
        end) then
      check_data_validity(wiki_id, INIT)
      os.exit(-1)
    end
    if not pcall(function ()
        lv99_ship_list_string = lv99_ship_list_string ..
                                data_to_list(wiki_id, LV99)
         end) then
      check_data_validity(wiki_id, LV99)
      os.exit(-1)
    end
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
