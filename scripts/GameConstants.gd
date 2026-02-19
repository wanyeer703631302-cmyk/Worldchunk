class_name GameConstants
extends Node

# 属性定义
enum Attribute {
	NONE,
	THUNDER, # 雷
	FIRE,    # 火
	ICE,     # 冰
	POISON   # 毒
}

# 属性克制关系 (攻击者 -> 防御者)
# 雷 -> 水/机械 (简化演示：雷 -> 毒)
# 火 -> 冰
# 冰 -> 雷
# 毒 -> 火 (闭环设计示例)
const ATTRIBUTE_COUNTER = {
	Attribute.THUNDER: [Attribute.POISON],
	Attribute.FIRE: [Attribute.ICE],
	Attribute.ICE: [Attribute.THUNDER],
	Attribute.POISON: [Attribute.FIRE]
}

# 属性颜色 (用于视觉调试)
const ATTRIBUTE_COLORS = {
	Attribute.NONE: Color.WHITE,
	Attribute.THUNDER: Color.YELLOW,
	Attribute.FIRE: Color.ORANGE_RED,
	Attribute.ICE: Color.AQUA,
	Attribute.POISON: Color.PURPLE
}