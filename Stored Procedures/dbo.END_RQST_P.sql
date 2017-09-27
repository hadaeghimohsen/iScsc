SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[END_RQST_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	DECLARE @Rqid BIGINT;	       
	       
	SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT');	      
	
	UPDATE Request
	   SET RQST_STAT = '002'
	 WHERE RQID = @Rqid;
END
GO
