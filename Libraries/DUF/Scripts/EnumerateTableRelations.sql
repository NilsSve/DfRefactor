SELECT
  object_name(parent_object_id),
  object_name(referenced_object_id),
  name 
FROM sys.foreign_keys
WHERE parent_object_id = object_id('TABLE_NAME_XXX')