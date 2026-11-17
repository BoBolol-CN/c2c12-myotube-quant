# C2C12 Myotube Quantification

C2C12 肌管定量：ImageJ全量MyHC预览 → MyHC HTML逐张审阅 → Python LoG自动DAPI → ImageJ面积/融合指数＋Python直径 → 按孔平均 → 可映射Excel＋原生Prism。

## 2026-11-16更新

- DAPI默认改为Python LoG-v1中心检测及强度标记分水岭，不再使用DAPI乘数分割或历史面积/圆度筛选方案。
- 不再逐图要求DAPI人工审核。保留自动质量核验、独立实例标签、质心、参数、脚本版本及校验值；真实异常仍须核查。
- MyHC HTML逐张审阅仍为必选项；右侧仅填写需修改的乘数，提交时空白通过，下一轮只显示待修改视野。
- Excel采用固定孔位映射；移动黄色C列视野编号，配对DAPI和指标自动查找，第二个sheet单独公式汇总。
- 三个指标导入同一个Prism工程，三表三图；沿用用户9色模板，超过9组循环用色。

## 安装

下载[完整skill ZIP](c2c12-myotube-quant.zip)，将其中的 `c2c12-myotube-quant` 文件夹放入客户端技能目录：

- Codex：`$CODEX_HOME/skills/`，未设置时为 `~/.codex/skills/`。
- Claude Code：`~/.claude/skills/`。

也可沿用本仓库已有的Skills CLI安装方式（需Node.js 22.20+）：

```bash
npx skills add https://raw.githubusercontent.com/BoBolol-CN/c2c12-myotube-quant/main/c2c12-myotube-quant.zip -g -a claude-code codex --copy
```

安装后新开会话，在Codex使用 `$c2c12-myotube-quant`，Claude Code使用 `/c2c12-myotube-quant`，提供图片目录和需求。安装skill不会自动安装Fiji、Python、Prism或Codex专用表格运行库。

## 当前七步流程

1. 确认实验设计、通道配对、视野/孔映射与独立生物学重复；已确认的信息不重复询问，不从文件数猜孔归属。
2. 原生ImageJ直接生成全部MyHC预览，不再抽5张；原图只读，保留宏、参数、掩膜、日志及SHA256，不固定跨实验MyHC乘数。
3. MyHC用HTML单页逐图审阅，左图右侧填乘数，不显示OK/不OK。确认后自动执行Python LoG DAPI，无DAPI逐图人工提交门槛。
4. 无法评估的视野只排除数据，不删除原图或记录。每孔以实际保留的3/2/1个视野取均值，0个有效视野的孔留空；保留原孔归属和排除原因，不依据指标高低决定排除。
5. ImageJ计算全部MyHC阳性面积、LoG核的质心归属及融合指数；Python计算DAPI实例与骨架/精确EDT直径。相邻核保留独立标签，不能先合成二值掩膜再数连通块。融合指数为含≥2核的MyHC对象内核数/全部DAPI核数。
6. Excel依次为“视野安排”“Prism汇总”“原始视野数据”“参数与排除”。固定A/B组别孔位，只交换黄色C列编号；查找公式带出数据，逐视野指标在孔内算术平均。重复/未知/跨组编号须显示异常并使对应孔均值留空。无冻结或拆分窗格。
7. 从当前保存且可信重算的Excel第二个sheet导入Prism，三项指标各一张Column表和关联图，保存在同一工程。每点是孔均值，空孔不填0。沿用模板且九色循环，不擅自增加统计检验或旧显著性。最终Excel和Prism放图片目录最上层；Excel之后调整需重新导入Prism。

## DAPI LoG-v1

原始uint16蓝通道缩至0.5倍；半分辨率Gaussian背景sigma=25，扣除后按P99.8归一化；平滑sigma=0.7。`blob_log`使用min_sigma=3、max_sigma=10、num_sigma=10、threshold=0.05、overlap=0.5。前景为平滑图高于Otsu×0.5，去除小于25半分辨率像素的连通块并填小于16像素孔洞；LoG中心作标记，以负强度作分水岭地形。去除小于25半分辨率像素的实例后连续编号，最近邻放回原尺寸，保留边缘核。

显示亮度/对比度不改变计数；DAPI不乘0.5、7或8。完整契约在安装包的 `references/dapi_log.md`。本批两张已认可试图的回归计数为1145、1152，实例标签逐像素一致；这不代替对新实验通道、配对和图像质量的核验。

## 指标与单位

| 指标 | 计算 | 无校准单位 |
|---|---|---|
| MyHC阳性面积 | ImageJ全部前景面积与全视野比例 | px²、% |
| 融合指数 | ImageJ按LoG独立实例质心归属，含≥2核对象内核数/总核数 | % |
| 肌管直径 | Python逐对象补背景、骨架＋精确EDT，骨架点2r先对象内平均，再对象等权汇总 | px |

MyHC的无核、单核、边缘和碎片对象仍计入面积和直径，不额外按核数、面积、形状或圆度筛选。直径是二维局部厚度估计，不能换写Feret或未经校准的µm。融合指数先逐视野计算，再对孔内比例取均值，不能以合并核数比例代替。

DAPI改法后旧核数、核归属、融合指数及相关Excel/Prism标记作废并重算；同一已验收MyHC掩膜的面积/直径可验证后复用。原图和历史结果保留。

## 安装包与环境

ZIP包含完整 `SKILL.md`、Python/JavaScript脚本、HTML模板、数据契约和ViaFuse原版宏，不含实验原图、分割标签、计数明细、用户意见或本地分析运行记录。`select_pilot.py`、`build_dapi_review.py`等历史兼容脚本保留，当前流程以SKILL.md及LoG入口为准。

需要本机Fiji/ImageJ、Python（numpy、scipy、scikit-image、tifffile、Pillow）、Excel导出运行库 `@oai/artifact-tool`，以及生成原生工程所需的GraphPad Prism。已在Windows环境验证；其他机器需配置实际可执行文件路径、工作目录和临时目录。安装到其他客户端不会附带Codex专用运行库，需适配相同的数据口径。

MyHC分割沿用ViaFuse绿色通道步骤；第二次Convert to Mask前显式 `setThreshold(255,255)` 防止二值前景重阈值反转。原版宏及来源校验保留在包中。来源：[tasneemsmacros/ViaFuse](https://github.com/tasneemsmacros/ViaFuse)，提交 `40f178768853bb68936e50b2fe48da1dcf9010da`。Python LoG、直径扩展和本项目融合口径不冒称ViaFuse原版自带或作者认证功能；第三方文件权利归原作者。
