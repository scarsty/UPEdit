# UPEdit
An Editor for All Heroes of Kam Yung's Stories

  Upwinded Editor(UPedit)
  An Editor--Special for All Heroes in Kam Yung's Stories
  Created by Upwinded.L.
  ©2011 Upwinded.L. Some rights reserved.

不需要任何插件即可编译，建议使用Delphi 10.4或之后的版本。

工程内提供的预编译版是64位版本。需注意网上下载的Delphi有可能不提供64位工具包。

## Qt 版本验证

Qt 工程位于 `QtCode`，当前 Windows 配置为 Qt 6.3.2、MSVC x64。
运行 `QtCode/release/UPEdit.exe` 时可以传入 INI 的绝对路径。

无损回归测试入口：

```powershell
$exe = (Resolve-Path 'QtCode/release/UPEdit.exe').Path
$report = Join-Path $env:TEMP 'upedit-selftest.txt'
Start-Process $exe -WorkingDirectory (Split-Path $exe) -ArgumentList @('--self-test', $report) -Wait
Get-Content $report
```

测试使用临时文件，不改写游戏存档。覆盖地图模块的小端格式、非正方形往返、
剪贴板裁剪、分层渲染像素、事件累计结束偏移、场景切换及撤销重做、
多帧与稀疏编号 PNG/ZIP、战斗帧配置保留。

Lua／剧本导入功能按用户要求不移植，已从 Qt 版移除，无需部署 Lua DLL。
Delphi 原版及其剧本脚本库保留不变。
完整真实存档回写还需使用有效数据副本核验，不能用空数据库代替。

Qt 场景编辑按进度保留内存会话，关闭前提示未保存修改。场景模块仍兼容六层
`.smd`，新导出同时生成 `.smd.events`，携带事件定义及模块匹配数据；移动模块时
应一起移动这两个文件。旧模块没有事件定义时只导入非事件层，避免误用目标场景事件。
跨场景粘贴会分配空闲事件编号；目标位置已有事件或编号不足时拒绝整次粘贴。

PNG 文件夹保存使用 `.upedit-images.json` 记录管理的图片，未登记的其他图片不自动删除。
保存先校验、暂存，再替换，失败时回滚；场景四文件及主地图五文件也采用批量提交。
这些机制处理正常文件操作失败，不保证断电时的跨文件原子性。若回滚被文件锁阻止，
请保留 `.upedit-old-*` 或 `.upedit-save-*` 中的备份。首次保存旧 PNG 目录前仍应备份。

## 旧版构建说明

  You can build it with delphi2010, with some parts supported by XLSreadwriteII.
  Anybody who gets this source code is able to modify or rebuild it anyway,
  but please keep this section when you want to spread a new version.

  你可以用delphi2010编译这些代码，其中一部分要用到XLSreadwriteII这个第三方控件。
  任何得到此代码的人都可以修改或者重新编译这段代码，但是请保留这段文字。


  Upwinded.L.(281184040@qq.com), in 2011 April. 
  
## 以下是sb500的补充
  
  xls支持的列数最多到256，改用tms flexcel可以支持xlsx。
  后该插件过期，改为自己手动写xlsxio和libxlsxwriter的pas文件。

### 使用数据库的时候，为了固定处理方便，增加以下几个选项：

  ```ini
  ;表格名称，空格分开
    Types=base role item submap magic shop bag
  ;每个表格是名字的字段
    TypeNameName=null 名字 物品名 名称 名称 null null
  ;以下是处理引用，含有下面名字的即视为引用，需前后使用|包围，不包含数字部分
    TypeRef1=|使用人|仅修炼人物|
    TypeRef2=|物品编号|武器|防具|装备物品|携带物品|修炼物品|练出物品|
    TypeRef3=|跳转场景|
    TypeRef4=|装备武功|二组装备武功|所会武功|练出武功|
```
### lazsrus的tag

基本由ai转换，除了画地图功能其他大致正常，但是问题在此修改器目前只有这个功能还不能被其他工具取代。

lcl存在大量兼容性和性能问题，突出的几个是：BitMap设置为8bit，但实际仍是24bit。CopyRect无效，刷新时机纯胡凑。在浪费大量request之后，因ai出现了bug，恢复时误删了大量修改，最后放弃。