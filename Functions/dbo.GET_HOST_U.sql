SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_HOST_U] ()
RETURNS NVARCHAR(128)
AS
BEGIN
	RETURN (SELECT s.host_name
             FROM sys.dm_exec_connections AS c  
             JOIN sys.dm_exec_sessions AS s  
               ON c.session_id = s.session_id  
            WHERE c.session_id = @@SPID);
END
GO
