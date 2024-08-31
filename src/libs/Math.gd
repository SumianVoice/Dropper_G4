extends GDScript
class_name Math

static func vec3anglediff(v, k):
	return Vector3(
		angle_difference(v.x, k.x),
		angle_difference(v.y, k.y),
		angle_difference(v.z, k.z)
	)
