# C2C12 Myotube Quantification

C2C12 肌管定量与孔重复分析：**ImageJ全量分割预览 → MyHC逐张审阅 → 独立DAPI逐张审阅 → ImageJ面积/融合指数＋Python直径 → 实际保留视野的孔均值 → Excel / Prism列格式**。

可安装到 **Claude Code 和 Codex**。本地科学计算流程已在 Windows + Fiji/ImageJ + Python 环境验证。

![C2C12 肌管定量 skill 功能概览](workflow-overview.png)

## 安装到 Claude Code 和 Codex

安装 Node.js 22.20+ 后，运行以下命令，同时安装到两个客户端：

```bash
npx skills add https://raw.githubusercontent.com/BoBolol-CN/c2c12-myotube-quant/main/c2c12-myotube-quant.zip -g -a claude-code codex --copy
```

只安装其中一个客户端：

```bash
# Claude Code
npx skills add https://raw.githubusercontent.com/BoBolol-CN/c2c12-myotube-quant/main/c2c12-myotube-quant.zip -g -a claude-code --copy

# Codex
npx skills add https://raw.githubusercontent.com/BoBolol-CN/c2c12-myotube-quant/main/c2c12-myotube-quant.zip -g -a codex --copy
```

安装采用 [Vercel Skills CLI](https://github.com/vercel-labs/skills)。PowerShell 只是可使用的终端，不是所需的 AI 客户端；`--copy` 避免 Windows 符号链接权限问题。

也可下载 [完整 skill ZIP](c2c12-myotube-quant.zip)，将其中的 `c2c12-myotube-quant` 文件夹放入：

- Claude Code：`~/.claude/skills/`
- Codex：`$CODEX_HOME/skills/`，未设置时为 `~/.codex/skills/`

安装后新开会话，Claude Code 使用 `/c2c12-myotube-quant`，Codex 使用 `$c2c12-myotube-quant`，附上图片目录和需求。安装 skill 不会自动安装 Fiji、Python 或 GraphPad Prism。

## 工作流

1. **确认实验设计。** 确认组别、配对、视野与孔的对应关系和独立生物学重复。已有明确回答不重复询问，不从文件数推断孔归属。
2. **ImageJ全量分割预览。** 首轮直接处理全部视野，不抽5张；原图只读。保留原生宏、日志、参数、掩膜和校验值，不固定跨实验乘数。
3. **先完成MyHC HTML逐张审阅。** 左侧纯绿通道和黄色轮廓，右侧只填需要修改的MyHC乘数。不设OK/不OK；留空提交表示当前版本通过，填写乘数则重新分割，下一轮只显示需修改视野。
4. **随后单独完成DAPI HTML逐张审阅。** 仅展示MyHC通过视野配对的纯蓝通道及黄色核轮廓。核对漏核、核粘连及背景误检；只填写需修改的DAPI乘数，留空提交通过。已确认MyHC掩膜保留；DAPI下一轮也只显示需修改视野。沿用DAPI参数不代表具体视野掩膜已经通过。
5. **仅排除数据，不删除图像。** 明确不纳入的视野保留原图、掩膜、预览和意见。排除后孔归属不变；不依据指标高低或显著性决定排除。
6. **两通道都通过后测量并按孔平均。** ImageJ计算面积、核归属和融合指数，Python计算骨架＋精确EDT直径。每孔平均实际保留的视野：保留3/2/1个分别平均，0个则该孔不可用，不填0。融合指数先逐视野计算再平均，n为独立孔数。
7. **核验并交付Excel与Prism列格式。** 逐视野明细、逐孔均值公式、有效视野数及排除记录均保留；最终输出.xlsx，不冻结或拆分窗格。

### 两个通道的验收必须分开

MyHC全部完成后，使用 `build_dapi_review.py` 生成DAPI页面，并以 `review_server.py --channel dapi` 启动独立反馈服务。DAPI有独立的轮次、意见JSON和不可变提交快照。每个纳入视野都必须具有MyHC和DAPI各自的验收快照及掩膜SHA256；缺少任何一个通道的通过记录，测量入口都会拒绝执行。草稿不算验收，填写新乘数也不等于尚未见过的新掩膜已经通过。

## 三项指标

| 指标 | 计算方式 | 输出单位 |
|---|---|---|
| MyHC 阳性面积 | ImageJ：全部MyHC阳性像素面积及其占全视野比例 | px²、% |
| 肌管直径 | Python：逐对象补零、scikit-image骨架＋SciPy精确EDT；骨架点2r先对象平均，再对象等权汇总 | px |
| 融合指数 | ImageJ：含 **≥2个核**的MyHC对象内核数 / 全视野DAPI核数 ×100% | % |

核归属依据 DAPI 核质心是否落在对应 MyHC 对象内。单核对象不进入融合分子，但单核、无核对象仍计入面积和直径。没有额外的尺寸/形状筛选，也不做人工核数修正。零核或缺失视野会标记需复核，不填零或静默少算。

融合指数的 ≥2 核标准是本项目口径；Python骨架＋精确EDT直径是本项目扩展，不声称属于 ViaFuse 原版自带或作者认证功能。没有有效长度校准时不换算为 μm、μm²。

## Excel 与 Prism

最终交付 `.xlsx`，而非用 CSV 替代。每个指标区首行为组名，每列下方是对应孔均值。右侧百分比采用 0–100 数值，可复制到 GraphPad Prism 的 Column 表格。

当前版本**不自动生成Prism原生工程、统计检验或显著性星号**。流程图仅展示计算步骤，不包含实验图像。肌管直径表示二维掩膜局部厚度估计，粘连、分支和碎片会影响结果。

## 安装包内容

```text
c2c12-myotube-quant/
├── SKILL.md
├── scripts/
│   ├── run_batch.py                # 全量分割预览
│   ├── run_viafuse.py              # 原生ImageJ分割
│   ├── build_review.py             # MyHC HTML预览页面
│   ├── build_dapi_review.py        # MyHC完成后的独立DAPI审阅页面
│   ├── review_server.py            # MyHC/DAPI独立意见保存与提交快照
│   ├── measure_reviewed_masks.py   # 当前测量入口：ImageJ面积/融合＋Python直径
│   ├── measure_python_diameter.py  # 仅计算骨架/精确EDT直径
│   ├── validate_manifest.py        # 实验设计及来源校验
│   └── export_excel.mjs            # 孔均值和Prism列格式
├── references/
│   ├── data_contract.md
│   ├── html_review.md
│   └── execution.md
└── assets/
    ├── review.html                 # 左图右侧乘数输入模板
    ├── native_area_fusion.js       # ImageJ面积、核归属与融合指数
    └── viafuse/                    # 原版宏及来源校验
```

旧 `select_pilot.py`、`measure_masks.py` 和 `native_measure_masks.js` 仅保留为历史参考，不是当前入口；`measure_native_imagej.py` 兼容转到当前混合测量入口。

ZIP保留完整skill源码、HTML模板和原版宏，不含实验原图、分割结果、用户审阅意见或本地分析运行记录。skill中的本机路径用于原安装环境；其他机器须按实际环境配置Fiji、工作目录及临时目录。

## 软件与运行环境

- Fiji / ImageJ：通过原生启动器后台执行。已验证 Windows ImageJ 1.52i；可使用 `--imagej` 指定本机路径。
- Python：`numpy`、`scipy`、`scikit-image`、`tifffile`、`Pillow`。
- Excel：自带 JavaScript 导出脚本使用 `@oai/artifact-tool`，按当前 Codex 表格运行库配置执行。安装到 Claude Code 不会附带 Codex 专用工具；其他客户端需配置兼容的表格写入环境或按相同数据口径适配导出，不能把安装成功视为该环境已完整验证。
- 不需要 MATLAB，不使用 MyoCount。Windows 以外的平台与其他 ImageJ 版本需先验证启动方式和掩膜一致性。

## 验证与来源

已验证两阶段验收闸门、DAPI独立反馈、草稿与正式提交的区别、缺少或不匹配DAPI验收记录时拒绝测量，以及原生ImageJ面积/融合指数与Python直径的完整流程。Excel保存后的均值公式缓存也独立核对。上述程序验证不等同于证明所有新图像的分割准确率。

原始ViaFuse MyHC块包含连续两次转换为掩膜；在本机ImageJ 1.52i中复现过第二次重新自动阈值导致前景反转。运行副本在第二次转换前显式 `setThreshold(255,255)`，保留第一次选中的255前景，不用Python按图像亮度猜测反相。作者原宏文件保持原样；修复若改变已验收掩膜，需重新审阅。

ViaFuse 来源：[tasneemsmacros/ViaFuse](https://github.com/tasneemsmacros/ViaFuse)，提交 `40f178768853bb68936e50b2fe48da1dcf9010da`。分割沿用作者宏步骤，原版宏及校验信息保留在安装包中。原版程序权利归其作者；本仓库不对第三方文件重新授权。
