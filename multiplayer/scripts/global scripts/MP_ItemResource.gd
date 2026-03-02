class_name MP_ItemResource extends Resource

@export var instance: PackedScene
@export var id: int
@export var name: String
@export var distribution_enabled: bool
@export var max_amount_on_table: int
@export var max_amount_on_table_global: int
@export_group("audio")
@export var sound_pick_up_fp: AudioStream
@export var sound_place_down_fp: AudioStream
@export var sound_pick_up_tp: AudioStream
@export var sound_place_down_tp: AudioStream
@export var sound_initial_interaction_fp: AudioStream
@export var sound_initial_interaction_tp: AudioStream
@export_group("offsets")
@export var pos_in_briefcase_local: Vector3
@export var rot_in_briefcase_local: Vector3
@export var pos_out_briefcase_local: Vector3
@export var rot_out_briefcase_local: Vector3
@export var pos_Y_offset_from_carriage: float
@export var pos_grid_offset_array_local: Array[Vector3]
@export var rot_grid_offset_array_local: Array[Vector3]
