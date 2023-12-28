USE [Chinook]
GO

create view vwNumberOfTracksPerGenre as

Select count([track].[genreid]) as 'NumberOfTracks', 
	[genre].[name] 
from [track] 
	join [genre] on [genre].[genreid] = [track].[GenreId]
group by [genre].[name]
