# C2C12 Myotube Quantification

C2C12 肌管定量与孔重复分析：**ImageJ全量分割预览 → HTML逐张审阅 → ImageJ面积/融合指数＋Python直径 → 实际保留视野的孔均值 → Excel / Prism列格式**。

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

1. **确认实验设计。** 确认每组视野数、孔数、MyHC/DAPI配对和逐视野孔归属，以及每孔是否为独立生物学重复；已有回答不重复询问。
2. **ImageJ直接全量试跑。** 首轮生成全部视野的MyHC/DAPI分割与预览，不随机抽5张、不要求pilot；原图只读，保留宏、日志、掩膜、逐图参数与校验值，无跨实验固定乘数。
3. **HTML逐张审阅是必选项。** 一个滚动页面：左侧纯MyHC与黄色轮廓，右侧仅填写需修改的MyHC乘数，不设OK/不OK。提交留空表示当前版本通过，填写正数表示请求重分割；下一轮只显示需修改视野。DAPI同样验收，已通过的不重跑。
4. **只排除数据，不删除图片。** 无法可靠评估时明确标记“不纳入计算”，保留原图、掩膜、预览及记录。不能依据指标高低或显著性决定排除。
5. **同一已验收掩膜分工测量。** ImageJ计算MyHC面积、DAPI核归属和融合指数；Python读取同一MyHC掩膜及原生8连通对象标签，用骨架＋精确欧氏距离变换计算直径，不重新分割。
6. **按孔平均实际保留视野。** 原计划每孔3视野时，保留3/2/1个就分别平均3/2/1个；0个则该孔不可用，不记0，并报告有效孔数。融合指数先逐视野计算再平均；n为独立孔数。
7. **核验并交付Excel。** 核对校验值、对象、核归属及孔均值；左侧逐视野结果，右侧Prism Column格式每孔一个值，保留公式、有效视野数与排除记录，不冻结或拆分窗格。

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
│   ├── build_review.py             # HTML预览页面
│   ├── review_server.py            # 本地意见保存与提交快照
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

当前混合测量入口已用三个组各一个已验收视野做集成验证：Python直径与独立对比计算一致，ImageJ面积及融合指数与此前原生结果一致。原生测试图核验8连通、边缘、孔洞、核质心取整和≥2核分子；强制绑定用户提交快照与掩膜校验值。skill格式校验通过。这些程序验证不等同于证明新图像的分割准确率，也不代表已重新分析所有历史批次。

ViaFuse 来源：[tasneemsmacros/ViaFuse](https://github.com/tasneemsmacros/ViaFuse)，提交 `40f178768853bb68936e50b2fe48da1dcf9010da`。分割沿用作者宏步骤，原版宏及校验信息保留在安装包中。原版程序权利归其作者；本仓库不对第三方文件重新授权。
