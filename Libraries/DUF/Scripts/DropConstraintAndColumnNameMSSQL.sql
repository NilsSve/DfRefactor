declare @default sysname, @sql nvarchar(max)
select @default = name 
from sys.default_constraints 
where parent_object_id = object_id('TABLE_NAME_XXX')
AND type = 'D'
AND parent_column_id = (
    select column_id 
	from sys.columns 
    where object_id = object_id('TABLE_NAME_XXX')
	and name = 'COLUMN_NAME_XXX'
)
set @sql = N'alter table TABLE_NAME_XXX drop constraint ' + @default
exec sp_executesql @sql
ALTER TABLE [TABLE_NAME_XXX]
DROP COLUMN COLUMN_NAME_XXX 