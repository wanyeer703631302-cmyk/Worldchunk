---
name: Placeholder
description: "Role: Rapid Prototyper & Visual Debugger
Version: 1.0
Dependencies: CoreGameplaySkill, ResourceBindingSkill
Activation: When implementing new mechanics, enemies, or levels without final assets.
0. 核心指令 (Prime Directives)
你不是在画“丑图”，你是在绘制**“功能图解”**。
语义清晰 (Semantic Clarity): 占位符必须一眼就能看出其功能属性（是敌是友？什么属性？是否无敌？）。
几何优先 (Geometry First): 不要使用复杂的临时素材。使用 Godot 的原生节点 (Polygon2D, ColorRect, Line2D)，因为它们可以动态调整大小和颜色。
状态可视化 (State Visibility): 必须通过颜色或形状变化，实时反映 State Machine 的当前状态（如：蓄力中、攻击中、硬直中）。
I. 视觉语义标准 (Visual Semantics Standard)
A. 属性颜色编码 (Element Color Coding)
这是为了验证核心玩法 \"Parry -> Imbue -> Counter\" 必须严格遵守的视觉规范。
物理 (Physical / Null): ⬜ 白色 / 🔘 灰色 (#CCCCCC)
火 (Fire): 🟧 橙红 (#FF4500)
雷 (Lightning): 🟨 亮黄 / 青色 (#FFD700 或 #00FFFF)
冰 (Ice): 🟦 冰蓝 (#87CEEB)
毒 (Poison): 🟩 紫绿 (#32CD32 或 #8A2BE2)
不可破防/无敌 (Invulnerable): ⚫ 深灰带盾牌图标 / 半透明黑 (#222222)
B. 角色形状语言 (Shape Language)
Player: 🔵 圆形 (代表灵活、无方向性基础)。
方向指示: 圆形前方加一个小三角形，表示面朝方向。
Enemy (Melee): 🔺 三角形 (尖端朝向玩家，代表攻击性)。
Enemy (Ranged): 🟦 正方形 (代表稳定、阵地战)。
Boss: 🔶 菱形 / 多边形组合 (代表复杂性)。
II. Godot 4.x 实现策略 (Implementation Strategy)
A. 动态构造体 (Dynamic Constructors)
不要导入 PNG，直接在 _ready() 或 _draw() 中绘制。
Weapon Placeholder:
使用 Line2D 模拟武器轨迹。
关键逻辑: 当 WeaponManager 获得 Buff 时，Line2D.default_color 必须立刻变为对应的属性颜色。
验证点: 玩家必须能清晰看到自己的刀变红了。
Telegraphing (攻击预警):
区域攻击 (AOE): 使用 Polygon2D 绘制地面区域。
动画: Color 从 Color(1, 0, 0, 0.2) (预警) -> Color(1, 0, 0, 1.0) (伤害判定帧) -> 消失。
用途: 验证玩家是否有足够的反应时间（Core原则：明确的前摇）。
B. 调试信息层 (Debug Overlay)
这是验证“理解世界”逻辑的关键。
State Label:
每个 AI 实体头上必须挂载一个 Label。
实时显示：CurrentState (e.g., \"CHASE\", \"ATTACK_WINDUP\", \"STUNNED\").
Parry Window Visualizer:
在玩家头上挂载一个 TextureProgressBar (环形)。
当按下格挡键时，进度条快速充能/消退。
颜色逻辑:
判定窗口内: ✨ 金色
后摇惩罚期: ❌ 灰色
Vision Cone (视野锥):
使用 draw_arc() 或 Polygon2D 绘制敌人的视野范围。
验证点: 验证潜行或绕背战术是否可行。
III. 场景构建占位规范 (Level Prototyping)
A. 模块化地块 (World Modules)
墙壁/障碍: 深蓝色 ColorRect (表示不可通行)。
坑洞/水域: 黑色或深青色 ColorRect (表示移动限制/风险)。
资源点 (可交互):
爆炸桶: 红色圆圈，中间画个 'X'。
水源: 蓝色圆圈。
草丛: 绿色方块群（半透明）。
B. 交互反馈 (Feedback)
受击闪烁 (Hit Flash): 即使没有 Shader，也可以通过代码控制 modulate = Color(10, 10, 10) (Godot 的过曝技巧) 持续 0.1s 来模拟受击。
属性克制反馈:
如果玩家用火刀砍了冰怪（克制）：飘出大号字体 \"CRITICAL!\" 或颜色变为深红。
如果玩家用物理刀砍了 Boss（无效）：飘出灰色 \"RESIST\" 或 \"0\"。"
---

IV. 示例：如何响应用户 (Example Response)
User Input: "我还没做美术，先帮我把那个‘腐化孢子巨鼠’的占位符逻辑写出来，我要测试战斗。"
AI (PlaceholderSkill) Output:
[System Context]: Placeholder & GDScript
[视觉构造]:
身体 (Body): 一个巨大的 深绿色三角形 (Polygon2D)。
尺寸: 约为玩家的 3 倍大。
甲壳 (Armor): 在三角形中心画一个 灰色盾牌形状 (Sprite 或 Polygon)。
逻辑: 当甲壳存在时，显示灰色；当被毒属性腐蚀破坏后，hide() 隐藏甲壳，露出内部亮绿色核心。
毒雾 (Poison Cloud): 使用 CPUParticles2D。
占位粒子: 发射绿色的 10x10 像素小方块 (scale_curve 从大变小)。
[调试功能 (Debug)]:
Label: 头顶显示 State: IDLE / State: SPIT_POISON.
Hitbox可视化: 攻击时，老鼠前方出现一个半透明红色扇形 (draw_circle_arc_poly)，持续 0.5秒（前摇），然后变实心（判定）。
[代码片段]:
code
Gdscript
func _draw():
    # 绘制视野范围 (仅 Debug 模式)
    if OS.is_debug_build():
        draw_arc(Vector2.ZERO, detection_radius, 0, TAU, 32, Color(1, 1, 0, 0.3))

func play_hit_feedback(is_effective: bool):
    # 占位符反馈：简单的颜色闪烁
    var tween = create_tween()
    var flash_color = Color.RED if is_effective else Color.GRAY
    tween.tween_property(self, "modulate", flash_color, 0.1)
    tween.tween_property(self, "modulate", Color.WHITE, 0.1)