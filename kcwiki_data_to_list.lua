--
-- kcwiki_data_to_list.lua
--
-- zh.kcwiki.moe
-- Generate "舰娘列表" (https://zh.kcwiki.moe/wiki/%E8%88%B0%E5%A8%98%E5%88%97%E8%A1%A8)
-- by
-- [[模块:舰娘数据]] (https://zh.kcwiki.moe/wiki/%E6%A8%A1%E5%9D%97:%E8%88%B0%E5%A8%98%E6%95%B0%E6%8D%AE)
--
--
-- How to use:
--
-- 1. Install Lua, version 5.1 or newer.
-- 2. Visit https://zh.kcwiki.moe/wiki/%E6%A8%A1%E5%9D%97:%E8%88%B0%E5%A8%98%E6%95%B0%E6%8D%AE,
--    click "编辑", then copy the lua code and save as file "wiki_orig_shipdata.lua".
-- 3. Put kcwiki_data_to_list.lua wiki_orig_shipdata.lua under same path.
-- 4. Run command below in console/cmd/terminal:
--    lua kcwiki_data_to_list.lua > output.txt
-- 5. Copy the code in output.txt to "镇守府沙滩（沙盒）" to ensure
--    there's no syntax error.
-- 6. Finally, edit 舰娘列表.

wikiOrigShipdata = require('wiki_orig_shipdata')


local INIT = 1
local LV99 = 2


function isNormalWikiId(str)
    -- Normal wiki ID: 001, 002, ..., Mist01, Mist02...
    -- Else: 001a, 002a...
    return (string.match(str, '^%d+$') or string.match(str, 'Mist%d+$'))
end


function shipTypeIdToString(shipTypeId)
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

    return tbl[shipTypeId]
end


function shipSpeedIdToString(shipSpeedId)
    local tbl = {}

    tbl[0] = '陆上基地'
    tbl[5] = '低速'
    tbl[10] = '高速'

    return tbl[shipSpeedId]
end


function shipRangeIdToString(shipRangeId)
    local tbl = {
        '短',
        '中',
        '长',
        '超长'
    }
    tbl[0] = '无'

    return tbl[shipRangeId]
end


function dataToList(wikiId, initOrLv99)
    local shipData = wikiOrigShipdata.shipDataTb[wikiId]
    local result = ''
    local itemSuffix = isNormalWikiId(wikiId) and '' or '2'

    if isNormalWikiId(wikiId) then
        result = result .. '{{舰娘列表\n'
        result = result .. string.format('\t|编号 = %s\n', wikiId)
    end
    result = result .. string.format('\t|名字%s = %s\n',
                                     itemSuffix, shipData['中文名'])
    if isNormalWikiId(wikiId) then
        result = result .. string.format('\t|级别 = %s%d号\n',
                                         shipData['级别'][1],
                                         shipData['级别'][2])
        result = result .. string.format('\t|类型 = %s\n',
                                         shipTypeIdToString(shipData['舰种']))
    end

    result = result .. string.format('\t|火力%s = %d\n',
                                     itemSuffix,
                                     shipData['数据']['火力'][initOrLv99])
    result = result .. string.format('\t|雷装%s = %d\n',
                                     itemSuffix,
                                     shipData['数据']['雷装'][initOrLv99])
    result = result .. string.format('\t|对空%s = %d\n',
                                     itemSuffix,
                                     shipData['数据']['对空'][initOrLv99])
    result = result .. string.format('\t|对潜%s = %d\n',
                                     itemSuffix,
                                     shipData['数据']['对潜'][initOrLv99])
    result = result .. string.format('\t|索敌%s = %d\n',
                                     itemSuffix,
                                     shipData['数据']['索敌'][initOrLv99])
    result = result .. string.format('\t|运%s = %d\n',
                                     itemSuffix,
                                     shipData['数据']['运'][initOrLv99])
    result = result .. string.format('\t|耐久%s = %d\n',
                                     itemSuffix,
                                     shipData['数据']['耐久'][initOrLv99])
    result = result .. string.format('\t|装甲%s = %d\n',
                                     itemSuffix,
                                     shipData['数据']['装甲'][initOrLv99])
    result = result .. string.format('\t|回避%s = %d\n',
                                     itemSuffix,
                                     shipData['数据']['回避'][initOrLv99])

    local shipCarrying = 0
    for _, v in ipairs(shipData['装备']['搭载']) do
        if v < 0 then
            v = 0
        end
        shipCarrying = shipCarrying + v
    end

    result = result .. string.format('\t|搭载%s = %d\n',
                                     itemSuffix,
                                     shipCarrying)
    result = result .. string.format('\t|速力%s = %s\n',
                                     itemSuffix,
                                     shipSpeedIdToString(shipData['数据']['速力']))
    result = result .. string.format('\t|射程%s = %s\n',
                                     itemSuffix,
                                     shipRangeIdToString(shipData['数据']['射程']))
    result = result .. string.format('\t|燃料%s = %d\n',
                                     itemSuffix,
                                     shipData['消耗']['燃料'])
    result = result .. string.format('\t|弹药%s = %d\n',
                                     itemSuffix,
                                     shipData['消耗']['弹药'])
    local remark = initOrLv99 == LV99 and 'Lv99' or ''
    result = result .. string.format('\t|备注%s = %s\n',
                                     itemSuffix, remark)

    result = result .. '}}\n'
    return result
end


function main()
    local wikiIdList = {}
    local initShiplistString = ''
    local lv99ShiplistString = ''
    local shipDataTable = wikiOrigShipdata.shipDataTb

    for id in pairs(shipDataTable) do
        table.insert(wikiIdList, id)
    end

    table.sort(wikiIdList)
    for _, wikiId in ipairs(wikiIdList) do

        if not isNormalWikiId(wikiId) then
            --
            -- Kcwiki ID such as 001a.
            -- As the last ID is 001, need to delete '}}\n' in the end.
            initShiplistString = string.sub(initShiplistString, 1, -4) .. '\n'
            lv99ShiplistString = string.sub(lv99ShiplistString, 1, -4) .. '\n'
        end
        initShiplistString = initShiplistString .. dataToList(wikiId, INIT)
        lv99ShiplistString = lv99ShiplistString .. dataToList(wikiId, LV99)
    end

    print('<!-- 如果您熟悉lua，可参考该lua脚本生成该页面代码')
    print('https://github.com/mczoden/kcwiki/edit/master/kcwiki_data_to_list.lua')
    print('同时也欢迎您对脚本提出意见和建议，谢谢-->\n')
    print('<tabber>初始数据={{舰娘列表/页首}}')
    print(initShiplistString)
    print('{{页尾|html}}')
    print('|-|满级数据={{舰娘列表/页首}}')
    print(lv99ShiplistString)
    print('{{页尾|html}}')
    print('</tabber>')
    print('[[en:Ship list]]')
    print('[[ko:함선목록]]')
end

main()
