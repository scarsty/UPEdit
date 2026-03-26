# UPEdit
An Editor for All Heroes of Kam Yung's Stories

  Upwinded Editor(UPedit)
  An Editor--Special for All Heroes in Kam Yung's Stories
  Created by Upwinded.L.
  ©2011 Upwinded.L. Some rights reserved.

不需要任何插件即可编译，建议使用Delphi 10.4或之后的版本。

工程内提供的预编译版是64位版本。需注意网上下载的Delphi有可能不提供64位工具包。

  -----------------
  以下是旧内容





  You can build it with delphi2010, with some parts supported by XLSreadwriteII.
  Anybody who gets this source code is able to modify or rebuild it anyway,
  but please keep this section when you want to spread a new version.



  你可以用delphi2010编译这些代码，其中一部分要用到XLSreadwriteII这个第三方控件。
  任何得到此代码的人都可以修改或者重新编译这段代码，但是请保留这段文字。


  Upwinded.L.(281184040@qq.com), in 2011 April. 
  
  -----------------
  以下是sb500的补充
  
  xls支持的列数最多到256，改用tms flexcel可以支持xlsx。
  后该插件过期，改为自己手动写xlsxio和libxlsxwriter的pas文件。

  -----------------

  使用数据库的时候，为了固定处理方便，增加以下几个选项：

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

  ## 在 VS Code 中构建与调试

  仓库已提供 VS Code 配置文件：

  - `.vscode/tasks.json`：Delphi 构建任务（Debug/Release, Win64）
  - `.vscode/launch.json`：F5 启动 `Code/debug/UPEdit.exe`
  - `Code/tools/build_delphi.cmd`：自动查找并加载 Delphi 的 `rsvars.bat`，再调用 `msbuild`

  使用步骤：

  1. 安装 Delphi（建议 10.4+，且包含 Win64 工具链）。
  2. 在 VS Code 打开仓库根目录。
  3. 按 `Ctrl+Shift+B` 运行默认任务 `Delphi: Build Debug Win64`。
  4. 按 `F5` 运行 `UPEdit (Win64 Debug)`。

  说明：

  - 如果你的 Delphi 不是安装在默认路径，可设置系统环境变量 `BDS` 指向 Delphi 安装目录（例如 `C:\Program Files (x86)\Embarcadero\Studio\22.0`）。
  - 工程的 Debug 输出目录为 `Code/debug`，Release 输出目录为 `Code/release`。