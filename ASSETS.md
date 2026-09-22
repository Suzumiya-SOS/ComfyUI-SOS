# 资产清单

Docker Compose 不会自动下载自定义节点或模型。以下命令均在仓库根目录执行。

清单中的勾选状态以实际磁盘内容为准，未安装的项标为 `[ ]`。

## 自定义节点

保存的工作流会用到下列扩展。`custom_nodes/` 已被 `.gitignore` 忽略，需要在本机单独克隆。

### 已安装（25 个）

- [x] [comfyui_controlnet_aux](https://github.com/Fannovel16/comfyui_controlnet_aux)
- [x] [ComfyUI-Autocomplete-Plus](https://github.com/newtextdoc1111/ComfyUI-Autocomplete-Plus)
- [x] [ComfyUI-Custom-Scripts](https://github.com/pythongosssss/ComfyUI-Custom-Scripts)
- [x] [ComfyUI-DaSiWa-Nodes](https://github.com/darksidewalker/ComfyUI-DaSiWa-Nodes)
- [x] [ComfyUI-Easy-Use](https://github.com/yolain/ComfyUI-Easy-Use)
- [x] [ComfyUI-FBCNN](https://github.com/Miosp/ComfyUI-FBCNN)
- [x] [ComfyUI-GGUF](https://github.com/city96/ComfyUI-GGUF)
- [x] [ComfyUI-Image-Saver](https://github.com/alexopus/ComfyUI-Image-Saver)
- [x] [ComfyUI-Impact-Pack](https://github.com/ltdrdata/ComfyUI-Impact-Pack)
- [x] [ComfyUI-Impact-Subpack](https://github.com/ltdrdata/ComfyUI-Impact-Subpack)
- [x] [ComfyUI_IPAdapter_plus](https://github.com/cubiq/ComfyUI_IPAdapter_plus)
- [x] [ComfyUI-KJNodes](https://github.com/kijai/ComfyUI-KJNodes)
- [x] [ComfyUI-layerdiffuse](https://github.com/huchenlei/ComfyUI-layerdiffuse)
- [x] [ComfyUI-Lora-Manager](https://github.com/willmiao/ComfyUI-Lora-Manager)
- [x] [ComfyUI-LTXVideo](https://github.com/Lightricks/ComfyUI-LTXVideo)
- [x] [ComfyUI-ppm](https://github.com/pamparamm/ComfyUI-ppm)
- [x] [ComfyUI-QwenVL](https://github.com/1038lab/ComfyUI-QwenVL)
- [x] [ComfyUI-See-through](https://github.com/jtydhr88/ComfyUI-See-through)
- [x] [ComfyUI-segment-anything-2](https://github.com/kijai/ComfyUI-segment-anything-2)
- [x] [ComfyUI_UltimateSDUpscale](https://github.com/ssitu/ComfyUI_UltimateSDUpscale)
- [x] [ComfyUI-VideoHelperSuite](https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite)
- [x] [ComfyUI-WanVideoWrapper](https://github.com/kijai/ComfyUI-WanVideoWrapper)
- [x] [comfyui-WhiteRabbit](https://github.com/Artificial-Sweetener/comfyui-WhiteRabbit)
- [x] [rgthree-comfy](https://github.com/rgthree/rgthree-comfy)
- [x] [z-tipo-extension](https://github.com/KohakuBlueleaf/z-tipo-extension)

### 需要补丁

以下扩展在 ComfyUI V3 或当前依赖版本下需要本地补丁，补丁已在各自仓库内本地提交：

- `ComfyUI-LTXVideo`：`kornia` 0.8.3 移除了 `kornia.core.pad` 别名，
  `pyramid_blending.py` 改为直接使用已导入的 `torch.nn.functional.pad`。

- `ComfyUI-layerdiffuse`：上游在 ComfyUI V3 下有两处失效。上游最新提交为 `b4f6a9e`，
  `main` 是唯一分支，重新克隆得到的代码与此处记录的完全一致。

  **一、节点直接崩溃。** `LayeredDiffusionDecodeRGBA` 调用
  `JoinImageWithAlpha().join_image_with_alpha()`，而该方法在 V3 中已被 `execute()` 取代
  （ComfyUI `6732014a0`，2025-10-08），节点一旦执行就抛出 `AttributeError`。上游 issue
  #136 自 2026-04 起保持开启，三个修复 PR（#132、#135、#137）均未合并。

  **二、注意力权重被丢弃。** `layer_xl_transparent_attn.safetensors` 的 1120 个张量全部以
  `::lora::` 配对格式保存，而 ComfyUI 的 patch 解析只识别 `diff`、`set`、`model_as_lora`
  三种类型，实测权重扰动为 0，注意力层完全不生效。

  补丁已在仓库内本地提交（`4dc25f8`）：把 LoRA 配对在 `pad_diff_weight()` 中折叠成完整
  权重差，并改用 `torch.cat` 直接拼接 alpha 通道。alpha 取解码器原始通道而非上游的
  `1.0 - mask`，实测两者正确率分别为 2/6 与 0/6。

补丁未推送到上游仓库，重新克隆后需要重新应用：

```bash
git -C custom_nodes/ComfyUI-layerdiffuse am ~/0001-Fold-LoRA-paired-weights-into-diff-patches-and-fix-a.patch
```

PowerShell 一键克隆命令（已存在的目录会跳过）：

```powershell
@(
  "https://github.com/Fannovel16/comfyui_controlnet_aux.git",
  "https://github.com/newtextdoc1111/ComfyUI-Autocomplete-Plus.git",
  "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git",
  "https://github.com/darksidewalker/ComfyUI-DaSiWa-Nodes.git",
  "https://github.com/yolain/ComfyUI-Easy-Use.git",
  "https://github.com/Miosp/ComfyUI-FBCNN.git",
  "https://github.com/city96/ComfyUI-GGUF.git",
  "https://github.com/alexopus/ComfyUI-Image-Saver.git",
  "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git",
  "https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git",
  "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git",
  "https://github.com/kijai/ComfyUI-KJNodes.git",
  "https://github.com/huchenlei/ComfyUI-layerdiffuse.git",
  "https://github.com/willmiao/ComfyUI-Lora-Manager.git",
  "https://github.com/Lightricks/ComfyUI-LTXVideo.git",
  "https://github.com/pamparamm/ComfyUI-ppm.git",
  "https://github.com/1038lab/ComfyUI-QwenVL.git",
  "https://github.com/jtydhr88/ComfyUI-See-through.git",
  "https://github.com/kijai/ComfyUI-segment-anything-2.git",
  "https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git",
  "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git",
  "https://github.com/kijai/ComfyUI-WanVideoWrapper.git",
  "https://github.com/Artificial-Sweetener/comfyui-WhiteRabbit.git",
  "https://github.com/rgthree/rgthree-comfy.git",
  "https://github.com/KohakuBlueleaf/z-tipo-extension.git"
) | ForEach-Object {
  $name = [IO.Path]::GetFileNameWithoutExtension($_)
  $destination = Join-Path "custom_nodes" $name
  if (-not (Test-Path $destination)) {
    git clone --recurse-submodules $_ $destination
  }
}
```

## 模型

以下路径均相对于 `models/` 目录。当前模型以单独文件分发，不克隆整个 Hugging Face 仓库。

### 已下载

| 完成 | 模型 | 保存路径 | 体积 |
| --- | --- | --- | --- |
| [x] | `illustriousXL_v01.safetensors` | `checkpoints/illustriousXL_v01.safetensors` | 6.46 GB |
| [x] | `waiIllustriousSDXL_v170.safetensors` | `checkpoints/waiIllustriousSDXL_v170.safetensors` | 6.46 GB |
| [x] | `layer_xl_transparent_conv.safetensors` | `layer_model/layer_xl_transparent_conv.safetensors` | 3.37 GB |
| [x] | `TIPO-500M-ft_TIPO-500M-ft-F16.gguf` | `kgen/TIPO-500M-ft_TIPO-500M-ft-F16.gguf` | 970 MB |
| [x] | `layer_xl_transparent_attn.safetensors` | `layer_model/layer_xl_transparent_attn.safetensors` | 709 MB |
| [x] | `parsing_lip.onnx` | `onnx/parsing_lip.onnx` | 255 MB |
| [x] | `vae_transparent_decoder.safetensors` | `layer_model/vae_transparent_decoder.safetensors` | 199 MB |
| [x] | `deeplabv3p-resnet50-human.onnx` | `onnx/human-parts/deeplabv3p-resnet50-human.onnx` | 45 MB |
| [x] | `RealESRGAN_x4plus_anime_6B.pth` | `upscale_models/RealESRGAN_x4plus_anime_6B.pth` | 17 MB |

`illustriousXL_v01` 与 `waiIllustriousSDXL_v170` 被现有 txt2img 工作流引用；
`layer_model/` 三个权重与 `onnx/parsing_lip.onnx` 供透明背景相关流程使用。

### 待下载

以下模型尚未下载，保留下载地址备用。

#### Z-Image

| 完成 | 模型 | 保存路径 | 来源 |
| --- | --- | --- | --- |
| [ ] | `z_image_turbo_bf16.safetensors` | `diffusion_models/z_image_turbo_bf16.safetensors` | [Download](https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors) |
| [ ] | `qwen_3_4b.safetensors` | `text_encoders/qwen_3_4b.safetensors` | [Download](https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors) |
| [ ] | `ae.safetensors` | `vae/ae.safetensors` | [Download](https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors) |
| [ ] | `Z-Image-Turbo-Fun-Controlnet-Union.safetensors` | `model_patches/Z-Image-Turbo-Fun-Controlnet-Union.safetensors` | [Download](https://huggingface.co/alibaba-pai/Z-Image-Turbo-Fun-Controlnet-Union/resolve/main/Z-Image-Turbo-Fun-Controlnet-Union.safetensors) |

#### FLUX.2

| 完成 | 模型 | 保存路径 | 来源 |
| --- | --- | --- | --- |
| [ ] | `flux-2-klein-base-9b-fp8.safetensors` | `diffusion_models/flux-2-klein-base-9b-fp8.safetensors` | [Download](https://huggingface.co/black-forest-labs/FLUX.2-klein-base-9b-fp8/resolve/main/flux-2-klein-base-9b-fp8.safetensors) |
| [ ] | `qwen_3_8b_fp8mixed.safetensors` | `text_encoders/qwen_3_8b_fp8mixed.safetensors` | [Download](https://huggingface.co/Comfy-Org/flux2-klein-9B/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors) |
| [ ] | `flux2-vae.safetensors` | `vae/flux2-vae.safetensors` | [Download](https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors) |
| [ ] | `full_encoder_small_decoder.safetensors` | `vae/full_encoder_small_decoder.safetensors` | [Download](https://huggingface.co/black-forest-labs/FLUX.2-small-decoder/resolve/main/full_encoder_small_decoder.safetensors) |

#### Wan

| 完成 | 模型 | 保存路径 | 来源 |
| --- | --- | --- | --- |
| [ ] | `umt5_xxl_fp8_e4m3fn_scaled.safetensors` | `text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors` | [Download](https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors) |
| [ ] | `clip_vision_h.safetensors` | `clip_vision/clip_vision_h.safetensors` | [Download](https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors) |
| [ ] | `wan_2.1_vae.safetensors` | `vae/wan_2.1_vae.safetensors` | [Download](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors) |
| [ ] | `WanAnimate_relight_lora_fp16.safetensors` | `loras/WanAnimate_relight_lora_fp16.safetensors` | [Download](https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors) |
| [ ] | `sam2_hiera_base_plus.safetensors` | `sam2/sam2_hiera_base_plus.safetensors` | [Download](https://huggingface.co/Kijai/sam2-safetensors/resolve/main/sam2_hiera_base_plus.safetensors) |

#### Anima

官方示例图包含可运行工作流，已保存为
`user/default/workflows/anima_official_example.png`。适配 Aesthetic v1.1 的纯 JSON
工作流位于 `user/default/workflows/Anima Aesthetic v1.1.json`。

| 完成 | 模型 | 保存路径 | 来源 |
| --- | --- | --- | --- |
| [x] | `anima-aesthetic-v1.1.safetensors` | `diffusion_models/anima-aesthetic-v1.1.safetensors` | [Download](https://huggingface.co/circlestone-labs/Anima/resolve/main/split_files/diffusion_models/anima-aesthetic-v1.1.safetensors) |
| [x] | `qwen_3_06b_base.safetensors` | `text_encoders/qwen_3_06b_base.safetensors` | [Download](https://huggingface.co/circlestone-labs/Anima/resolve/main/split_files/text_encoders/qwen_3_06b_base.safetensors) |
| [ ] | `waiANIMA_v10Base10.safetensors` | `diffusion_models/waiANIMA_v10Base10.safetensors` | 待补充链接 |
| [ ] | `waiANIMA_v10Base10_txt.safetensors` | `text_encoders/waiANIMA_v10Base10_txt.safetensors` | 待补充链接 |
| [x] | `qwen_image_vae.safetensors` | `vae/qwen_image_vae.safetensors` | [Download](https://huggingface.co/circlestone-labs/Anima/resolve/main/split_files/vae/qwen_image_vae.safetensors) |

### Illustrious

| 完成 | 模型 | 保存路径 | 来源 |
| --- | --- | --- | --- |
| [ ] | `illustriousXL_v01.safetensors` | `checkpoints/illustriousXL_v01.safetensors` | 待补充链接 |
| [ ] | `waiIllustriousSDXL_v170.safetensors` | `checkpoints/waiIllustriousSDXL_v170.safetensors` | 待补充链接 |
