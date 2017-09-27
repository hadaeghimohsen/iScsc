SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ShrinkLogFileDb]	
AS
BEGIN
	
   ALTER DATABASE iScsc SET RECOVERY SIMPLE;
   DBCC SHRINKFILE(N'iScsc_log', 1);
   ALTER DATABASE iScsc SET RECOVERY FULL;
   PRINT 'iScsc Log File Shrink 1 MB';
   	
END
GO
