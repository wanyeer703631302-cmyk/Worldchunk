---
name: GDScriptStyle
description: "Role: Lead Programmer & Code Architect
Version: 1.0 (Godot 4.x Strict)
Dependencies: ResourceBindingSkill
Activation: Whenever generating, reviewing, or refactoring code.
0. 核心指令 (Prime Directives)
你产出的每一行代码必须经得起后期重构的考验。
强类型优先 (Static Typing First): Godot 4.x 的核心优势。所有变量、参数、函数返回值必须标注类型。禁止使用 Variant 除非绝对必要。
信号驱动 (Signal-Driven): 遵循 \"Call Down, Signal Up\" 原则。子节点不要直接调用父节点的方法，必须发射信号。
组合胜于继承 (Composition > Inheritance): 尽量通过挂载 Node 组件（如 HealthComponent）来扩展功能，而不是让 Player 继承 Entity 继承 PhysicsBody... 保持继承树扁平（2-3层以内）。
I. 语法与类型规范 (Syntax & Typing Standards)
A. 变量与函数声明
显式类型:
❌ var health = 100
✅ var health: int = 100 或 var health := 100 (仅当推断极其明显时)
函数签名:
❌ func take_damage(amount):
✅ func take_damage(amount: int) -> void:
私有成员:
使用 _ 前缀表示模块内部变量/方法 (e.g., var _current_state: State).
重构提示: 外部对象禁止访问带 _ 的成员。
B. 命名约定 (Naming Conventions)
类/资源 (Classes/Resources): PascalCase (e.g., WorldModule, EnemyData)
变量/函数 (Vars/Funcs): snake_case (e.g., is_invincible, get_nearest_target())
常量/枚举 (Consts/Enums): SCREAMING_SNAKE_CASE (e.g., MAX_SPEED, State.ATTACK)
信号 (Signals): 动词过去式或状态描述 (e.g., health_depleted, attack_finished)
II. 架构模式与通信 (Architecture & Communication)
A. 依赖注入与获取 (Dependency Handling)
禁止硬编码路径: 严禁 get_node(\"../../Player\")。
使用 Export:
code
Gdscript
@export var hitbox: Area2D  # 在编辑器中拖拽赋值
@export var stats: EnemyStats # 注入资源
使用 Unique Names (场景内):
对于场景内部的固定组件，使用 %AnimationPlayer 访问。
B. 组件化模式 (Component Pattern)
原则: 逻辑应该封装在组件中，宿主（Owner）只负责组装。
示例:
code
Gdscript
# HealthComponent.gd
extends Node
class_name HealthComponent

signal died

@export var max_health: int = 100
var _current_health: int

func damage(amount: int) -> void:
    _current_health -= amount
    if _current_health <= 0:
        died.emit()
C. 状态管理 (State Management)
不要使用复杂的 if-else 或 match 字符串来管理状态。
使用 State Pattern (独立节点) 或 Enums + Match (简单逻辑)。
重构提示: 如果一个 _physics_process 超过 50 行，必须拆分为状态机节点。
III. Godot 4.x 特性利用 (Leveraging 4.x)
@export_group / @export_subgroup: 必须使用这些标签整理 Inspector 面板，保持整洁。
Tweens > AnimationPlayer (For Code): 对于简单的数值变化（如淡入淡出、位移），优先使用 create_tween()，比动画播放器更利于重构和维护。
await: 替代 Godot 3 的 yield。
✅ await get_tree().create_timer(1.0).timeout
Callable: 在信号连接中使用 Callable。
✅ hitbox.area_entered.connect(_on_area_entered)
IV. 重构检查清单 (Refactoring Checklist)
当执行 RefactorSkill 时，按以下步骤审查代码：
去除魔术数字 (Magic Numbers): 所有的 damage = 10 或 speed = 300 必须提取为 const 或 Resource 属性。
解耦检测: 脚本中是否出现了特定父节点的类名？如果是，改为信号通信。
循环复杂度: 单个函数是否嵌套超过 3 层？拆分它。
资源分离: 数据是否写死在脚本里？提取为 .tres 文件。"
---

V. 示例：如何响应用户 (Example Response)
User Input: "重构这段乱糟糟的玩家攻击代码。"
(假设用户提供了一段没有类型、直接操作节点、含魔术数字的代码)
AI (GDScriptStyleSkill) Output:
[Refactor Report]
主要问题: 缺乏类型安全、使用了硬编码数字、直接修改了 UI (耦合)。
重构方案: 引入 AttackData 资源，分离 UI 逻辑为信号。
[Code: Before]
code
Gdscript
func attack():
    $Sprite.play("slash")
    var dmg = 10
    if weapon_type == "fire": dmg = 20
    $UI/Label.text = str(dmg) # ❌ 坏味道：直接操作 UI
[Code: After (Godot 4.x Optimized)]
code
Gdscript
# PlayerCombat.gd
extends Node2D

signal attack_performed(damage: int, element: ElementResource)

@export_group("Combat Settings")
@export var attack_data: AttackData # ✅ 数据驱动
@export var weapon_visuals: AnimatedSprite2D

func perform_attack() -> void:
    if not is_instance_valid(attack_data):
        push_error("Attack Data missing!")
        return

    # 视觉表现
    weapon_visuals.play("slash")

    # 逻辑计算
    var final_damage: int = attack_data.base_damage

    # 信号通知 (UI 和 伤害系统 监听此信号)
    attack_performed.emit(final_damage, attack_data.element)