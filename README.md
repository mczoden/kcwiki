# kcwiki
kcwiki scripts

Generate [舰娘列表] (https://zh.kcwiki.moe/wiki/%E8%88%B0%E5%A8%98%E5%88%97%E8%A1%A8) by [模块:舰娘数据] (https://zh.kcwiki.moe/wiki/%E6%A8%A1%E5%9D%97:%E8%88%B0%E5%A8%98%E6%95%B0%E6%8D%AE)


直接在终端运行:
    python download_and_conver.py
脚本会自动检测舰娘列表是否需要更新，
如果需要更新，直接将output.txt中的内容，复制到舰娘列表的编辑区。


如果只有lua，没有python环境，需要做如下步骤：
1. 直接用浏览器访问kcwiki的 模块:舰娘数据
2. 打开编辑模式，复制lua代码到本地文件，并重命名为wiki_orig_shipdata
3. 在终端运行
    lua kcwiki_data_to_list.lua > output.txt
4. 直接将output.txt中的内容，复制到舰娘列表的编辑区。 

Has tested under:
python >= 2.6
lua >= 5.1
