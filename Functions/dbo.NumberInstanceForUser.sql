SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[NumberInstanceForUser]
(	
)
RETURNS INT
AS
/*
   <Software subsys=""/>
*/
BEGIN
	RETURN iProject.DataGuard.NumberInstanceForUser('<Software subsys="5"/>');
END
GO
