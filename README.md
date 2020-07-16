# 2020NSCSCC

PipelineMIPS

## 目标

设计并实现一个流水线版的MIPS处理器，力求：

1. 模块清晰易懂，代码规范
2. 有较为完善的Cache
3. 主频达到100MHz
4. 有TLB支持，便于之后运行操作系统

## 设计

1. 指令集为MIPS32 Release1子集。初赛(57 条),  决赛(增加上学期跑PMON, linux时添加的指令)
2. 采用流水线结构（5级或7级）
3. Cache：一级cache，组相联结构，块大小为多字。
4. Cache和TLB结合：虚拟索引，物理tag
5. 分支预测模块

