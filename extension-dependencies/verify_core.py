"""核对基础镜像原有分发未被扩展安装替换或降级。"""

import importlib.metadata
import json
from pathlib import Path

from packaging.requirements import Requirement


constraints = Path(__file__).with_name('core-constraints.txt')
checked = 0
changed = []
for line in constraints.read_text().splitlines():
    if not line or line.startswith('#'):
        continue
    requirement = Requirement(line)
    expected = str(requirement.specifier).removeprefix('==')
    try:
        actual = importlib.metadata.version(requirement.name)
    except importlib.metadata.PackageNotFoundError:
        actual = None
    if actual != expected:
        changed.append({'package': requirement.name, 'expected': expected, 'actual': actual})
    checked += 1
if changed:
    raise RuntimeError(json.dumps(changed, ensure_ascii=False))
print(json.dumps({'protected_distributions': checked, 'changed': 0}, ensure_ascii=False))
