# 远端 master 独立 Docker 部署

基线为 `origin/master=7a28332047b6af638dc6c7f72ef3481a718769fd`，ComfyUI 0.42.0。仅新增部署文件，不修改核心源码或官方 requirements。使用 Python 3.12、官方 PyTorch 2.14.1/cu130、TorchVision 0.29.1/cu130，以及原生 Manager；不继承旧基础镜像，不套旧 H3 补丁，不设置旧卸载/缓存优化参数。

当前新环境在主机 **8189** 运行；旧容器 `comfyui-sos` 继续提供8188，尚未切换。默认端口保留8189，避免一次普通 `docker compose up` 意外替换原服务。

## 构建和启动

```bash
cd /opt/ComfyUI-SOS-master
docker compose build
docker compose up -d
docker compose logs --tail 120
```

首次验证使用独立端口，旧服务保持运行：

```bash
COMFYUI_HOST_PORT=8189 docker compose up -d
curl --fail http://127.0.0.1:8189/system_stats
```

核心、Manager 的实际安装清单保存在镜像 `/opt/comfyui-build/requirements.freeze.txt`。官方核心依赖原样解析，精确运行版本以该文件为准。

## 数据和扩展

- 共享原目录的模型（只读）、输入和输出；只读模型挂载不会替扩展自动下载或改模型。
- 新目录使用独立的 `user` 和 `custom_nodes`。默认用户资产从旧环境复制，旧 Manager 的自动安装配置、旧数据库和旧启动脚本不直接迁入用户目录。
- 按用户要求原样迁入旧扩展，但不解决其兼容性，不为扩展降级官方核心依赖。缺依赖、声明冲突和运行加载错误分别记录；加载成功也不等于其全部工作流已执行通过。
- 暂不为旧扩展安装编译器、NVCC、SageAttention 或旧版 Torch；需要这些环境的节点按实际错误报告。
- 为遵守“不处理兼容”的要求，运行容器的核心/依赖层和迁入扩展源码只读，禁止用户级 Python 包覆盖，阻止 WAS 自动安装并禁止 pip 自动访问包索引；可写用户数据和缓存通过独立挂载提供。扩展自动 pip、源码目录写配置失败属于保护限制，不冒充版本/API 不兼容。原生 Manager 可查看，但安装/更新扩展及其依赖需要后续明确授权、在宿主调整源码或更新镜像并重建，不在运行容器中自动修改环境。
- 输入输出沿用原路径，使 Maoning 的文件位置保持兼容。迁入的工作流可能依赖尚未兼容的扩展，不能保证旧工作流直接可运行。

## 原入口切换和回滚

**尚未执行切换。** 当前23个旧扩展加载失败，关键H3/VHS/分层等流程未恢复。即使新核心和GPU/网页/API验收通过，也需要用户明确接受这些限制、授权替换原入口后才执行下面命令。

获授权后，先确认旧服务队列为空；保留原容器，不执行 down 或删除镜像，并在停写后备份完整user及ACL/xattrs。

```bash
curl --fail http://127.0.0.1:8188/queue
docker stop comfyui-sos
cd /opt/ComfyUI-SOS-master
COMFYUI_HOST_PORT=8188 docker compose up -d
curl --fail http://127.0.0.1:8188/system_stats
```

如需回滚，先停新服务，再启动保留的原容器：

```bash
docker stop comfyui-master
docker start comfyui-sos
curl --fail http://127.0.0.1:8188/system_stats
```

不要同时把两个容器都绑定到主机 8188。旧目录和其中未提交内容不受新分支的 Git 操作影响。

## 当前验收结果与边界

- 新核心0.42.0、frontend1.57.1、Torch2.14.1+cu130，原生Manager4.2.2版本接口可访问；`pip check`通过。
- 小矩阵运算、FP16/BF16 SDPA、TorchVision CUDA NMS通过；Kitchen CUDA后端可用。
- 迁入user和原样旧扩展后，网页入口/hashed JS、API和64×64无模型PNG图执行通过，服务健康、重启0。
- 44活动扩展中旧Manager由原生版本排除；43尝试加载，23失败、20未标失败，最终1649节点。失败多为缺包及只读写入限制，并非已证明都是新版核心API不兼容；没有处理这些兼容项。
- H3 T8采样器、VHS、See-through、BiRefNet、Fill拼图等关键节点仍缺失，原工作流并未全部恢复；没有运行真实大模型、付费API、视频或画质测试。
- 原生Manager日志误报未安装Torch，实际导入和GPU测试通过，未因此重装Torch。
- 本机完整静态/运行报告与测试记录位于 `/opt/maoning/Reference/comfy-master-rebuild-20261022/`，私密日志和user备份不进入Git或镜像。
