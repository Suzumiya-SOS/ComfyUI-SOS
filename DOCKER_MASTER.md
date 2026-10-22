# 远端 master 独立 Docker 部署

基线为 `origin/master=7a28332047b6af638dc6c7f72ef3481a718769fd`，ComfyUI 0.42.0。新增独立部署和扩展依赖层，不修改核心源码或官方 requirements。使用 Python 3.12、官方 PyTorch 2.14.1/cu130、TorchVision 0.29.1/cu130，以及原生 Manager；不继承旧基础镜像，不套旧 H3 补丁，不设置旧卸载/缓存优化参数。

当前新环境在主机 **8189** 运行；旧容器 `comfyui-sos` 继续提供8188，尚未切换。默认端口保留8189，避免一次普通 `docker compose up` 意外替换原服务。

## 构建和启动

当前默认镜像为 `comfyui-sos-comfyui:master-extensions-20261022`。它在已验收的核心镜像 `comfyui-sos-comfyui:master-20261022` 上，通过 `Dockerfile.extensions` 安装扩展依赖。已有核心镜像时：

```bash
cd /opt/ComfyUI-SOS-master
docker compose build comfyui
COMFYUI_HOST_PORT=8189 docker compose up -d --no-build --pull never --no-deps comfyui
curl --fail http://127.0.0.1:8189/system_stats
docker compose logs --tail 120 comfyui
```

首次构建、尚无核心镜像时，先使用原 `Dockerfile`：

```bash
docker build -f Dockerfile \
  --build-arg COMFYUI_REVISION=7a28332047b6af638dc6c7f72ef3481a718769fd \
  -t comfyui-sos-comfyui:master-20261022 .
```

核心、Manager的原安装清单保存在镜像 `/opt/comfyui-build/requirements.freeze.txt`；完整扩展环境清单在 `/opt/comfyui-build/extensions.freeze.txt`。`extension-dependencies/core-constraints.txt` 精确保护原116个分发，构建在安装前后逐项校验版本并运行 `pip check`。如果重新构建核心后依赖发生漂移，应先核对并重新验收基线，不能删除保护来让构建假通过。

普通扩展依赖按版本锁定，TorchAudio/TorchCodec使用官方wheel及SHA256，三个已审阅Git依赖按完整提交SHA锁定。基础镜像标签、apt源和普通包工件未全部锁定，因此这是依赖版本可重复、失败时封闭的构建流程，不是字节级可复现镜像。

## 数据和扩展

- 共享原目录的模型（只读）、输入和输出；只读模型挂载不会替扩展自动下载或改模型。
- 新目录使用独立的 `user` 和 `custom_nodes`。默认用户资产从旧环境复制，旧 Manager 的自动安装配置、旧数据库和旧启动脚本不直接迁入用户目录。
- 先原样迁入并更新旧扩展；用户后续授权正常依赖安装，但仍不修改其算法、不为扩展降级官方核心依赖。缺依赖、声明冲突和运行加载错误分别记录；加载成功也不等于其全部工作流已执行通过。
- 扩展镜像已安装普通构建工具、184个新增Python分发和OpenGL系统动态库。没有安装NVCC、SageAttention或旧版Torch，没有运行任意扩展 `install.py`；SAM-2仅采用原作的 `SAM2_BUILD_CUDA=0` 模式，其可选掩膜孔洞/小斑点后处理扩展不可用，不宣称与完整CUDA安装等效。
- 运行容器的核心/依赖层和迁入扩展源码继续只读，禁止用户级Python包覆盖，阻止WAS自动安装并禁止pip自动访问包索引；可写用户数据和缓存通过独立挂载提供。源码目录写配置失败属于保护限制，不冒充版本/API不兼容。原生Manager可以查看，但容器内自动安装/更新仍受保护限制；后续扩展变更应先更新宿主源码、审阅依赖并重建镜像，不能在运行容器中临时pip。
- 输入输出沿用原路径，使 Maoning 的文件位置保持兼容。迁入的工作流可能依赖尚未兼容的扩展，不能保证旧工作流直接可运行。

## 本次8189依赖层回滚

旧核心镜像保留，回滚只重建新 `comfyui-master` 容器。先确认8189没有正在执行/排队任务，再执行：

```bash
curl --fail http://127.0.0.1:8189/queue
cd /opt/ComfyUI-SOS-master
COMFYUI_HOST_PORT=8189 COMFYUI_IMAGE=comfyui-sos-comfyui:master-20261022 \
  docker compose up -d --no-build --pull never --no-deps comfyui
```

恢复扩展镜像时将 `COMFYUI_IMAGE` 改回 `comfyui-sos-comfyui:master-extensions-20261022`。回滚镜像不会回退共享input/output或独立user数据，也不会回退宿主扩展源码；不使用 `down`、删除volume或清理镜像。

## 原8188入口切换和回滚

**尚未执行8188切换。** 新8189已补齐本轮正常依赖，但仍有4个扩展被只读保护挡住、部分可选路径受限，且未运行真实大模型工作流。需要用户接受这些限制、单独授权替换原入口后才执行下面命令；普通重建始终保留8189。

获授权后，先确认旧服务队列为空；保留原容器，不执行 down 或删除镜像，并在停写后备份完整user及ACL/xattrs。

```bash
curl --fail http://127.0.0.1:8188/queue
docker stop comfyui-sos
cd /opt/ComfyUI-SOS-master
COMFYUI_HOST_PORT=8188 docker compose up -d --no-build --pull never --no-deps comfyui
curl --fail http://127.0.0.1:8188/system_stats
```

如需回滚，先停新服务，再启动保留的原容器：

```bash
docker stop comfyui-master
docker start comfyui-sos
curl --fail http://127.0.0.1:8188/system_stats
```

不要同时把两个容器都绑定到主机 8188。旧目录和其中未提交内容不受新分支的 Git 操作影响。

## 当前验收结果与边界（依赖安装后）

- 新核心0.42.0、frontend1.57.1、Torch2.14.1+cu130，原生Manager4.2.2版本接口可访问；`pip check`通过。
- 小矩阵运算、FP16/BF16 SDPA、TorchVision CUDA NMS通过；Kitchen CUDA后端可用。
- 实际8189已运行扩展镜像，网页入口/hashed JS、API和64×64无模型PNG图执行通过；服务healthy、自动重启计数0。旧8188容器ID、镜像和启动时间均未变。
- 44活动扩展中旧Manager由原生版本排除；43尝试加载，导入失败从24降至4，最终3902节点（依赖安装前1611，新增2291、移除0）。H3 T8、VHS、See-through、Fill拼图、Impact等关键节点现已注册；不等于全部功能或模型工作流可用。
- 剩余4个顶层失败为Custom-Scripts、RH_OpenAPI、Prompt-Assistant和Plush写入只读目录被阻止。另有Autocomplete、mtb样式等非致命/单节点写保护限制；未为消除报错而放开源码写权限。
- RMBG的SAM3Segment仍缺Decord：现有0.6.0工件内部标记仅CPython3.6，Python3.12下 `pip check` 不通过，未篡改元数据或降Python。`img2texture` 因关闭全局Pillow超大图片保护而暂缓；SD-PPP的FastAPI提示属于其非Comfy后端可选路径。
- 15项关键依赖导入、16×16小图、合成短WAV保存/读取和重采样通过；`libOpenGL.so.0` 可加载，但未测试OpenGL context/无头渲染。OpenCV/ORT同版多分发仍共享命名空间，provider列出不代表ORT GPU执行通过。
- 没有下载模型或运行H3、See-through等真实模型推理、视频生成、付费API或画质测试；不能将节点注册和小算子验收描述为原工作流全部恢复。
- 原生Manager日志误报未安装Torch，实际导入和GPU测试通过，未因此重装Torch。
- 本轮依赖安装、实际加载和验收报告位于 `/opt/maoning/Reference/comfy-extension-deps-20261022/`；最初重建记录在 `comfy-master-rebuild-20261022/`，源码更新记录在 `comfy-extension-update-20261022/`。私密日志、配置和user备份不进入Git或镜像。

## 2026-10-22：旧扩展源码更新

用户要求更新迁入扩展，范围仍限独立master/8189。先完整备份扩展（含Git、配置、未跟踪/ignored内容与链接）和用户资产，在隔离副本fetch并验证快进，再重放本地修改；只有成功项才替换到新树，原件另存私密保留目录。没有修改核心、安装/降级运行依赖、下载模型或更新旧8188。

11个扩展已快进到核验时的远端版本：

| 扩展 | 新SHA前缀 |
| --- | --- |
| ComfyUI-Easy-Use | `b0b47ca13721` |
| ComfyUI-KJNodes | `f4bae1f9960e` |
| ComfyUI-LTXVideo | `220e1d45aa04` |
| comfyui-minimax-h3-audio-T8 | `e576eba8433e` |
| ComfyUI-OpenPose-Studio | `2075fbe59b88` |
| ComfyUI-RMBG | `a66a5e641a54` |
| comfyui_controlnet_aux | `a587a4c15945` |
| ComfyUI_LayerStyle | `51977b27869a` |
| ComfyUI_RH_OpenAPI | `7f1160f5a66e` |
| LanPaint | `2d7912f9a5ef` |
| rgthree-comfy | `d7297b42f0fa` |

另外29个源码仓库已是对应远端最新（包括PerfectPixel真实源），4个无Git目录保留，旧Manager保留停用。记录共45条，包含44活动目录及PerfectPixel包装背后的1个真实源码仓库，不是45个活动扩展。LTX、RH以及其他定制配置未丢弃；没有向第三方扩展远端推送。

仅源码更新阶段的历史快照：节点净减38，新版LTX当时缺`colour`、77个节点未注册；RMBG从9增至44，KJNodes从261增至265，核心节点无变动。本轮正常依赖安装后已更新为上节3902节点结果；LTX现55节点来自新版实际schema，不能按旧版77数量直接认定又缺22个。缺包不等于新核心API不兼容，源码更新也不能代替补包或工作流验收。

更新清单、备份校验、保留核验及实际加载报告位于本机 `/opt/maoning/Reference/comfy-extension-update-20261022/`。临时无网审计容器已停止；新8189运行、旧8188入口及容器保持原样。
